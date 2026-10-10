#' Get drive or site for list
#'
#' @returns A `ms_drive` object if a drive is identified by `drive`,
#'   `drive_name`, or `drive_id`. Otherwise, a `ms_site` object.
#' @noRd
get_ms_list_obj <- function(
  list_name = NULL,
  list_id = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  get_sp_drive_obj <- any(c(
    !is.null(drive),
    !is.null(drive_name) && !identical(drive_name, "Lists"),
    !is.null(drive_id)
  ))

  if (get_sp_drive_obj) {
    drive <- drive %||%
      get_sp_drive(
        drive_name = drive_name,
        drive_id = drive_id,
        ...,
        properties = FALSE,
        site = site,
        site_url = site_url,
        call = call
      )

    check_ms_drive(drive, call = call)

    return(drive)
  }

  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

  check_ms_site(site, call = call)

  site
}

#' Get a SharePoint list or a list of SharePoint lists
#'
#' [get_sp_list()] is a wrapper for the `get_list` and `list_items` methods.
#' This function is still under development and does not support the URL parsing
#' used by [get_sp_item()]. [list_sp_lists()] returns all lists for a SharePoint
#' site or drive as a list or data frame. Note, when using `filter` with
#' [get_sp_list()], names used in the expression must be prefixed with "fields/"
#' to distinguish them from item metadata.
#'
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @seealso
#' - [Microsoft365R::ms_list]
#' - [Microsoft365R::ms_list_item]
#' - [create_sp_list()]; [delete_sp_list()]
#' @name sp_list
NULL

#' @rdname sp_list
#' @name get_sp_list
#' @param list_name,list_id SharePoint List name or ID string.
#' @param as_data_frame If `TRUE`, return a data frame with a "ms_list" column.
#'   [get_sp_list()] returns a 1 row data frame and [list_sp_lists()] returns a
#'   data frame with n rows or all lists available for the SharePoint site or
#'   drive. Defaults to `FALSE`. Ignored is `metadata = TRUE` as list metadata
#'   is always returned as a data frame.
#' @param metadata If `TRUE`, [get_sp_list()] applies the `get_column_info`
#'   method to the returned SharePoint list and returns a data frame with column
#'   metadata for the list.
#' @returns A data frame `as_data_frame = TRUE` or a `ms_list` object (or list
#'   of `ms_list` objects) if `FALSE`.
#' @keywords lists
#' @export
get_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  metadata = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  # FIXME: URL parsing is not set up for links to SharePoint lists
  if (is_url(list_name)) {
    url <- list_name
    list_name <- NULL

    check_sp_list_url(url, call = call)

    sp_url_parts <- sp_url_parse(
      url = url,
      call = call
    )

    # FIXME: Parsing the drive_name for lists does not typically work
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]

    if (is_null(list_id) && is_null(sp_url_parts[["item_id"]])) {
      list_name <- sp_url_parts[["list_name"]] %||% sp_url_parts[["file"]]
    }

    list_id <- list_id %||% sp_url_parts[["item_id"]]
    site_url <- site_url %||% sp_url_parts[["site_url"]]
  }

  ms_list_obj <- get_ms_list_obj(
    list_name = list_name,
    list_id = list_id,
    ...,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  check_exclusive_strings(list_name, list_id, call = call)

  hidden_lists <- "User Information List"

  cli::cli_progress_step(
    "Getting list from SharePoint"
  )

  sp_list <- NULL

  if (!is.null(list_name) && !(list_name %in% hidden_lists)) {
    # FIXME: This is a work around to handle lists that have been renamed

    if (is_ms_site(ms_list_obj)) {
      sp_lists <- list_sp_lists(
        site = ms_list_obj,
        as_data_frame = FALSE,
        call = call
      )
    } else if (is_ms_drive(ms_list_obj)) {
      sp_lists <- list_sp_lists(
        drive = ms_list_obj,
        as_data_frame = FALSE,
        call = call
      )
    } else {
      # TODO: Add handling for displayName validation
      sp_lists <- list_sp_lists(
        ...,
        site_url = site_url,
        site = site,
        drive_name = drive_name,
        drive_id = drive_id,
        as_data_frame = FALSE,
        drive = drive,
        call = call
      )
    }

    nm_values <- purrr::map_chr(sp_lists, \(x) x$properties$name)

    list_name <- arg_match(list_name, values = nm_values, error_call = call)

    # Use the matching list from the site lists (with the same properties as
    # the get_list method) instead of getting the list again
    sp_list <- sp_lists[[match(list_name, nm_values)]]
  }

  if (is.null(sp_list)) {
    sp_list <- ms_list_obj$get_list(
      list_name = list_name,
      list_id = list_id
    )
  }

  # TODO: Consider removing the metadata argument
  if (metadata) {
    if (!as_data_frame) {
      cli_warn(
        c(
          "{.code metadata = TRUE} always returns a data frame.",
          "i" = "Ignoring {.code as_data_frame = FALSE} parameter."
        )
      )
    }

    return(sp_list$get_column_info())
  }

  if (!as_data_frame) {
    return(sp_list)
  }

  ms_obj_as_data_frame(
    sp_list,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
  )
}

#' @rdname sp_list
#' @name list_sp_lists
#' @inheritParams ms_graph_arg_terms
#' @export
list_sp_lists <- function(
  site_url = NULL,
  filter = NULL,
  n = Inf,
  ...,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  ms_list_obj <- get_ms_list_obj(
    site_url = site_url,
    ...,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  sp_lists <- ms_list_obj$get_lists(filter = filter, n = n)

  if (!as_data_frame) {
    return(sp_lists)
  }

  ms_obj_list_as_data_frame(
    sp_lists,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
  )
}

#' @rdname sp_list
#' @name get_sp_list_metadata
#' @inheritParams ms_graph_obj_terms
#' @param keep One of "all" (default), "editable", "external" (non-internal
#' fields). Argument determines if the returned list metadata includes read
#' only columns or hidden columns.
#' @param sync_fields If `TRUE`, use the `sync_fields` method to sync the fields
#'   of the local `ms_list` object with the fields of the SharePoint List source
#'   before retrieving list metadata.
#' @export
get_sp_list_metadata <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  keep = c("all", "editable", "external"),
  sync_fields = FALSE,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      metadata = FALSE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  if (sync_fields) {
    sp_list <- sp_list$sync_fields()
  }

  sp_list_op_resp <- sp_list$do_operation(
    options = list(expand = "columns"),
    simplify = as_data_frame
  )

  sp_list_meta <- sp_list_op_resp$columns

  keep <- arg_match(keep, error_call = call)

  if (keep == "all") {
    return(sp_list_meta)
  }

  vctrs::vec_slice(
    sp_list_meta,
    pull_sp_list_cols(sp_list_meta, col_type = keep, call = call)
  )
}

