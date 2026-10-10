#' Read, write, and create SharePoint list definitions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' A SharePoint list definition describes a list and its columns using
#' Microsoft Graph list and columnDefinition property names. Definitions can
#' be stored as YAML files, used to create a list with
#' `create_sp_list(definition = )`, and compared or synced with an existing
#' list using [compare_sp_list()] and [sync_sp_list()].
#'
#' - [read_sp_list_yaml()] reads and validates a YAML file.
#' - [write_sp_list_yaml()] writes a definition or an existing list to a YAML
#'   file.
#' - [get_sp_list_definition()] creates a definition from an existing list.
#' - [as_sp_list_definition()] validates a list with the same structure as a
#'   YAML file.
#'
#' @details YAML format
#'
#' ```yaml
#' # Comments before the first key are kept by write_sp_list_yaml()
#' ---
#' format_version: 1
#' displayName: Capital Project
#' description: Capital projects and their status.
#' list:
#'   template: genericList
#' # Read-only properties of an existing list (optional)
#' id: 5a8b3c4d-0000-0000-0000-000000000000
#' webUrl: https://example.sharepoint.com/sites/Planning/Lists/CapitalProject
#' parentReference:
#'   siteId: example.sharepoint.com,1111,2222
#' custom:
#'   owner: Planning
#' columns:
#'   - name: Title
#'     displayName: Project Name
#'     required: true
#'     text: {}
#'   - name: ProjectID
#'     displayName: Project ID
#'     description: Project reference ID
#'     required: true
#'     text: {}
#'   - name: Notes
#'     displayName: Project Notes
#'     text:
#'       allowMultipleLines: true
#'     custom:
#'       form_order: 2
#'   - name: Status
#'     choice:
#'       choices:
#'         - Active
#'         - Closed
#'       displayAs: radioButtons
#' ```
#'
#' Top-level keys use the Graph
#' [list](https://learn.microsoft.com/en-us/graph/api/resources/list?view=graph-rest-1.0)
#' property names:
#'
#' - `displayName` (required): the list display name. SharePoint sets the
#'   read-only list `name` (used in the list URL) from the display name when a
#'   list is created. Changing the display name later doesn't change the URL.
#' - `columns` (required): a sequence of column definitions.
#' - `description` (optional): the list description.
#' - `list` (optional): list settings using the
#'   [listInfo](https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0)
#'   property names `template` (e.g. `genericList`, the default, or
#'   `documentLibrary`), `hidden`, and `contentTypesEnabled`. The template
#'   can't be changed after a list is created.
#' - `format_version` (optional): the format version. Only `1` is supported.
#' - `custom` (optional): a mapping that isn't validated (see below).
#'
#' Comments and blank lines before the first key are a header that
#' [write_sp_list_yaml()] keeps when it updates a file. An optional document
#' start marker (`---`) after the header marks where the header ends. Other
#' comments (including comments between `---` and the first key) are lost
#' when a file is rewritten, so use `custom` for notes that need to be kept.
#' A file can only have one YAML document.
#'
#' Read-only list properties can also be included as a reference to an
#' existing list: `id`, `name`, `webUrl`, `createdDateTime`, `createdBy`,
#' `lastModifiedDateTime`, `lastModifiedBy`, `eTag`, `parentReference`,
#' `sharepointIds`, and `system`. These properties are never sent to
#' SharePoint. [compare_sp_list()] and [sync_sp_list()] use
#' `id` and `parentReference.siteId` to get the list if `sp_list` isn't
#' supplied, and error if a supplied list has a different `id`.
#' [create_sp_list()] ignores them.
#'
#' Columns can also include an `id` as a reference to an existing column.
#' Columns are always matched by `name`.
#'
#' Column keys use the Graph
#' [columnDefinition](https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0)
#' property names:
#'
#' - `name` (required): the internal column name. The name can't be changed
#'   after a column is created and should avoid names that look like
#'   spreadsheet cell references (e.g. `V4`). For a list (but not a document
#'   library), the name of a new column can't be longer than 32 characters,
#'   counting each space or special character as 7 (e.g. a space is stored as
#'   `_x0020_`). SharePoint cuts longer names without an error, so
#'   [create_sp_list()] and [create_sp_list_column()] error instead. Display
#'   names can be longer: the column settings page allows up to 255
#'   characters.
#' - `displayName`, `description`, `required`, `enforceUniqueValues`,
#'   `hidden`, `indexed`, `readOnly`, `defaultValue` (with `value` or
#'   `formula`), and `validation` (see [column_validation()]).
#' - Exactly one column type key holding the properties for that type. Use an
#'   empty mapping (`{}`) for a type with no properties.
#'
#' A `Title` column updates the default title column of a `genericList` list
#' instead of adding a new column.
#'
#' Column type keys and properties:
#'
#' | Type key | Properties |
#' |---|---|
#' | `text` | `allowMultipleLines`, `appendChangesToExistingText`, `linesForEditing`, `maxLength`, `textType` |
#' | `choice` | `allowTextEntry`, `choices`, `displayAs` |
#' | `number` | `decimalPlaces`, `displayAs`, `maximum`, `minimum` |
#' | `dateTime` | `displayAs`, `format` |
#' | `currency` | `locale` |
#' | `calculated` | `formula`, `outputType`, `format` |
#' | `lookup` | `listId`, `columnName`, `allowMultipleValues`, `allowUnlimitedLength`, `primaryLookupColumnId` |
#' | `personOrGroup` | `allowMultipleSelection`, `chooseFromType`, `displayAs` |
#' | `hyperlinkOrPicture` | `isPicture` |
#' | `term` | `allowMultipleValues`, `showFullyQualifiedName` |
#' | `boolean`, `geolocation`, `thumbnail` | none |
#'
#' Validation rules:
#'
#' - Unknown keys are errors, with a hint for common alternatives (e.g.
#'   `label` for `displayName`). Read-only properties (e.g. `id`) are errors.
#' - Values must match the type and allowed values in the Graph API
#'   documentation.
#' - A `calculated` column requires `formula` and `outputType`. `format` is
#'   only allowed when `outputType` is `dateTime`.
#' - A `lookup` column requires `listId` and `columnName`. The `listId` is
#'   specific to a site.
#' - Column names must be unique. Duplicate display names are a warning since
#'   formulas reference columns by display name.
#'
#' Keys that aren't columnDefinition properties go under `custom`, either for
#' the list or for each column. sharepointr doesn't validate `custom` and
#' doesn't send it to SharePoint, so it can hold metadata used by other
#' applications (e.g. form order or app-enforced choices).
#'
#' Properties that aren't included in a column definition aren't compared or
#' changed by [sync_sp_list()]. Removing a property from a file
#' doesn't reset it to the default value.
#'
#' @details List views
#'
#' An optional `views` key holds a sequence of list views using the SharePoint
#' REST API SP.View property names (see [list_sp_list_views()]):
#'
#' ```yaml
#' views:
#'   - Title: Active Projects
#'     DefaultView: true
#'     ViewFields:
#'       - LinkTitle
#'       - ProjectStatus
#'       - Budget
#'     ViewQuery: <Where><Eq><FieldRef Name="ProjectStatus"/><Value Type="Choice">Active</Value></Eq></Where>
#'     RowLimit: 50
#'     CustomFormatter:
#'       additionalRowClass: sp-field-severity--good
#' ```
#'
#' - `Title` is required and must be unique. Only one view can set
#'   `DefaultView: true`.
#' - Other properties are `ViewFields` (internal column names), `ViewQuery`
#'   (a CAML query), `RowLimit`, `Paged`, `Scope`, `Hidden`, `MobileView`,
#'   `MobileDefaultView`, and `CustomFormatter` (view formatting as a YAML
#'   mapping or a JSON string). `Id` and `ServerRelativeUrl` can be included
#'   as a reference to an existing view.
#' - A warning is given if a view shows fields that aren't columns in the
#'   definition or built-in fields (e.g. `LinkTitle`, `ID`, or `Modified`).
#'
#' `create_sp_list(definition = )` creates views after creating the columns. A
#' view titled `All Items` updates the default view of a new `genericList`
#' list. [compare_sp_list()] and [sync_sp_list()] compare and update views
#' only if the definition has a `views` element. Views are only written by
#' [write_sp_list_yaml()] if `include_views = TRUE`.
#'
#' @param path Path to a YAML file.
#' @param x For [write_sp_list_yaml()], a `sp_list_definition` object or a
#'   `ms_list` object. For [as_sp_list_definition()], a named list with the
#'   same structure as a YAML file or an unnamed list of column definitions.
#' @inheritParams rlang::args_error_context
#' @returns A `sp_list_definition` object: a list with `format_version`,
#'   `displayName`, `description`, `list`, any read-only list properties,
#'   `custom`, and `columns` elements.
#'   [write_sp_list_yaml()] invisibly returns the definition that was written.
#' @seealso [sp_list_definition_table()] to convert a definition to a data
#'   frame.
#' @keywords lists
#' @examples
#' path <- system.file("extdata", "example-list.yaml", package = "sharepointr")
#'
#' definition <- read_sp_list_yaml(path)
#'
#' definition
#'
#' sp_list_definition_table(definition)
#'
#' @name sp_list_definition
NULL