#' Create, update, or delete a SharePoint List
#'
#' @description
#' [create_sp_list()] allows the creation of a SharePoint list for a site. See:
#' <https://learn.microsoft.com/en-us/graph/api/list-create?view=graph-rest-1.0&tabs=http>
#'
#' [update_sp_list()] allows the modification of the list display name and
#' description.
#'
#' [delete_sp_list()] deletes an existing list and requires user confirmation by
#' default.
#'
#' Notes on creating a SharePoint list:
#'
#' - Dashes (`"-"``) in list names are removed from the list name but retained
#'   in the list display name.
#' - Column names longer than 32 characters (counting each space or special
#'   character as 7) are an error for a list (but not a document library),
#'   since SharePoint cuts them without an error. A display name longer than
#'   255 characters (the limit on the column settings page) is a warning.
#' - Calculated columns are added after the list is created since formulas
#'   may reference other columns.
#' - Column validation is applied with the SharePoint REST API after the list
#'   is created since the Graph API doesn't support it.
#' - A `"Title"` column in `columns` or `definition` updates the default
#'   `"Title"` column of a `"genericList"` list (combined with
#'   `title_definition`) instead of adding a new column.
#' - Views in `definition` are created with the SharePoint REST API after the
#'   columns are created. A view titled `"All Items"` updates the default view
#'   of a `"genericList"` list.
#'
#' Notes on updating a SharePoint list:
#'
#' - The `"Title"` column type is always a "text" type column and can't be
#'   changed.
#'
#' @param list_name List name used as `displayName` property. Required unless
#'   `definition` is supplied.
#' @param description Optional description.
#' @param columns Optional. Use [create_column_definition()] to create a single
#' column definition or [create_column_definition_list()] to create a list
#' of column definitions. `custom` metadata is dropped. A `sp_list_definition`
#' object is used as `definition`.
#' @param template Optional list template (Graph listInfo property `template`).
#'   Defaults to `"genericList"`.
#' @inheritParams create_list_info
#' @param title_definition Named list used to update the column definition of
#' the default `"Title"` column created when using the `"genericList"` template.
#' By default, makes Title column optional.
#' @param definition Optional. A list definition from [read_sp_list_yaml()] or
#'   a path to a YAML file. The definition `displayName`, `description`,
#'   `columns`, and `list` settings (`template`, `hidden`, and
#'   `contentTypesEnabled`) are used unless the matching argument is supplied.
#'   Read-only list properties (e.g. `id`) and column ids are ignored.
#'   `definition` can't be combined with `columns`. Views in the definition are
#'   also created (see [list_sp_list_views()]).
#' @inheritParams get_sp_site
#' @returns For [create_sp_list()], invisibly returns a `ms_list` object for
#'   the newly created list. For [update_sp_list()], the updated `ms_list`
#'   object. For [delete_sp_list()], invisibly returns `NULL`.
#' @keywords lists
#' @examples
#' \dontrun{
#' create_sp_list(
#'   definition = "list-fields/capital-project.yaml",
#'   site_url = "<SharePoint site url>"
#' )
#' }
#' @export
create_sp_list <- function(
  list_name = NULL,
  ...,
  description = NULL,
  columns = NULL,
  template = NULL,
  content_types = NULL,
  hidden = NULL,
  title_definition = list(
    required = FALSE
  ),
  definition = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  if (inherits(columns, "sp_list_definition")) {
    if (!is.null(definition)) {
      cli_abort(
        "{.arg columns} can't be a list definition if {.arg definition} is
        supplied.",
        call = call
      )
    }
    definition <- columns
    columns <- NULL
  }

  if (!is.null(definition)) {
    if (!is.null(columns)) {
      cli_abort(
        "{.arg columns} can't be supplied with {.arg definition}.",
        call = call
      )
    }

    if (is_string(definition)) {
      definition <- read_sp_list_yaml(definition, call = call)
    }

    definition <- as_sp_list_definition(definition, call = call)
    list_info <- definition[["list"]]

    if (!is.null(definition[["id"]])) {
      cli_warn(
        c(
          "{.arg definition} has the {.field id} of an existing list:
          {.val {definition[['id']]}}.",
          "i" = "Read-only list properties and column ids are ignored. The
          new list has a new {.field id}."
        ),
        call = call
      )
    }

    list_name <- list_name %||% definition[["displayName"]]
    description <- description %||% definition[["description"]]
    columns <- definition[["columns"]]
    template <- template %||% list_info[["template"]]
    hidden <- hidden %||% list_info[["hidden"]]
    content_types <- content_types %||% list_info[["contentTypesEnabled"]]
  }

  check_string(list_name, call = call)
  template <- template %||% "genericList"
  views <- if (!is.null(definition)) definition[["views"]]

  # Check column names before connecting to the site
  if (!is.null(columns)) {
    check_new_column_names(
      if (is_named(columns) && has_name(columns, "name")) {
        list(columns)
      } else {
        columns
      },
      template = template,
      display_name = FALSE,
      call = call
    )
  }

  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

  check_ms_site(site, call = call)

  validations <- list()
  calculated_columns <- list()
  n_columns <- 0

  if (!is.null(columns)) {
    if (is_named(columns) && has_name(columns, "name")) {
      columns <- list(columns)
    }

    n_columns <- length(columns)
    col_names <- purrr::map_chr(columns, "name")

    # A Title column updates the default Title column
    if (template == "genericList" && "Title" %in% col_names) {
      title_column <- columns[[match("Title", col_names)]]
      title_definition <- utils::modifyList(
        title_definition %||% list(),
        title_column[setdiff(names(title_column), c("name", "id", "custom"))]
      )
      columns <- columns[col_names != "Title"]
    }

    # Calculated columns are added after the list is created
    is_calculated <- purrr::map_lgl(
      columns,
      \(col) identical(column_type_key(col), "calculated")
    )
    calculated_columns <- columns[is_calculated]
    columns <- columns[!is_calculated]

    # Display names of calculated columns are checked when they're added by
    # create_sp_list_column()
    check_new_column_names(columns, template = template, call = call)

    # Validation isn't supported by the Graph API so it is applied after the
    # list is created
    validations <- purrr::compact(
      set_names(
        purrr::map(columns, "validation"),
        purrr::map_chr(columns, "name")
      )
    )

    columns <- sp_list_definition_columns(columns, drop_validation = TRUE)
  }

  body <- purrr::compact(
    list(
      displayName = list_name,
      description = description,
      columns = if (length(columns) > 0) columns,
      list = create_list_info(
        hidden = hidden,
        content_types = content_types,
        template = template,
        call = call
      )
    )
  )

  cli_progress_step(
    "Creating list {.str {list_name}} with {n_columns} column{?s}."
  )

  resp <- site$do_operation(
    op = "lists",
    body = body,
    encode = "json",
    http_verb = "POST"
  )

  cli_progress_step(
    "List created at {.url {resp[['webUrl']]}}."
  )

  sp_list <- suppressMessages(
    get_sp_list(
      list_id = resp[["id"]],
      site = site
    )
  )

  purrr::iwalk(
    validations,
    \(validation, column_name) {
      update_sp_list_column_validation(
        sp_list,
        column_name = column_name,
        validation = validation,
        call = call
      )
    }
  )

  # Update default Title column definition
  # Title is set up as required when using `"genericList"` template
  if (template == "genericList" && !is.null(title_definition)) {
    suppressMessages(
      update_sp_list_column(
        sp_list = sp_list,
        column_name = "Title",
        column_definition = c(list(name = "Title"), title_definition),
        call = call
      )
    )
  }

  for (column in calculated_columns) {
    create_sp_list_column(
      sp_list = sp_list,
      column_definition = column,
      call = call
    )
  }

  # Views are created after all columns since views reference columns
  if (length(views) > 0) {
    create_sp_list_definition_views(
      sp_list,
      views = views,
      template = template,
      call = call
    )
  }

  invisible(sp_list)
}

#' Create the views from a list definition for a new list
#'
#' A view titled "All Items" updates the default view of a `"genericList"`
#' list. The default view is set after all views are created.
#' @noRd
create_sp_list_definition_views <- function(
  sp_list,
  views,
  template = "genericList",
  call = caller_env()
) {
  default_title <- NULL

  for (view in views) {
    if (isTRUE(view[["DefaultView"]])) {
      default_title <- view[["Title"]]
    }

    view <- as_view_to_create(view)

    if (template == "genericList" && identical(view[["Title"]], "All Items")) {
      update_sp_list_view(
        sp_list,
        view_title = "All Items",
        view_definition = view,
        call = call
      )
    } else {
      create_sp_list_view(sp_list, view_definition = view, call = call)
    }
  }

  if (!is.null(default_title)) {
    update_sp_list_view(
      sp_list,
      view_title = default_title,
      default_view = TRUE,
      call = call
    )
  }

  invisible(sp_list)
}

#' @rdname create_sp_list
#' @name update_sp_list
#' @param list_id List ID for list to update or delete.
#' @param display_name Display name to replace existing display name. Used by
#' [update_sp_list()].
#' @inheritParams get_sp_list
#' @export
update_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  display_name = NULL,
  description = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  list_properties <- purrr::compact(
    list(
      displayName = display_name,
      description = description
    )
  )

  inject(sp_list$update(!!!list_properties))
}

#' @rdname create_sp_list
#' @name delete_sp_list
#' @param sp_list A `Microsoft365R::ms_list` object.
#' @inheritParams get_sp_drive
#' @param confirm If `TRUE`, confirm deletion of list before proceeding.
#' @export
delete_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  confirm = TRUE,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  cli_progress_step("Deleting SharePoint list")

  check_ms_obj(sp_list, "ms_list", call = call)

  if (confirm) {
    nm <- sp_list[["properties"]][["displayName"]]
    check_yes(
      cli::format_inline(
        "Do you want to delete the list {.val {nm}}?"
      ),
      call = call
    )
  }

  sp_list$delete(confirm = FALSE)
}

#' Create listinfo object
#'
#' Helper function to create a listInfo object for use internally by
#' [create_sp_list()]. See:
#' <https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0>
#'
#' @param template Type of template to use in creating the list.
#' @param content_types Optional. Set `TRUE` for `contentTypesEnabled` to be
#' enabled.
#' @param hidden Optional. Set `TRUE` for list to be hidden.
#' @keywords internal lists
#' @export
create_list_info <- function(
  template = c(
    "documentLibrary",
    "genericList",
    "task",
    "survey",
    "announcements",
    "contacts"
  ),
  content_types = NULL,
  hidden = NULL,
  call = caller_env()
) {
  # Validate listinfo properties
  template <- arg_match(template, error_call = call)

  check_bool(content_types, allow_null = TRUE, call = call)
  check_bool(hidden, allow_null = TRUE, call = call)

  purrr::compact(
    list(
      hidden = hidden,
      contentTypesEnabled = content_types,
      template = template
    )
  )
}

#' Get SharePoint list column definition for a single column
#'
#' [get_sp_list_column()] gets a list column definition for a single column
#' specified by column name or ID.
#'
#' See the [Get columnDefinition Graph API documentation](https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http) for more information.
#'
#' @inheritParams get_sp_list
#' @param list_name SharePoint List name. Optional if `sp_list` or `list_id` are provided.
#' @inheritDotParams get_sp_list -as_data_frame -metadata
#' @param column_name,column_id Column name or ID to get a definition for.
#' @param column_name_type "name" or "displayName". Used to match column ID so
#' column_name must be unique if `column_name_type = "displayName"`.
#' @returns A named list with the columnDefinition resource for the matched
#'   column.
#' @export
get_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_name_type = "name",
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      ...,
      site_url = site_url,
      site = site,
      metadata = FALSE,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  if (!is.null(column_name) && is.null(column_id)) {
    return(
      sp_list_column_by_name(
        column_name,
        sp_list = sp_list,
        column_name_type = column_name_type,
        call = call
      )
    )
  } else if (!is_string(column_id)) {
    cli::cli_abort(
      "{.arg column_id} or {.arg column_name} must be provided.",
      call = call
    )
  }

  sp_list$do_operation(
    paste0(
      "columns/",
      column_id
    ),
    encode = "json",
    http_verb = "GET"
  )
}