#' @rdname sp_list_definition
#' @export
read_sp_list_yaml <- function(path, call = caller_env()) {
  check_installed("yaml12", call = call)
  check_string(path, call = call)

  if (!file.exists(path)) {
    cli_abort("{.file {path}} doesn't exist.", call = call)
  }

  # Read every document so a second document (e.g. after a stray `---`)
  # isn't silently ignored
  docs <- yaml12::read_yaml(path, multi = TRUE)

  if (length(docs) > 1) {
    cli_abort(
      c(
        "{.file {path}} must have one YAML document, not {length(docs)}.",
        "i" = "A {.code ---} line starts a new document. Use it only once,
        before the first key."
      ),
      call = call
    )
  }

  doc <- if (length(docs) == 1) docs[[1]]

  as_sp_list_definition(doc, call = call)
}

#' @rdname sp_list_definition
#' @param display_name List display name. Used by [as_sp_list_definition()]
#'   if `x` is an unnamed list of column definitions.
#' @param ... Must be empty.
#' @export
as_sp_list_definition <- function(
  x,
  ...,
  display_name = NULL,
  call = caller_env()
) {
  check_dots_empty()

  if (!is.list(x)) {
    cli_abort(
      "{.arg x} must be a list, not {.obj_type_friendly {x}}.",
      call = call
    )
  }

  # An unnamed list of column definitions
  if (!inherits(x, "sp_list_definition") && !is_named(x) && length(x) > 0) {
    x <- list(displayName = display_name, columns = x)
  }

  x <- unclass(x)
  allowed <- c(
    "format_version",
    "displayName",
    "description",
    "list",
    names(sp_list_read_only_props),
    "custom",
    "columns",
    "views"
  )
  unknown <- setdiff(names(x), allowed)

  if (length(unknown) > 0) {
    cli_abort(
      c(
        "A list definition has unknown key{?s}: {.field {unknown}}.",
        "i" = "Allowed keys: {.field {setdiff(allowed, names(sp_list_read_only_props))}}.
        Use {.field custom} for other metadata.",
        "i" = "Read-only list properties (e.g. {.field id} or {.field webUrl})
        are also allowed."
      ),
      call = call
    )
  }

  if (is.null(x[["displayName"]]) && !is.null(x[["name"]])) {
    cli_abort(
      c(
        "A list definition must have a {.field displayName}.",
        "i" = "{.field name} is the read-only list name set by SharePoint
        (used in the list URL). Use {.field displayName} for the list
        display name."
      ),
      call = call
    )
  }

  format_version <- x[["format_version"]] %||% 1L
  check_number_whole(format_version, arg = "format_version", call = call)

  if (format_version != 1) {
    cli_abort(
      "{.field format_version} {format_version} isn't supported.",
      call = call
    )
  }

  check_string(x[["displayName"]], arg = "displayName", call = call)
  check_string(
    x[["description"]],
    allow_null = TRUE,
    arg = "description",
    call = call
  )

  list_info <- check_sp_list_info(x[["list"]], call = call)
  read_only <- check_sp_list_read_only(
    x[intersect(names(sp_list_read_only_props), names(x))],
    call = call
  )
  custom <- x[["custom"]]

  if (!is.null(custom) && (!is.list(custom) || !is_named2(custom))) {
    cli_abort("{.field custom} must be a named list (a YAML mapping).", call = call)
  }

  columns <- x[["columns"]]

  if (!is.list(columns) || is_named(columns)) {
    cli_abort(
      "{.field columns} must be an unnamed list (a YAML sequence).",
      call = call
    )
  }

  # A loop (not purrr::imap()) so errors aren't wrapped with the index
  for (i in seq_along(columns)) {
    column <- columns[[i]]
    label <- if (is_string(column[["name"]])) {
      column[["name"]]
    } else {
      paste0("columns[[", i, "]]")
    }

    columns[[i]] <- validate_column_definition(
      column,
      allow_read_only = FALSE,
      allow_custom = TRUE,
      require_type = TRUE,
      label = label,
      call = call
    )
  }

  col_names <- purrr::map_chr(columns, "name")
  dupes <- unique(col_names[duplicated(col_names)])

  if (length(dupes) > 0) {
    cli_abort(
      "Column names must be unique. Duplicated: {.field {dupes}}.",
      call = call
    )
  }

  display_names <- purrr::map_chr(
    columns,
    \(column) column[["displayName"]] %||% column[["name"]]
  )
  dupe_display <- unique(display_names[duplicated(display_names)])

  if (length(dupe_display) > 0) {
    cli_warn(
      c(
        "Duplicated column display name{?s}: {.val {dupe_display}}.",
        "i" = "Formulas reference columns by display name."
      ),
      call = call
    )
  }

  views <- check_sp_list_definition_views(
    x[["views"]],
    col_names = col_names,
    call = call
  )

  new_sp_list_definition(
    display_name = x[["displayName"]],
    columns = columns,
    description = x[["description"]],
    list_info = list_info,
    read_only = read_only,
    custom = custom,
    views = views,
    format_version = as.integer(format_version)
  )
}

#' Fields that can be shown in a view without being defined as columns
#' @noRd
sp_view_builtin_fields <- c(
  "Title",
  "LinkTitle",
  "LinkTitleNoMenu",
  "ID",
  "Created",
  "Modified",
  "Author",
  "Editor",
  sp_list_internal_colnames
)

#' Check the `views` element of a list definition
#'
#' Validates each view, checks that view titles are unique and that only one
#' view is the default view, and warns if a view shows fields that aren't
#' columns in the definition.
#' @noRd
check_sp_list_definition_views <- function(
  views,
  col_names = character(0),
  call = caller_env()
) {
  if (is.null(views)) {
    return(NULL)
  }

  if (!is.list(views) || is_named(views)) {
    cli_abort(
      "{.field views} must be an unnamed list (a YAML sequence).",
      call = call
    )
  }

  for (i in seq_along(views)) {
    label <- views[[i]][["Title"]] %||% paste0("views[[", i, "]]")

    views[[i]] <- validate_view_definition(
      views[[i]],
      formatter_as_list = TRUE,
      label = if (is_string(label)) label else paste0("views[[", i, "]]"),
      call = call
    )
  }

  titles <- purrr::map_chr(views, "Title")
  dupes <- unique(titles[duplicated(titles)])

  if (length(dupes) > 0) {
    cli_abort(
      "View titles must be unique. Duplicated: {.val {dupes}}.",
      call = call
    )
  }

  defaults <- titles[purrr::map_lgl(views, \(view) isTRUE(view[["DefaultView"]]))]

  if (length(defaults) > 1) {
    cli_abort(
      "Only one view can be the default view, not {.val {defaults}}.",
      call = call
    )
  }

  unknown <- purrr::map(
    views,
    \(view) setdiff(view[["ViewFields"]], c(col_names, sp_view_builtin_fields))
  )
  unknown <- purrr::set_names(unknown, titles)
  unknown <- purrr::discard(unknown, \(x) length(x) == 0)

  if (length(unknown) > 0) {
    cli_warn(
      c(
        "Views show fields that aren't columns in the definition:",
        set_names(
          purrr::imap_chr(unknown, \(fields, title) {
            cli::format_inline("{.val {title}}: {.field {fields}}")
          }),
          rep("*", length(unknown))
        )
      ),
      call = call
    )
  }

  views
}