#' Create, update, and delete a SharePoint list column
#'
#' [create_sp_list_column()] adds a column to a SharePoint list and
#' [delete_sp_list_column()] removes a column to a SharePoint list.
#' [update_sp_list_column()] updates a column definition for an existing column
#' in a SharePoint list. Only properties that differ from the existing column
#' are sent. Use [sync_sp_list()] for changes the Graph API can't make,
#' such as switching a text column to multiple lines.
#'
#' See documentation:
#' <https://learn.microsoft.com/en-us/graph/api/list-post-columns?view=graph-rest-1.0&tabs=http>
#'
#' @inheritParams get_sp_list
#' @inheritDotParams create_column_definition
#' @param column_definition List with column definition created with
#' [create_column_definition()] or a related function. Optional if `column_name`
#' and any required additional parameters are provided. A `custom` element
#' (e.g. from [read_sp_list_yaml()]) is dropped. A `validation` element is
#' applied with the SharePoint REST API since the Graph API doesn't support
#' it.
#' @param list_name List name. Required if `sp_list` is `NULL`.
#' @returns For [create_sp_list_column()], a named list with the newly
#'   created columnDefinition resource. For [update_sp_list_column()],
#'   invisibly returns the input `sp_list`. For [delete_sp_list_column()], an
#'   empty list with a `"status"` attribute giving the HTTP response status
#'   code.
#' @export
create_sp_list_column <- function(
  sp_list = NULL,
  ...,
  column_name = NULL,
  column_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      site_url = site_url,
      site = site,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)
  # TODO: Add check for mismatch between `column_name` and
  # column_definition[["column_name"]]

  column_definition <- column_definition %||%
    create_column_definition(
      name = column_name,
      ...
    )

  # Drop custom metadata and column ids (a reference to an existing column)
  # from definitions read with `read_sp_list_yaml()`
  column_definition[["custom"]] <- NULL
  column_definition[["id"]] <- NULL

  check_new_column_names(
    list(column_definition),
    template = sp_list[["properties"]][["list"]][["template"]],
    call = call
  )

  # The Graph API doesn't support validation so apply it with the SharePoint
  # REST API after creating the column
  validation <- column_definition[["validation"]]
  column_definition[["validation"]] <- NULL

  column_definition <- as_column_body(column_definition)
  type <- column_type_key(column_definition)

  resp <- try_fetch(
    sp_list$do_operation(
      op = "columns",
      body = column_definition,
      encode = "json",
      http_verb = "POST"
    ),
    error = function(cnd) {
      if (!type %in% sp_column_types_create_unsupported) {
        cnd_signal(cnd)
      }

      cli_abort(
        c(
          "Can't create column {.field {column_definition[['name']]}}.",
          "i" = "The Graph API doesn't support creating {.val {type}}
          columns on a list."
        ),
        parent = cnd,
        call = call
      )
    }
  )

  if (!is.null(validation)) {
    update_sp_list_column_validation(
      sp_list,
      column_name = resp[["name"]] %||% column_definition[["name"]],
      validation = validation,
      call = call
    )
  }

  resp
}

# <https://learn.microsoft.com/en-us/graph/api/columndefinition-update?view=graph-rest-1.0&tabs=http>
#' @rdname create_sp_list_column
#' @param column_name,column_id Column ID for column to delete.
#' @param column_name_type "name" or "displayName". Used to match column ID so
#' column_name must be unique if `column_name_type = "displayName"`.
#' @export
update_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_definition = NULL,
  column_name_type = "name",
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      site_url = site_url,
      site = site,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  if (is.null(column_name) && !is.null(column_definition[[column_name_type]])) {
    column_name <- column_definition[[column_name_type]]
  }

  if (!is.null(column_name) && is.null(column_id)) {
    existing_column <- sp_list_column_by_name(
      column_name,
      sp_list = sp_list,
      column_name_type = column_name_type,
      call = call
    )
    column_id <- existing_column[["id"]]
  } else if (is_string(column_id)) {
    existing_column <- get_sp_list_column(
      sp_list = sp_list,
      column_id = column_id
    )
  } else {
    cli::cli_abort(
      "{.arg column_id} or {.arg column_name} must be provided.",
      call = call
    )
  }

  column_definition <- column_definition %||%
    create_column_definition(
      name = column_name,
      ...
    )

  # Send only properties that differ from the existing column
  column_definition <- diff_column_definition(
    column_definition,
    existing_column
  )

  if (length(column_definition) == 0) {
    cli_inform(
      c("i" = "Column {.field {existing_column[['name']]}} is unchanged.")
    )
    return(invisible(sp_list))
  }

  # The Graph API doesn't support validation so apply it with the SharePoint
  # REST API
  if (!is.null(column_definition[["validation"]])) {
    update_sp_list_column_validation(
      sp_list,
      column_name = existing_column[["name"]],
      validation = column_definition[["validation"]],
      call = call
    )
    column_definition[["validation"]] <- NULL
  }

  if (length(column_definition) > 0) {
    sp_list$do_operation(
      op = paste0(
        "columns/",
        column_id
      ),
      body = column_definition,
      encode = "json",
      http_verb = "PATCH"
    )
  }

  invisible(sp_list)
}

# <https://learn.microsoft.com/en-us/graph/api/columndefinition-delete?view=graph-rest-1.0&tabs=http>
#' @rdname create_sp_list_column
#' @export
delete_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_name_type = "name",
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      site_url = site_url,
      site = site,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  if (!is.null(column_name) && is.null(column_id)) {
    column_id <- sp_list_column_as_id(
      column_name = column_name,
      sp_list = sp_list,
      column_name_type = column_name_type,
      call = call
    )
  } else if (!is_string(column_id)) {
    cli::cli_abort(
      "{.arg column_id} or {.arg column_name} must be provided.",
      call = call
    )
  }

  sp_list$do_operation(
    paste0(
      "columns/",
      column_id
    ),
    encode = "json",
    http_verb = "DELETE"
  )
}

#' @returns A string with the column ID matched to `column_name`, or `NA` if
#'   no column matches.
#' @noRd
sp_list_column_as_id <- function(
  column_name,
  sp_list = NULL,
  column_name_type = "name",
  call = caller_env()
) {
  sp_list_column_by_name(
    column_name,
    sp_list = sp_list,
    column_name_type = column_name_type,
    call = call
  )[["id"]]
}

#' Get a column definition from the list metadata by column name
#'
#' Used in place of a separate request for the column (by id) when only the
#' column name is known.
#' @returns The columnDefinition (as a list) matched to `column_name`.
#' @noRd
sp_list_column_by_name <- function(
  column_name,
  sp_list = NULL,
  column_name_type = "name",
  call = caller_env()
) {
  column_name_type <- arg_match0(
    column_name_type,
    c("name", "displayName"),
    error_call = call
  )

  col_metadata <- get_sp_list_metadata(
    sp_list = sp_list,
    as_data_frame = FALSE,
    call = call
  )

  values <- as.character(pluck_sp_list_meta(col_metadata, column_name_type))
  column_name <- arg_match(column_name, values, error_call = call)

  col_metadata[[match(column_name, values)]]
}