#' Read-only list properties
#' <https://learn.microsoft.com/en-us/graph/api/resources/list?view=graph-rest-1.0>
#' @noRd
sp_list_read_only_props <- list(
  id = "string",
  name = "string",
  webUrl = "string",
  createdDateTime = "string",
  createdBy = "mapping",
  lastModifiedDateTime = "string",
  lastModifiedBy = "mapping",
  eTag = "string",
  parentReference = "mapping",
  sharepointIds = "mapping",
  system = "mapping"
)

#' Read-only list properties that don't change after a list is created
#'
#' `createdBy` is stable but excluded since it includes personal information.
#' @noRd
sp_list_stable_props <- c(
  "id",
  "name",
  "webUrl",
  "createdDateTime",
  "parentReference",
  "sharepointIds",
  "system"
)

#' Check read-only list properties
#' @noRd
check_sp_list_read_only <- function(x, call = caller_env()) {
  for (prop in names(x)) {
    if (sp_list_read_only_props[[prop]] == "mapping") {
      if (!is.list(x[[prop]]) || !is_named2(x[[prop]])) {
        cli_abort(
          "{.field {prop}} must be a named list (a YAML mapping).",
          call = call
        )
      }
    } else {
      # Timestamps may be parsed as other types, so coerce scalars to strings
      if (is_scalar_atomic(x[[prop]]) && !is.na(x[[prop]])) {
        x[[prop]] <- as.character(x[[prop]])
      }
      check_string(x[[prop]], arg = prop, call = call)
    }
  }

  if (length(x) == 0) {
    return(NULL)
  }

  x
}

#' Resolve the `read_only` argument to property names
#' @noRd
resolve_read_only_props <- function(read_only, call = caller_env()) {
  check_character(read_only, call = call)

  if (is_string(read_only) && read_only %in% c("stable", "all", "none")) {
    return(switch(
      read_only,
      stable = sp_list_stable_props,
      all = names(sp_list_read_only_props),
      none = character(0)
    ))
  }

  unknown <- setdiff(read_only, names(sp_list_read_only_props))

  if (length(unknown) > 0) {
    cli_abort(
      c(
        "{.arg read_only} must be {.val stable}, {.val all}, {.val none}, or
        read-only list property names.",
        "x" = "Unknown propert{?y/ies}: {.val {unknown}}."
      ),
      call = call
    )
  }

  read_only
}

#' listInfo properties
#' <https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0>
#' @noRd
sp_list_info_props <- list(
  template = "string",
  hidden = "bool",
  contentTypesEnabled = "bool"
)

#' Check the `list` element of a list definition
#' @noRd
check_sp_list_info <- function(x, call = caller_env()) {
  if (is.null(x)) {
    return(NULL)
  }

  if (!is.list(x) || !is_named2(x)) {
    cli_abort("{.field list} must be a named list (a YAML mapping).", call = call)
  }

  unknown <- setdiff(names(x), names(sp_list_info_props))

  if (length(unknown) > 0) {
    abort_unknown_props(
      unknown,
      label = "list",
      allowed = names(sp_list_info_props),
      call = call
    )
  }

  for (prop in names(x)) {
    x[[prop]] <- check_sp_prop(
      x[[prop]],
      rule = sp_list_info_props[[prop]],
      arg = paste0("list.", prop),
      call = call
    )
  }

  x
}

#' @noRd
new_sp_list_definition <- function(
  display_name,
  columns = list(),
  description = NULL,
  list_info = NULL,
  read_only = NULL,
  custom = NULL,
  views = NULL,
  format_version = 1L
) {
  read_only <- read_only[intersect(names(sp_list_read_only_props), names(read_only))]

  structure(
    c(
      list(
        format_version = format_version,
        displayName = display_name,
        description = description,
        list = list_info
      ),
      read_only,
      list(
        custom = custom,
        columns = columns,
        views = views
      )
    ),
    class = "sp_list_definition"
  )
}

#' Get the read-only list properties from a definition
#' @noRd
sp_list_definition_read_only <- function(x) {
  props <- unclass(x)[intersect(names(sp_list_read_only_props), names(x))]
  purrr::discard(props, is.null)
}

#' @export
print.sp_list_definition <- function(x, ...) {
  types <- purrr::map_chr(x[["columns"]], \(col) column_type_key(col) %||% "")
  type_counts <- table(types)

  cli::cli_text(
    "{.cls sp_list_definition} {.strong {x[['displayName']]}}",
    if (!is.null(x[["list"]][["template"]])) " ({x[['list']][['template']]})"
  )

  if (!is.null(x[["description"]])) {
    cli::cli_text(x[["description"]])
  }

  if (!is.null(x[["webUrl"]] %||% x[["id"]])) {
    cli::cli_text("Existing list: {.url {x[['webUrl']] %||% x[['id']]}}")
  }

  cli::cli_text(
    "{length(x[['columns']])} column{?s}: ",
    "{paste(names(type_counts), type_counts, sep = ' (', collapse = '), ')}",
    if (length(type_counts) > 0) ")"
  )

  if (length(x[["views"]]) > 0) {
    cli::cli_text(
      "{length(x[['views']])} view{?s}: {.val {purrr::map_chr(x[['views']], 'Title')}}"
    )
  }

  invisible(x)
}

#' Get columns from a list definition formatted for the Graph API
#'
#' Drops the `custom` element from each column. If `drop_validation` is `TRUE`,
#' also drops the `validation` element since the Graph API doesn't support it.
#' @noRd
sp_list_definition_columns <- function(x, drop_validation = FALSE) {
  if (inherits(x, "sp_list_definition")) {
    x <- x[["columns"]]
  }

  # A single column definition
  if (is_named(x) && has_name(x, "name")) {
    x <- list(x)
  }

  # Column ids are references to existing columns
  drop <- c("custom", "id", if (drop_validation) "validation")

  purrr::map(x, \(col) as_column_body(col[setdiff(names(col), drop)]))
}

#' Prepare a column definition to send to the Graph API
#'
#' Converts empty column type properties to an empty named list so they are
#' sent as a JSON object (`{}`) instead of an array (`[]`).
#' @noRd
as_column_body <- function(col) {
  type <- column_type_key(col)

  if (!is.null(type) && length(col[[type]]) == 0) {
    col[[type]] <- set_names(list(), character(0))
  }

  col
}

#' @rdname sp_list_definition
#' @inheritParams get_sp_list_metadata
#' @param keep_defaults If `FALSE` (default), drop properties with the default
#'   value returned by the Graph API (e.g. `required: false`) to keep
#'   definitions short. Properties that aren't included aren't compared by
#'   [compare_sp_list()].
#' @param read_only Read-only list properties to include as a reference to
#'   the existing list. One of `"stable"` (default) for properties that don't
#'   change after a list is created (`id`, `name`, `webUrl`, `createdDateTime`,
#'   `parentReference`, `sharepointIds`, and `system`), `"all"`, `"none"`, or
#'   a character vector of property names (e.g. `c("id", "createdBy")`).
#'   Column ids (and view ids) are included if `"id"` is included.
#'   `createdBy` and `lastModifiedBy` include the name and email of a person.
#' @param include_views If `TRUE`, include the list views (excluding hidden and
#'   personal views). Defaults to `FALSE`. Views are read with the SharePoint
#'   REST API, which requires a delegated (user) login. See
#'   [list_sp_list_views()].
#' @export
get_sp_list_definition <- function(
  sp_list = NULL,
  ...,
  keep_defaults = FALSE,
  read_only = "stable",
  include_views = FALSE,
  call = caller_env()
) {
  check_bool(include_views, call = call)
  read_only <- resolve_read_only_props(read_only, call = call)

  sp_list <- sp_list %||%
    get_sp_list(..., metadata = FALSE, as_data_frame = FALSE, call = call)

  check_ms_obj(sp_list, "ms_list", call = call)

  columns <- sp_list_live_columns(
    sp_list,
    keep_defaults = keep_defaults,
    keep_id = "id" %in% read_only,
    exclude = c("id", sp_list_internal_colnames),
    call = call
  )

  # Include the Title column only if it differs from the default
  columns <- purrr::discard(
    columns,
    \(col) {
      identical(col[["name"]], "Title") &&
        !keep_defaults &&
        identical(col[["displayName"]], "Title") &&
        setequal(setdiff(names(col), "id"), c("name", "displayName", "text")) &&
        length(col[["text"]]) == 0
    }
  )

  no_type <- purrr::map_lgl(columns, \(col) is.null(column_type_key(col)))

  if (any(no_type)) {
    cli_warn(
      c(
        "Skipping {sum(no_type)} column{?s} with a column type the Graph API
        doesn't return: {.field {purrr::map_chr(columns[no_type], 'name')}}.",
        "i" = "Hyperlink, picture, thumbnail, and term columns don't include
        a column type when read with the Graph API."
      ),
      call = call
    )
  }

  description <- sp_list[["properties"]][["description"]]

  if (identical(description, "")) {
    description <- NULL
  }

  list_info <- sp_list[["properties"]][["list"]]
  list_info <- list_info[intersect(names(list_info), names(sp_list_info_props))]

  if (!keep_defaults) {
    list_info <- purrr::discard(list_info, isFALSE)
  }

  new_sp_list_definition(
    display_name = sp_list[["properties"]][["displayName"]],
    columns = purrr::map(columns[!no_type], order_column_keys),
    description = description,
    list_info = if (length(list_info) > 0) list_info,
    read_only = purrr::discard(sp_list[["properties"]][read_only], is.null),
    views = if (include_views) {
      get_sp_list_definition_views(
        sp_list,
        keep_id = "id" %in% read_only,
        keep_defaults = keep_defaults,
        call = call
      )
    }
  )
}

#' Get view definitions for an existing list
#' @noRd
get_sp_list_definition_views <- function(
  sp_list,
  keep_id = FALSE,
  keep_defaults = FALSE,
  call = caller_env()
) {
  views <- list_sp_list_views(sp_list, as_data_frame = FALSE, call = call)
  views <- purrr::discard(views, \(view) isTRUE(view[["PersonalView"]]))

  purrr::map(
    views,
    \(view) as_definition_view(view, keep_id = keep_id, keep_defaults = keep_defaults)
  )
}

#' Get cleaned column definitions for an existing list
#'
#' @param exclude Column names to exclude.
#' @returns A list of column definitions using writable columnDefinition
#'   properties. Columns with a type the Graph API doesn't return have no
#'   column type key.
#' @noRd
sp_list_live_columns <- function(
  sp_list,
  keep_defaults = TRUE,
  keep_id = FALSE,
  exclude = c("Title", "id", sp_list_internal_colnames),
  call = caller_env()
) {
  meta <- get_sp_list_metadata(
    sp_list = sp_list,
    as_data_frame = FALSE,
    call = call
  )

  as_live_columns(
    meta,
    keep_defaults = keep_defaults,
    keep_id = keep_id,
    exclude = exclude
  )
}

#' Clean a list of column metadata from the Graph API
#' @noRd
as_live_columns <- function(
  meta,
  keep_defaults = TRUE,
  keep_id = FALSE,
  exclude = c("Title", "id", sp_list_internal_colnames)
) {
  meta <- purrr::keep(meta, \(col) !col[["name"]] %in% exclude)
  purrr::map(
    meta,
    \(col) clean_live_column(col, keep_defaults = keep_defaults, keep_id = keep_id)
  )
}