#' Create SharePoint list lookup column and update lookup column items
#'
#' `r lifecycle::badge("experimental")`
#'
#' [create_sp_list_lookup_column()] is a wrapper for [create_lookup_column()]
#' and [create_sp_list_column()] that creates a lookup column in a list
#' (`sp_list`) using a column from a second list in the same site (the "lookup"
#' list). [create_sp_list_person_column()] is a wrapper for
#' [create_person_column()] and [create_sp_list_column()] that creates a person
#' or group column.
#'
#' @param sp_list A `ms_list` object. If supplied, `list_name`, `site`, and
#' `site_url` are all ignored.
#' @param column_name Name of the lookup (or person or group) column. For
#'   [create_sp_list_lookup_column()], the name of the new column. For
#'   [update_sp_list_lookup_items()] and [update_sp_list_person_items()],
#'   lookup ID values are written to the `"{column_name}LookupId"` field. For
#'   [fmt_sp_list_lookup_items()], one or more column (or record element) names
#'   in `data` to format.
#' @param lookup_list The lookup list as a `ms_list` object, list name, or list
#'   URL. The lookup list must be in the same site as `sp_list` and a list name
#'   is retrieved from the same site as `sp_list`. For
#'   [update_sp_list_lookup_items()] and [fmt_sp_list_lookup_items()],
#'   `lookup_list` is only used to retrieve `lookup_list_data` if not supplied.
#'   For [fmt_sp_list_lookup_items()], a list name requires site information
#'   (e.g. `site_url`) passed with `...`.
#' @param ... For [create_sp_list_lookup_column()] and
#'   [create_sp_list_person_column()], additional parameters are passed to
#'   [create_lookup_column()] or [create_person_column()]. For
#'   [update_sp_list_lookup_items()] and [update_sp_list_person_items()],
#'   additional parameters are passed to [get_sp_list()] (if `sp_list = NULL`),
#'   [get_sp_list_items()] (if `data = NULL`), and [update_sp_list_items()].
#'   For [fmt_sp_list_lookup_items()], additional parameters are passed to
#'   [get_sp_list()] if `lookup_list` is a list name.
#' @inheritParams create_sp_list_column
#' @inheritParams create_lookup_column
#' @inheritParams update_sp_list_items
#' @inheritParams update_sp_list_item
#' @inheritParams purrr::map
#' @inheritDotParams create_lookup_column -name -lookup_list_id
#' @keywords lists
#' @export
create_sp_list_lookup_column <- function(
  sp_list = NULL,
  column_name,
  lookup_list,
  lookup_list_column = column_name,
  ...,
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  call = caller_env()
) {
  check_string(column_name, call = call)

  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      site = site,
      site_url = site_url,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  lookup_list <- get_sp_lookup_list(
    lookup_list,
    sp_list = sp_list,
    call = call
  )

  lookup_column_definition <- create_lookup_column(
    name = column_name,
    lookup_list_column = lookup_list_column,
    lookup_list = lookup_list,
    ...
  )

  create_sp_list_column(
    sp_list = sp_list,
    column_definition = lookup_column_definition,
    call = call
  )
}

#' @rdname create_sp_list_lookup_column
#' @inheritParams create_person_column
#' @keywords lists
#' @export
create_sp_list_person_column <- function(
  sp_list = NULL,
  column_name,
  ...,
  allow_multiple_selection = NULL,
  display_as = NULL,
  from_type = "peopleOnly",
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  allow_multiple = deprecated(),
  call = caller_env()
) {
  check_string(column_name, call = call)

  if (lifecycle::is_present(allow_multiple)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_sp_list_person_column(allow_multiple)",
      "create_sp_list_person_column(allow_multiple_selection)"
    )
    allow_multiple_selection <- allow_multiple_selection %||% allow_multiple
  }

  create_sp_list_column(
    sp_list = sp_list,
    column_definition = create_person_column(
      name = column_name,
      ...,
      allow_multiple_selection = allow_multiple_selection,
      display_as = display_as,
      from_type = from_type
    ),
    list_name = list_name,
    site = site,
    site_url = site_url,
    call = call
  )
}

#' Get a lookup list from a `ms_list` object, list name, or list URL
#'
#' If `lookup_list` is a list name (not a URL) and `sp_list` is supplied, the
#' lookup list is retrieved from the same site as `sp_list`. Otherwise, a list
#' name requires site information passed with `...`.
#' @param sp_list Optional. A `ms_list` object for the list with the lookup
#'   column. If supplied, `lookup_list` must be in the same site as `sp_list`.
#' @returns A `ms_list` object. Errors if the lookup list can't be found or is
#'   not in the same site as `sp_list`.
#' @noRd
get_sp_lookup_list <- function(
  lookup_list,
  sp_list = NULL,
  ...,
  arg = caller_arg(lookup_list),
  call = caller_env()
) {
  if (!is_ms_obj(lookup_list, "ms_list")) {
    check_string(lookup_list, allow_empty = FALSE, arg = arg, call = call)

    if (!is.null(sp_list) && !is_url(lookup_list)) {
      lookup_list <- get_sp_list(
        list_name = lookup_list,
        site = sp_list_site(sp_list),
        as_data_frame = FALSE,
        call = call
      )
    } else {
      lookup_list <- get_sp_list(
        list_name = lookup_list,
        ...,
        as_data_frame = FALSE,
        call = call
      )
    }
  }

  check_ms_obj(lookup_list, "ms_list", arg = arg, call = call)

  # Lookup columns can only use a list from the same site
  if (
    !is.null(sp_list) &&
      !identical(sp_list_site_id(lookup_list), sp_list_site_id(sp_list))
  ) {
    cli_abort(
      "{.arg {arg}} must be a list in the same site as {.arg sp_list}.",
      call = call
    )
  }

  lookup_list
}

#' @returns The site ID string for a `ms_list` object.
#' @noRd
sp_list_site_id <- function(sp_list) {
  sp_list[["properties"]][["parentReference"]][["siteId"]]
}

#' Get the site for a `ms_list` object without a request
#'
#' A `ms_site` only needs the site ID to get lists (or other site resources),
#' so this avoids getting the site again with [get_sp_site()]. The returned
#' site only has an `id` property.
#' @returns A `ms_site` object for the site of `sp_list`.
#' @noRd
sp_list_site <- function(sp_list) {
  Microsoft365R::ms_site$new(
    sp_list[["token"]],
    sp_list[["tenant"]],
    properties = list(id = sp_list_site_id(sp_list))
  )
}