#' Clean a column definition returned by the Graph API
#'
#' Keeps only writable columnDefinition properties and the properties for the
#' column type, converts choices to a character vector, and optionally drops
#' default values.
#' @noRd
clean_live_column <- function(col, keep_defaults = TRUE, keep_id = FALSE) {
  writable <- setdiff(
    names(sp_column_props),
    c("isDeletable", "isSealed", "propagateChanges", "columnGroup")
  )

  col <- col[intersect(
    names(col),
    c(writable, if (keep_id) "id", names(sp_column_type_props))
  )]
  # Drop NULL values but keep empty column type properties (e.g. `boolean`)
  col <- purrr::discard(col, is.null)
  type <- column_type_key(col)

  if (!is.null(type)) {
    props <- col[[type]]
    props <- props[intersect(names(props), names(sp_column_type_props[[type]]))]
    props <- purrr::compact(props)

    if (has_name(props, "choices")) {
      props[["choices"]] <- as.character(unlist(props[["choices"]]))
    }

    if (!keep_defaults) {
      props <- drop_default_values(props, type)
    }

    if (length(props) == 0) {
      props <- set_names(list(), character(0))
    }

    col[[type]] <- props
  }

  if (identical(col[["description"]], "")) {
    col[["description"]] <- NULL
  }

  default_value <- purrr::compact(col[["defaultValue"]])
  default_value <- purrr::discard(default_value, \(v) identical(v, ""))

  col[["defaultValue"]] <- if (length(default_value) > 0) default_value

  # Calculated columns are always read-only
  if (identical(type, "calculated")) {
    col[["readOnly"]] <- NULL
  }

  if (!keep_defaults) {
    col <- drop_default_values(col, "column")
  }

  purrr::discard(col, is.null)
}

#' Drop properties with default values
#' @noRd
drop_default_values <- function(props, type) {
  defaults <- sp_column_default_values[[type]] %||% list()

  is_default <- purrr::imap_lgl(
    props,
    \(value, prop) is_default_value(value, prop, type, props, defaults)
  )

  props[!is_default]
}

#' @noRd
is_default_value <- function(
  value,
  prop,
  type,
  props = list(),
  defaults = sp_column_default_values[[type]]
) {
  if (has_name(defaults, prop) && identical(value, defaults[[prop]])) {
    return(TRUE)
  }

  if (type == "text") {
    multiple <- isTRUE(props[["allowMultipleLines"]])

    if (prop == "linesForEditing") {
      return(value == if (multiple) 6 else 0)
    }

    if (prop == "maxLength") {
      return(value == 255)
    }
  }

  # Graph returns the largest double for an unset number column maximum or
  # minimum
  if (type == "number" && prop %in% c("maximum", "minimum")) {
    return(abs(value) >= 1e300)
  }

  FALSE
}

#' Order column definition keys for writing
#' @noRd
order_column_keys <- function(col) {
  type <- column_type_key(col)
  keys <- c(
    "name",
    "id",
    names(sp_column_props),
    type,
    "custom"
  )

  col[c(intersect(keys, names(col)), setdiff(names(col), keys))]
}

#' @rdname sp_list_definition
#' @param merge If `TRUE` (default) and `path` exists, keep the comment header
#'   and column order from the existing file. `custom` metadata for the list
#'   and each column comes from `x` if it has any and is otherwise kept from
#'   the existing file (a list never has `custom` metadata, so it's always
#'   kept when `x` is a `ms_list` object). Read-only list properties
#'   and column ids always come from `x`. Views come from `x` if it has views
#'   (e.g. with `include_views = TRUE`) and are otherwise kept from the
#'   existing file. Columns that are only in the existing file are dropped
#'   (unless the Graph API doesn't return their column type). Comments after
#'   the header are always lost.
#' @param doc_start If `TRUE`, write a document start marker (`---`) after the
#'   comment header (or at the start of a file with no header). If `FALSE`,
#'   don't. If `NULL` (default), write the marker only if the existing file
#'   has one (with `merge = TRUE`).
#' @export
write_sp_list_yaml <- function(
  x,
  path,
  ...,
  merge = TRUE,
  keep_defaults = FALSE,
  read_only = "stable",
  include_views = FALSE,
  doc_start = NULL,
  call = caller_env()
) {
  check_dots_empty()
  check_installed("yaml12", call = call)
  check_string(path, call = call)
  check_bool(merge, call = call)
  check_bool(doc_start, allow_null = TRUE, call = call)

  if (inherits(x, "ms_list")) {
    x <- get_sp_list_definition(
      sp_list = x,
      keep_defaults = keep_defaults,
      read_only = read_only,
      include_views = include_views,
      call = call
    )
  } else {
    x <- as_sp_list_definition(x, call = call)
  }

  header <- NULL
  existing_doc_start <- FALSE

  if (merge && file.exists(path)) {
    header <- read_yaml_header(path, call = call)
    existing_doc_start <- attr(header, "doc_start")
    attr(header, "doc_start") <- NULL
    existing <- read_sp_list_yaml(path, call = call)
    x <- merge_sp_list_definition(x, existing, call = call)
  }

  x[["columns"]] <- purrr::map(x[["columns"]], order_column_keys)
  yaml <- yaml12::format_yaml(as_yaml_list(x))

  doc_start <- doc_start %||% existing_doc_start

  # The document start marker ends the header, so it's written with no blank
  # line before it
  writeLines(
    c(
      header,
      if (doc_start) "---" else if (length(header) > 0) "",
      yaml
    ),
    path
  )

  cli_inform(
    c("v" = "Wrote {length(x[['columns']])} column{?s} to {.file {path}}.")
  )

  invisible(x)
}

#' Merge a definition with an existing definition
#'
#' Uses `x` for column definitions and keeps column order and columns with a
#' type the Graph API doesn't return from `existing`. `custom` metadata (for
#' the list and each column) comes from `x` if it has any (e.g. an edited
#' definition) and is otherwise kept from `existing` (e.g. for a definition
#' from a list, which never has `custom` metadata).
#' @noRd
merge_sp_list_definition <- function(x, existing, call = caller_env()) {
  new_cols <- set_names(x[["columns"]], purrr::map_chr(x[["columns"]], "name"))
  old_cols <- set_names(
    existing[["columns"]],
    purrr::map_chr(existing[["columns"]], "name")
  )

  # Keep columns with a type the Graph API doesn't return and the Title column
  # (which is left out of a live definition if it has default settings)
  keep_old <- names(old_cols)[
    purrr::map_lgl(
      old_cols,
      \(col) {
        column_type_key(col) %in% sp_column_types_create_unsupported ||
          identical(col[["name"]], "Title")
      }
    )
  ]
  keep_old <- setdiff(keep_old, names(new_cols))

  dropped <- setdiff(names(old_cols), c(names(new_cols), keep_old))

  if (length(dropped) > 0) {
    cli_inform(
      c(
        "!" = "Dropping {length(dropped)} column{?s} not found in the list:
        {.field {dropped}}."
      )
    )
  }

  col_order <- c(
    intersect(names(old_cols), c(names(new_cols), keep_old)),
    setdiff(names(new_cols), names(old_cols))
  )

  columns <- purrr::map(
    col_order,
    \(nm) {
      if (nm %in% keep_old) {
        return(old_cols[[nm]])
      }

      col <- new_cols[[nm]]
      custom <- col[["custom"]] %||% old_cols[[nm]][["custom"]]
      col[["custom"]] <- NULL
      col[["custom"]] <- custom
      col
    }
  )

  new_sp_list_definition(
    display_name = x[["displayName"]],
    columns = columns,
    description = x[["description"]] %||% existing[["description"]],
    list_info = x[["list"]] %||% existing[["list"]],
    read_only = sp_list_definition_read_only(x),
    custom = x[["custom"]] %||% existing[["custom"]],
    views = x[["views"]] %||% existing[["views"]],
    format_version = x[["format_version"]]
  )
}

#' Read the comment header from a YAML file
#'
#' Returns the comment and blank lines before the first key (or before a
#' document start marker, `---`, if the file has one) and warns if the file
#' has comments after the header. The `doc_start` attribute is `TRUE` if the
#' header ends with a document start marker.
#' @noRd
read_yaml_header <- function(path, call = caller_env()) {
  lines <- readLines(path, warn = FALSE)
  is_header <- grepl("^\\s*(#.*)?$", lines)
  first_key <- match(FALSE, is_header)

  if (is.na(first_key)) {
    return(structure(lines, doc_start = FALSE))
  }

  doc_start <- grepl("^---\\s*(#.*)?$", lines[[first_key]])

  header <- lines[seq_len(first_key - 1)]
  # Drop trailing blank lines
  while (length(header) > 0 && !nzchar(trimws(header[length(header)]))) {
    header <- header[-length(header)]
  }

  # The body starts after the document start marker, if the file has one
  body <- lines[(first_key + doc_start):length(lines)]
  # Remove quoted strings before looking for comments
  unquoted <- gsub("\"([^\"\\\\]|\\\\.)*\"|'[^']*'", "", body)

  if (any(grepl("(^|\\s)#", unquoted))) {
    cli_warn(
      c(
        "{.file {path}} has comments after the header.",
        "!" = "Only the comments before the first key (or before a
        {.code ---} document start marker) are kept."
      ),
      call = call
    )
  }

  structure(header, doc_start = doc_start)
}

#' Convert a definition to a list for writing YAML
#' @noRd
as_yaml_list <- function(x) {
  columns <- purrr::map(
    x[["columns"]],
    \(col) {
      col <- order_column_keys(col)
      type <- column_type_key(col)

      if (!is.null(type)) {
        props <- col[[type]]

        # Write choices as a sequence even if there is a single choice
        if (has_name(props, "choices")) {
          props[["choices"]] <- as.list(props[["choices"]])
        }

        col[[type]] <- if (length(props) == 0) {
          set_names(list(), character(0))
        } else {
          props
        }
      }

      col
    }
  )

  yaml <- purrr::compact(
    c(
      list(
        format_version = x[["format_version"]] %||% 1L,
        displayName = x[["displayName"]],
        description = x[["description"]],
        list = x[["list"]]
      ),
      sp_list_definition_read_only(x),
      list(custom = x[["custom"]])
    )
  )

  # `columns` is required, so a definition with no columns (e.g. a list with
  # only the default Title column) is written as `columns: []`
  yaml[["columns"]] <- columns

  views <- purrr::map(x[["views"]], as_yaml_view)

  if (length(views) > 0) {
    yaml[["views"]] <- views
  }

  yaml
}

#' Convert a view definition to a list for writing YAML
#' @noRd
as_yaml_view <- function(view) {
  view <- order_view_keys(view)

  # Write fields as a sequence even if there is a single field
  if (has_name(view, "ViewFields")) {
    view[["ViewFields"]] <- as.list(view[["ViewFields"]])
  }

  view
}