#' [update_sp_list_lookup_items()] provides an easy way to update item lookup
#' column values. The function requires a join column in the target SharePoint
#' list (`sp_list`) with values that match a column in the list specified in
#' the lookup column (`lookup_list`). The function matches the data from the
#' target list to the data from the lookup list (either user provided or
#' retrieved based on the provided lists), renames the column to match the
#' required pattern of `"{column_name}LookupId"`, and calls
#' [update_sp_list_items()] with `check_fields = FALSE`. As of May 2026, the
#' function does not support multiple values for lookup columns.
#'
#' [update_sp_list_person_items()] is a variant of
#' [update_sp_list_lookup_items()] for person or group columns. Person or group
#' columns are a type of lookup column where the lookup list is the hidden
#' "User Information List" for the site. By default, users are matched by email
#' address (ignoring case). Users that have never accessed the site are not
#' included in the "User Information List" and can't be matched.
#'
#' [fmt_sp_list_lookup_items()] formats one or more lookup (or person or group)
#' columns in `data` by replacing the values with matching lookup list item ID
#' values and renaming the columns to `"{column_name}LookupId"`. Use the output
#' with [create_sp_list_items()] or [update_sp_list_items()].
#'
#' Values in `data` that can't be matched to a lookup list item are listed in a
#' message and replaced with `NA` values. Missing values are never matched.
#'
#' @param data Optional. A data frame, a list of named lists (one record per
#'   item), or a single named list record with item ID values (`.id`) and join
#'   values (`join_column`) for the items to update. A single record or a named
#'   list of records is returned by [fmt_sp_list_lookup_items()] as an unnamed
#'   list of records. If `NULL`, items are retrieved
#'   from `sp_list`. Required for [fmt_sp_list_lookup_items()] where `data`
#'   must include all `column_name` values as column (or record element) names.
#' @param lookup_list_data Optional. A data frame or a list of named lists
#'   with item ID values (`.id`) and unique join values
#'   (`lookup_join_column`) for the lookup list items. If `NULL`, items are
#'   retrieved from `lookup_list`.
#' @param join_column Name of column (or record element) in `data` to match
#'   items to lookup list items. Defaults to `column_name`. Items without a
#'   matching lookup list item are not updated when `na_fields = "drop"`.
#' @param lookup_join_column Name of column (or record element) in
#'   `lookup_list_data` with values to match to `join_column` values. Defaults
#'   to `join_column`. For [fmt_sp_list_lookup_items()], `lookup_join_column`
#'   must be length 1 or the same length as `column_name` and defaults to
#'   `column_name`.
#' @param .id Name of column (or record element) with item ID values in `data`
#'   and `lookup_list_data`. Defaults to "id".
#' @param ignore_case If `TRUE`, ignore case when matching join values.
#'   Defaults to `FALSE`.
#' @rdname create_sp_list_lookup_column
#' @keywords lists
#' @export
update_sp_list_lookup_items <- function(
  data = NULL,
  sp_list = NULL,
  column_name,
  lookup_list_data = NULL,
  lookup_list = NULL,
  join_column = column_name,
  lookup_join_column = join_column,
  ...,
  .id = "id",
  ignore_case = FALSE,
  na_fields = c("drop", "replace"),
  .progress = TRUE,
  call = caller_env()
) {
  check_string(column_name, call = call)
  check_string(join_column, call = call)
  check_string(lookup_join_column, call = call)
  check_bool(ignore_case, call = call)

  sp_list <- sp_list %||%
    get_sp_list(
      ...,
      as_data_frame = FALSE,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  data <- data %||%
    get_sp_list_items(
      sp_list = sp_list,
      ...,
      select = c(.id, join_column),
      call = call
    )

  if (is.null(lookup_list_data)) {
    lookup_list_data <- .ms365_list_items(
      sp_list = get_sp_lookup_list(
        lookup_list,
        sp_list = sp_list,
        call = call
      ),
      select = c(.id, lookup_join_column),
      ptype = "select",
      call = call
    )
  }

  data_keys <- pull_lookup_keys(
    data,
    .id = .id,
    join_column = join_column,
    call = call
  )

  lookup_keys <- pull_lookup_keys(
    lookup_list_data,
    .id = .id,
    join_column = lookup_join_column,
    call = call
  )

  items <- vctrs::new_data_frame(
    set_names(
      list(
        data_keys[["ids"]],
        match_lookup_ids(
          data_keys[["keys"]],
          lookup_keys = lookup_keys,
          join_column = join_column,
          lookup_join_column = lookup_join_column,
          ignore_case = ignore_case,
          call = call
        )
      ),
      c(.id, paste0(column_name, "LookupId"))
    )
  )

  # TODO: Add support for multiple values w/ odata.type component of API call
  # This could be implemented here or in update_sp_list_items
  # See https://stackoverflow.com/a/56356460

  update_sp_list_items(
    data = items,
    sp_list = sp_list,
    ...,
    .id = .id,
    allow_display_nm = FALSE,
    check_fields = FALSE,
    na_fields = na_fields,
    .progress = .progress,
    call = call
  )
}

#' @rdname create_sp_list_lookup_column
#' @keywords lists
#' @export
fmt_sp_list_lookup_items <- function(
  data,
  column_name,
  lookup_list_data = NULL,
  lookup_list = NULL,
  lookup_join_column = column_name,
  ...,
  .id = "id",
  ignore_case = FALSE,
  call = caller_env()
) {
  check_character(column_name, call = call)
  check_character(lookup_join_column, call = call)
  check_bool(ignore_case, call = call)

  lookup_join_column <- vctrs::vec_recycle(
    lookup_join_column,
    size = length(column_name),
    x_arg = "lookup_join_column",
    call = call
  )

  if (!is.data.frame(data)) {
    data <- as_sp_item_records(data, .id = .id, call = call)
  }

  is_records <- !is.data.frame(data)

  if (is.null(lookup_list_data)) {
    lookup_list_data <- .ms365_list_items(
      sp_list = get_sp_lookup_list(lookup_list, ..., call = call),
      select = unique(c(.id, lookup_join_column)),
      ptype = "select",
      call = call
    )
  }

  for (j in seq_along(column_name)) {
    col <- column_name[[j]]
    lookup_col <- paste0(col, "LookupId")

    lookup_keys <- pull_lookup_keys(
      lookup_list_data,
      .id = .id,
      join_column = lookup_join_column[[j]],
      call = call
    )

    if (is_records) {
      # Records without a value for the column are left as is
      has_col <- purrr::map_lgl(data, \(x) has_name(x, col))

      if (!any(has_col)) {
        cli_abort(
          "At least one record in {.arg data} must have a {.val {col}} element.",
          call = call
        )
      }

      lookup_ids <- match_lookup_ids(
        pull_record_values(data[has_col], col, arg = "data", call = call),
        lookup_keys = lookup_keys,
        join_column = col,
        lookup_join_column = lookup_join_column[[j]],
        ignore_case = ignore_case,
        call = call
      )

      data[has_col] <- purrr::map2(
        data[has_col],
        vctrs::vec_chop(lookup_ids),
        \(x, id) {
          x[[col]] <- id
          names(x)[names(x) == col] <- lookup_col
          x
        }
      )
    } else {
      if (!has_name(data, col)) {
        cli_abort(
          "{.arg data} must have a column named {.val {col}}.",
          call = call
        )
      }

      data[[col]] <- match_lookup_ids(
        data[[col]],
        lookup_keys = lookup_keys,
        join_column = col,
        lookup_join_column = lookup_join_column[[j]],
        ignore_case = ignore_case,
        call = call
      )

      names(data)[names(data) == col] <- lookup_col
    }
  }

  data
}

#' Match join values to lookup list item ID values
#'
#' Missing join values are never matched. Errors if any join value matches a
#' duplicated lookup join value. Values that can't be matched are listed in a message.
#' @param values Join values to match.
#' @param lookup_keys A list with `ids` and `keys` from `pull_lookup_keys()`.
#' @returns A vector of lookup list item ID values the same size as `values`
#'   with `NA` values for any unmatched values.
#' @noRd
match_lookup_ids <- function(
  values,
  lookup_keys,
  join_column = NULL,
  lookup_join_column = join_column,
  ignore_case = FALSE,
  call = caller_env()
) {
  lookup_values <- lookup_keys[["keys"]]
  match_values <- values

  if (ignore_case) {
    match_values <- tolower(match_values)
    lookup_values <- tolower(lookup_values)
  }

  # Each join value must match a single lookup list item. Duplicated lookup
  # values (e.g. a group account listed twice in the "User Information List")
  # are only an error if they match a join value. Missing values are ignored.
  is_dup <- vctrs::vec_duplicate_detect(lookup_values) &
    !vctrs::vec_detect_missing(lookup_values)

  if (any(is_dup)) {
    dup_values <- vctrs::vec_unique(vctrs::vec_slice(lookup_values, is_dup))
    dup_values <- vctrs::vec_slice(
      dup_values,
      vctrs::vec_in(dup_values, match_values)
    )

    if (has_length(dup_values)) {
      cli_abort(
        "Lookup list data must have unique {.field {lookup_join_column}}
        values to match. Duplicated value{?s}: {.val {dup_values}}",
        call = call
      )
    }
  }

  lookup_i <- vctrs::vec_match(
    match_values,
    lookup_values,
    na_equal = FALSE
  )

  unmatched <- vctrs::vec_unique(
    vctrs::vec_slice(
      values,
      is.na(lookup_i) & !vctrs::vec_detect_missing(values)
    )
  )

  if (has_length(unmatched)) {
    n_unmatched <- length(unmatched)

    cli::cli_bullets(
      c(
        "!" = "{n_unmatched} {.field {join_column}} {cli::qty(n_unmatched)}
        value{?s} can't be matched to a lookup list item: {.val {unmatched}}"
      )
    )
  }

  vctrs::vec_slice(lookup_keys[["ids"]], lookup_i)
}

#' Get item ID and join values from a data frame or list of records
#'
#' Used by [update_sp_list_lookup_items()] and [fmt_sp_list_lookup_items()] to
#' match items to lookup list items. A record without a join value has a
#' missing join value.
#' @returns A list with `ids` (item ID values) and `keys` (join values) vectors
#'   with one value per item in `data`.
#' @noRd
pull_lookup_keys <- function(
  data,
  .id = "id",
  join_column = NULL,
  arg = caller_arg(data),
  call = caller_env()
) {
  if (is.data.frame(data)) {
    missing_cols <- setdiff(c(.id, join_column), names(data))

    if (has_length(missing_cols)) {
      cli_abort(
        "{.arg {arg}} must have {cli::qty(missing_cols)}column{?s}
        {.val {missing_cols}}.",
        call = call
      )
    }

    return(list(
      ids = as_sp_item_ids(data, .id = .id, arg = arg, call = call),
      keys = data[[join_column]]
    ))
  }

  records <- as_sp_item_records(data, .id = .id, arg = arg, call = call)

  list(
    ids = as_sp_item_ids(records, .id = .id, arg = arg, call = call),
    keys = pull_record_values(records, join_column, arg = arg, call = call)
  )
}

#' Get a single value for each record in a list of records
#' @returns A vector with one value per record in `records` with `NA` values
#'   for records without an element named `name`. Errors if any record has a
#'   value that is not length 1.
#' @noRd
pull_record_values <- function(
  records,
  name,
  arg = caller_arg(records),
  call = caller_env()
) {
  values <- purrr::map(records, \(x) x[[name]] %||% NA)

  is_invalid <- !purrr::map_lgl(values, \(x) has_length(x, 1))

  if (any(is_invalid)) {
    invalid_i <- which(is_invalid)

    cli_abort(
      "Each record in {.arg {arg}} must have a single {.val {name}}
      value. {cli::qty(length(invalid_i))}Record{?s} with an invalid value:
      {invalid_i}.",
      call = call
    )
  }

  vctrs::list_unchop(values)
}

#' Pull a named index of list columns matching a column type
#'
#' Find the columns described by list metadata from [get_sp_list_metadata()]
#' that match a single type or property, e.g. all lookup columns or all
#' required columns. Pass the result to [vctrs::vec_slice()] to subset
#' `sp_list_meta`.
#'
#' @param sp_list_meta List column metadata returned by
#'   [get_sp_list_metadata()]: either a data frame (`as_data_frame = TRUE`) or
#'   a list with one element per column (`as_data_frame = FALSE`).
#' @param col_type Column type or property to match:
#'   - "hidden", "indexed", "readOnly", or "required" match columns where the
#'     logical property of the same name is `TRUE` (`NA` is treated as
#'     `FALSE`).
#'   - A column type from `sp_list_col_types`, e.g. "text", "number", or
#'     "lookup", matches columns with the column type property (facet) of the
#'     same name. For data frame input, a column matches if the
#'     nested facet data frame has any non-missing value for that column.
#'     "boolean", "contentApprovalStatus", "geolocation", and "thumbnail"
#'     columns can only be identified from list input because these facets are
#'     empty objects (`{}`) that are dropped when the API response is
#'     simplified to a data frame.
#'   - "all" matches every column.
#'   - "editable" matches columns where `readOnly` is not `TRUE`.
#'   - "external" matches columns with a name not in
#'     `sp_list_internal_colnames`.
#' @param names_from Property to use for names of the returned vector. One of
#'   "name" (default) or "displayName".
#' @returns A named integer vector of positions in `sp_list_meta` for the
#'   matching columns, named with the corresponding values of `names_from`.
#'   Returns a zero-length named integer vector if no columns match or if
#'   `sp_list_meta` lacks the metadata needed to identify `col_type`.
#' @keywords internal
#' @export
pull_sp_list_cols <- function(
  sp_list_meta,
  col_type = c(
    "required",
    "hidden",
    "indexed",
    "readOnly",
    "boolean",
    "calculated",
    "choice",
    "contentApprovalStatus",
    "currency",
    "dateTime",
    "geolocation",
    "hyperlinkOrPicture",
    "lookup",
    "number",
    "personOrGroup",
    "term",
    "text",
    "thumbnail",
    "all",
    "editable",
    "external"
  ),
  names_from = c("name", "displayName"),
  call = caller_env()
) {
  if (!is.data.frame(sp_list_meta) && !is_bare_list(sp_list_meta)) {
    stop_input_type(
      sp_list_meta,
      "a data frame or list",
      arg = "sp_list_meta",
      call = call
    )
  }

  col_type <- arg_match(col_type, error_call = call)
  names_from <- arg_match(names_from, error_call = call)

  if (col_type %in% sp_list_col_types) {
    col_match <- has_sp_list_col_facet(sp_list_meta, col_type, call = call)
  } else {
    col_match <- switch(
      col_type,
      all = rep_len(TRUE, vctrs::vec_size(sp_list_meta)),
      editable = !(pluck_sp_list_meta(sp_list_meta, "readOnly") %in% TRUE),
      external = !(pluck_sp_list_meta(sp_list_meta, "name") %in%
        sp_list_internal_colnames),
      pluck_sp_list_meta(sp_list_meta, col_type) %in% TRUE
    )
  }

  col_i <- which(col_match)

  set_names(
    col_i,
    as.character(pluck_sp_list_meta(sp_list_meta, names_from)[col_i])
  )
}

#' Column type properties (facets) supported by `pull_sp_list_cols()`
#'
#' The columnDefinition type properties are mutually exclusive so each column
#' has at most one. See:
#' <https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>
#' @noRd
sp_list_col_types <- c(
  "boolean",
  "calculated",
  "choice",
  "contentApprovalStatus",
  "currency",
  "dateTime",
  "geolocation",
  "hyperlinkOrPicture",
  "lookup",
  "number",
  "personOrGroup",
  "term",
  "text",
  "thumbnail"
)

#' Does each column in list metadata have a column type property (facet)?
#'
#' @param sp_list_meta A data frame or list of list column metadata.
#' @param facet A column type property name, e.g. "lookup" or "number".
#' @returns A logical vector with one value per column.
#' @noRd
has_sp_list_col_facet <- function(sp_list_meta, facet, call = caller_env()) {
  if (!is.data.frame(sp_list_meta)) {
    # Present facets may be empty lists, e.g. `boolean = list()`
    return(purrr::map_lgl(sp_list_meta, \(x) !is.null(x[[facet]])))
  }

  facet_values <- sp_list_meta[[facet]]

  if (is.null(facet_values)) {
    return(rep_len(FALSE, nrow(sp_list_meta)))
  }

  if (is.data.frame(facet_values) && ncol(facet_values) == 0) {
    cli::cli_abort(
      c(
        "Can't identify {.val {facet}} columns from a data frame of list \\
        metadata.",
        "i" = "The {.field {facet}} property has no values so it is dropped \\
        when the API response is simplified to a data frame.",
        "i" = "Use {.code as_data_frame = FALSE} with \\
        {.fn get_sp_list_metadata} instead."
      ),
      call = call
    )
  }

  has_facet_values(facet_values)
}

#' Does each row of a nested facet data frame (or element of a list column)
#' have any non-missing value?
#' @noRd
has_facet_values <- function(x) {
  if (is.data.frame(x)) {
    return(
      purrr::reduce(
        purrr::map(x, has_facet_values),
        `|`,
        .init = rep_len(FALSE, nrow(x))
      )
    )
  }

  !purrr::map_lgl(x, \(value) is.null(value) || all(is.na(value)))
}

#' Pull a property from each column in list metadata
#'
#' @param sp_list_meta A data frame or list of list column metadata.
#' @param ... Property names passed to [purrr::pluck()], e.g. `"lookup",
#'   "columnName"` for a nested property.
#' @returns A vector with one value per column. List inputs use `NA` for
#'   columns missing the property. Data frame inputs return `NULL` if the
#'   property is missing.
#' @noRd
pluck_sp_list_meta <- function(sp_list_meta, ...) {
  if (is.data.frame(sp_list_meta)) {
    return(purrr::pluck(sp_list_meta, ...))
  }

  purrr::map_vec(
    sp_list_meta,
    \(x) purrr::pluck(x, ..., .default = NA)
  )
}

#' Internal SharePoint list column names
#'
#' Length 27 of internal field or column names for SharePoint lists.
#' Note: Not all internal columns are read-only, _ColorTag
#' ComplianceAssetId, ContentType, and Attachments are all editable.
#'
#' @noRd
sp_list_internal_colnames <- c(
  "_ColorTag",
  "ComplianceAssetId",
  "Modified",
  "ID",
  "ContentType",
  "Created",
  "Author",
  "AuthorLookupId",
  "Editor",
  "EditorLookupId",
  "_UIVersionString",
  "Attachments",
  "Edit",
  "LinkTitleNoMenu",
  "LinkTitle",
  "DocIcon",
  "ItemChildCount",
  "FolderChildCount",
  "_ComplianceFlags",
  "_ComplianceTag",
  "_ComplianceTagWrittenTime",
  "_ComplianceTagUserId",
  "_IsRecord",
  "AppAuthor",
  "AppAuthorLookupId",
  "AppEditor",
  "AppEditorLookupId"
)

#' Internal fields modeled as lookup columns in list metadata that the Graph
#' API returns under their own name (without a "LookupId" suffix).
#'
#' @noRd
sp_list_lookup_exempt_colnames <- c(
  "ItemChildCount",
  "FolderChildCount",
  "_ComplianceFlags",
  "_ComplianceTag",
  "_ComplianceTagWrittenTime",
  "_ComplianceTagUserId"
)


#' System fields for SharePoint Online
#' <https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/connections/connection-sharepoint-online#notes>
#' @noRd
sp_list_sys_colnames <- c(
  "\\u200b\\u200b\\u200b\\u200b\\u200b\\u200bIdentifier",
  "IsFolder",
  "Thumbnail",
  "Link\\u200b",
  "Name",
  "FilenameWithExtension",
  "Path",
  "FullPath",
  "ModerationStatus",
  "ModerationComment",
  "ContentType",
  "IsCheckedOut",
  "VersionNumber",
  "TriggerWindowStartToken",
  "TriggerWindowEndToken"
)