#' Order view definition keys for writing
#' @noRd
order_view_keys <- function(view) {
  keys <- c(
    "Title",
    "Id",
    "ServerRelativeUrl",
    "DefaultView",
    "ViewFields",
    "ViewQuery",
    "RowLimit",
    "Paged",
    "Scope",
    "Hidden",
    "MobileView",
    "MobileDefaultView",
    "CustomFormatter"
  )

  view[c(intersect(keys, names(view)), setdiff(names(view), keys))]
}

#' Default SP.View property values
#'
#' Used to drop default values when writing view definitions.
#' @noRd
sp_view_default_values <- list(
  DefaultView = FALSE,
  RowLimit = 30L,
  Paged = TRUE,
  Scope = 0L,
  Hidden = FALSE,
  MobileView = FALSE,
  MobileDefaultView = FALSE,
  ViewQuery = ""
)

#' Convert a view from the SharePoint REST API to a view definition
#'
#' @param view A view from `list_sp_list_views(as_data_frame = FALSE)`.
#' @param keep_id If `TRUE`, keep `Id` and `ServerRelativeUrl` as a reference.
#' @noRd
as_definition_view <- function(view, keep_id = FALSE, keep_defaults = FALSE) {
  view <- view[intersect(
    names(view),
    c(names(sp_view_props), if (keep_id) c("Id", "ServerRelativeUrl"))
  )]

  # Write view formatting as a YAML mapping
  formatter <- view[["CustomFormatter"]]

  if (is_string(formatter) && nzchar(formatter)) {
    view[["CustomFormatter"]] <- jsonlite::fromJSON(formatter, simplifyVector = FALSE)
  }

  if (!keep_defaults) {
    is_default <- purrr::imap_lgl(
      view,
      \(value, prop) {
        has_name(sp_view_default_values, prop) &&
          identical(value, sp_view_default_values[[prop]])
      }
    )
    view <- view[!is_default]
  }

  order_view_keys(purrr::discard(view, is.null))
}

#' Convert a list definition to a data frame
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' [sp_list_definition_table()] converts a `sp_list_definition` object to a
#' data frame with one row per column. The `as.data.frame()` method for
#' `sp_list_definition` objects uses the same function.
#'
#' The data frame has `list_name`, `name`, `displayName`, `description`, and
#' `type` columns followed by any other column-level properties, the
#' properties for each column type, and the `custom` metadata for each
#' column. Properties for column types aren't prefixed since each column has a
#' single column type. Properties with more than one value (e.g. `choices`)
#' are list columns and all other columns are simplified to atomic vectors.
#'
#' @param x A `sp_list_definition` object or a path to a YAML file.
#' @param custom If `TRUE` (default), include the `custom` metadata for each
#'   column.
#' @param custom_prefix Optional prefix added to the names of `custom`
#'   metadata columns. A `custom` key with the same name as a columnDefinition
#'   property is an error unless a prefix is supplied.
#' @param row.names,optional,... Ignored.
#' @returns A data frame with one row per column.
#' @keywords lists
#' @examples
#' path <- system.file("extdata", "example-list.yaml", package = "sharepointr")
#'
#' sp_list_definition_table(path)
#'
#' @export
sp_list_definition_table <- function(
  x,
  custom = TRUE,
  custom_prefix = NULL
) {
  if (is_string(x)) {
    x <- read_sp_list_yaml(x)
  }

  x <- as_sp_list_definition(x)
  check_bool(custom)
  check_string(custom_prefix, allow_null = TRUE)

  reserved <- c(
    "list_name",
    "type",
    "id",
    names(sp_column_props),
    unique(unlist(purrr::map(sp_column_type_props, names)))
  )

  if (custom) {
    for (col in x[["columns"]]) {
      keys <- paste0(custom_prefix %||% "", names(col[["custom"]]))
      collisions <- intersect(keys, reserved)

      if (length(collisions) > 0) {
        cli_abort(
          c(
            "{.field {collisions}} in the {.field custom} metadata for column
            {.field {col[['name']]}} can't use the name of a column property.",
            "i" = "Use {.arg custom_prefix} to add a prefix to the names of
            {.field custom} metadata."
          )
        )
      }
    }
  }

  rows <- purrr::map(
    x[["columns"]],
    \(col) {
      type <- column_type_key(col)
      base <- col[setdiff(names(col), c(type, "custom"))]
      row <- c(
        list(list_name = x[["displayName"]]),
        base[intersect(c("name", "displayName", "description"), names(base))],
        list(type = type),
        base[setdiff(names(base), c("name", "displayName", "description"))],
        col[[type]]
      )

      if (custom && length(col[["custom"]]) > 0) {
        col_custom <- col[["custom"]]

        if (!is.null(custom_prefix)) {
          names(col_custom) <- paste0(custom_prefix, names(col_custom))
        }

        row <- c(row, col_custom)
      }

      vctrs::new_data_frame(purrr::map(row, list), n = 1L)
    }
  )

  table <- vctrs::vec_rbind(!!!rows)

  first <- c("list_name", "name", "displayName", "description", "type")
  table <- table[c(
    intersect(first, names(table)),
    setdiff(names(table), first)
  )]

  table[] <- purrr::map(table, simplify_list_col)
  table
}

#' @rdname sp_list_definition_table
#' @export
as.data.frame.sp_list_definition <- function(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  custom = TRUE,
  custom_prefix = NULL
) {
  sp_list_definition_table(x, custom = custom, custom_prefix = custom_prefix)
}

#' Simplify a list column if every element has length 0 or 1
#' @noRd
simplify_list_col <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  lengths <- lengths(x)

  if (any(lengths > 1) || any(purrr::map_lgl(x, is.list))) {
    return(x)
  }

  x[lengths == 0] <- list(NA)
  purrr::list_simplify(x, strict = FALSE)
}
