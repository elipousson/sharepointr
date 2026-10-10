# SharePoint list views
#
# The Graph API doesn't support list views so these functions use the
# SharePoint REST API. View properties use the SP.View property names.
# <https://learn.microsoft.com/en-us/previous-versions/office/sharepoint-csom/jj244979(v=office.15)>

#' SP.View properties that can be set
#' @noRd
sp_view_props <- list(
  Title = "string",
  ViewFields = "character",
  ViewQuery = "string",
  RowLimit = "whole",
  Paged = "bool",
  DefaultView = "bool",
  Hidden = "bool",
  Scope = "scope",
  CustomFormatter = "json",
  MobileView = "bool",
  MobileDefaultView = "bool"
)

#' SP.View properties that are returned as a reference to an existing view
#' @noRd
sp_view_read_only_props <- c(
  "Id",
  "ServerRelativeUrl",
  "ViewType",
  "PersonalView"
)

#' SP.View Scope values (SP.ViewScope)
#' 0 = Default, 1 = Recursive, 2 = RecursiveAll, 3 = FilesOnly
#' @noRd
sp_view_scopes <- 0:3

#' SP.View properties set by the view function arguments
#' @noRd
sp_view_arg_props <- c(
  title = "Title",
  view_fields = "ViewFields",
  view_query = "ViewQuery",
  row_limit = "RowLimit",
  paged = "Paged",
  default_view = "DefaultView",
  hidden = "Hidden",
  scope = "Scope",
  custom_formatter = "CustomFormatter"
)

#' Names used in place of SP.View property names
#' @noRd
sp_view_prop_hints <- c(
  sp_view_arg_props,
  fields = "ViewFields",
  query = "ViewQuery",
  Query = "ViewQuery",
  SetAsDefaultView = "DefaultView",
  id = "Id"
)

#' Get a view definition from view function arguments
#'
#' Uses `view_definition` if supplied. Otherwise, collects the view arguments
#' (named as in `sp_view_arg_props`) from `env` and names them with SP.View
#' property names.
#' @noRd
view_args_as_definition <- function(
  view_definition = NULL,
  env = caller_env(),
  call = caller_env()
) {
  args <- purrr::compact(
    env_get_list(env, names(sp_view_arg_props), default = NULL)
  )

  if (is.null(view_definition)) {
    return(set_names(args, sp_view_arg_props[names(args)]))
  }

  if (length(args) > 0) {
    cli_abort(
      c(
        "Supply {.arg view_definition} or view arguments, not both.",
        "x" = "Also supplied: {.arg {names(args)}}."
      ),
      call = call
    )
  }

  view_definition
}

#' Validate a list view definition
#'
#' @param x A named list of SP.View properties.
#' @param require_title If `TRUE`, require a `Title`.
#' @param formatter_as_list If `TRUE`, keep a `CustomFormatter` supplied as a
#'   list (e.g. a YAML mapping) as a list. Otherwise, convert it to a JSON
#'   string (the format used by the SharePoint REST API).
#' @returns `x` with `ViewFields` as a character vector and `CustomFormatter`
#'   as a JSON string (or a list if `formatter_as_list = TRUE`).
#' @noRd
validate_view_definition <- function(
  x,
  require_title = TRUE,
  formatter_as_list = FALSE,
  label = NULL,
  call = caller_env()
) {
  if (!is.list(x) || (length(x) > 0 && !is_named(x))) {
    cli_abort(
      "{label %||% 'A view definition'} must be a named list.",
      call = call
    )
  }

  label <- label %||% x[["Title"]] %||% "view"
  allowed <- c(names(sp_view_props), sp_view_read_only_props)
  unknown <- setdiff(names(x), allowed)

  if (length(unknown) > 0) {
    abort_unknown_props(
      unknown,
      label = label,
      allowed = names(sp_view_props),
      kind = "view",
      hints = sp_view_prop_hints,
      call = call
    )
  }

  if (require_title) {
    check_string(x[["Title"]], arg = paste0(label, ".Title"), call = call)
  }

  for (prop in intersect(names(x), names(sp_view_props))) {
    arg <- paste0(label, ".", prop)
    rule <- sp_view_props[[prop]]
    value <- x[[prop]]

    x[[prop]] <- switch(
      rule,
      scope = {
        check_number_whole(value, min = 0, max = 3, arg = arg, call = call)
        as.integer(value)
      },
      json = if (formatter_as_list && is.list(value)) {
        if (!is_named2(value)) {
          cli_abort("{.arg {arg}} must be a named list or a JSON string.", call = call)
        }
        value
      } else {
        as_view_json(value, arg = arg, call = call)
      },
      # SharePoint returns whole numbers as integers
      whole = as.integer(check_sp_prop(value, rule = rule, arg = arg, call = call)),
      check_sp_prop(value, rule = rule, arg = arg, call = call)
    )
  }

  for (prop in intersect(names(x), sp_view_read_only_props)) {
    if (prop == "PersonalView") {
      check_bool(x[[prop]], arg = paste0(label, ".", prop), call = call)
    } else {
      check_string(x[[prop]], arg = paste0(label, ".", prop), call = call)
    }
  }

  x
}

#' Drop read-only properties from a view definition
#'
#' Read-only properties (e.g. `Id`) are references to an existing view.
#' @noRd
drop_view_read_only <- function(view) {
  view[setdiff(names(view), sp_view_read_only_props)]
}

#' Prepare a view from a list definition to create
#'
#' Drops read-only properties and `DefaultView`, since the default view is set
#' after all views are created.
#' @noRd
as_view_to_create <- function(view) {
  view <- drop_view_read_only(view)
  view[["DefaultView"]] <- NULL
  view
}

#' Convert a custom formatter to a JSON string
#'
#' @param x A JSON string or a list (converted with [jsonlite::toJSON()]).
#' @noRd
as_view_json <- function(x, arg = caller_arg(x), call = caller_env()) {
  if (is.list(x)) {
    return(as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null")))
  }

  check_string(x, arg = arg, call = call)

  if (nzchar(x) && !jsonlite::validate(x)) {
    cli_abort("{.arg {arg}} must be valid JSON.", call = call)
  }

  x
}

#' Clean a view returned by the SharePoint REST API
#'
#' Keeps the SP.View properties used by sharepointr and converts the expanded
#' `ViewFields` to a character vector.
#' @noRd
clean_view <- function(view) {
  fields <- view[["ViewFields"]][["Items"]]
  view <- view[intersect(
    names(view),
    c(sp_view_read_only_props, names(sp_view_props))
  )]
  view[["ViewFields"]] <- as.character(unlist(fields))

  if (identical(view[["CustomFormatter"]], "")) {
    view[["CustomFormatter"]] <- NULL
  }

  purrr::discard(view, is.null)
}

#' Normalize a CAML view query for comparison
#'
#' SharePoint adds a space before the end of empty elements (`<FieldRef
#' Name="X" />`) when a view query is saved.
#' @noRd
normalize_view_query <- function(x) {
  x <- gsub(">\\s+<", "><", trimws(x %||% ""))
  gsub("\\s*/>", "/>", x)
}

#' Are a proposed and current view property value the same?
#' @noRd
same_view_value <- function(proposed, current, prop) {
  if (prop == "ViewQuery") {
    return(identical(normalize_view_query(proposed), normalize_view_query(current)))
  }

  if (prop == "CustomFormatter") {
    parse <- \(x) if (nzchar(x %||% "")) jsonlite::fromJSON(x, simplifyVector = FALSE)
    return(identical(parse(proposed), parse(current)))
  }

  identical(proposed, current)
}

#' Get the REST API path for a view
#' @noRd
sp_view_path <- function(view_title = NULL, view_id = NULL) {
  if (!is.null(view_id)) {
    return(paste0("views(guid'", view_id, "')"))
  }

  if (!is.null(view_title)) {
    return(paste0("views/getbytitle('", sp_rest_string(view_title), "')"))
  }

  "defaultview"
}

#' List, get, create, update, or delete SharePoint list views
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' - [list_sp_list_views()] lists the views for a SharePoint list.
#' - [get_sp_list_view()] gets a single view by title or ID (or the default
#'   view).
#' - [create_sp_list_view()] creates a view.
#' - [update_sp_list_view()] updates a view. Only properties that differ from
#'   the existing view are changed.
#' - [delete_sp_list_view()] deletes a view. The default view can't be deleted.
#'
#' The Graph API doesn't support list views, so these functions use the
#' SharePoint REST API and require a delegated (user) login with a refresh
#' token, such as the default Microsoft365R login. View properties use the
#' SharePoint REST API
#' [SP.View](https://learn.microsoft.com/en-us/previous-versions/office/sharepoint-csom/jj244979(v=office.15))
#' property names (e.g. `ViewFields` or `RowLimit`) and the arguments use the
#' same names in snake case (e.g. `view_fields` or `row_limit`).
#'
#' @details View queries
#'
#' `view_query` is a [CAML](https://learn.microsoft.com/en-us/sharepoint/dev/schema/query-schema)
#' query with optional `<Where>`, `<OrderBy>`, and `<GroupBy>` elements (but
#' without an enclosing `<Query>` element). Reference columns by internal name.
#' For example, to show active items sorted by amount:
#'
#' ```
#' <Where><Eq><FieldRef Name="Status"/><Value Type="Choice">Active</Value></Eq></Where>
#' <OrderBy><FieldRef Name="Amount" Ascending="FALSE"/></OrderBy>
#' ```
#'
#' @details Limitations
#'
#' - Board, gallery, and calendar views can be listed but their layout
#'   settings can't be changed.
#' - Personal views can be listed but not created.
#' - Hidden views include list form settings (e.g. a hidden "Untitled Form"
#'   view holds custom form formatting) and are excluded by default.
#' - Changing view fields removes and re-adds every field. If a request fails
#'   partway through, call [update_sp_list_view()] again.
#' - Renaming a view doesn't change the view URL.
#'
#' @inheritParams get_sp_list
#' @param sp_list A `ms_list` object. If `NULL`, the list is retrieved with
#'   [get_sp_list()] using `list_name` and any additional arguments passed to
#'   `...`.
#' @param ... Additional arguments passed to [get_sp_list()] if `sp_list` is
#'   `NULL`.
#' @param list_name List name or URL. Used to get the list if `sp_list` is
#'   `NULL`.
#' @param hidden For [list_sp_list_views()], if `TRUE`, include hidden views.
#'   For [create_sp_list_view()] and [update_sp_list_view()], if `TRUE`, hide
#'   the view. SP.View property: `Hidden`.
#' @param as_data_frame If `TRUE` (default), return a data frame with one row
#'   per view. If `FALSE`, return a list of views.
#' @inheritParams rlang::args_error_context
#' @returns [list_sp_list_views()] returns a data frame or a list of views.
#'   The data frame always has the same columns (`Id`, `Title`,
#'   `DefaultView`, `Hidden`, `ViewFields`, `ViewQuery`, `RowLimit`, `Paged`,
#'   `Scope`, `CustomFormatter`, `MobileView`, `MobileDefaultView`,
#'   `ServerRelativeUrl`, `ViewType`, and `PersonalView`), even if the list
#'   has no views. `ViewFields` is a list column and missing values are `NA`.
#'   [get_sp_list_view()] returns a named list of SP.View properties (`Id`,
#'   `Title`, `ViewFields`, `ViewQuery`, `RowLimit`, `DefaultView`, and other
#'   properties). [create_sp_list_view()] and [update_sp_list_view()]
#'   invisibly return the created or updated view in the same format.
#'   [delete_sp_list_view()] invisibly returns `NULL`.
#' @keywords lists
#' @examples
#' \dontrun{
#' list_sp_list_views(list_name = "Projects", site_url = "<SharePoint site url>")
#'
#' create_sp_list_view(
#'   sp_list,
#'   title = "Active Projects",
#'   view_fields = c("LinkTitle", "Status", "Amount"),
#'   view_query = '<Where><Eq><FieldRef Name="Status"/>
#'     <Value Type="Choice">Active</Value></Eq></Where>',
#'   row_limit = 50
#' )
#'
#' update_sp_list_view(
#'   sp_list,
#'   view_title = "Active Projects",
#'   default_view = TRUE
#' )
#' }
#' @export
list_sp_list_views <- function(
  sp_list = NULL,
  ...,
  hidden = FALSE,
  as_data_frame = TRUE,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  check_bool(hidden, call = call)
  check_bool(as_data_frame, call = call)

  sp_list <- get_view_sp_list(
    sp_list,
    ...,
    list_name = list_name,
    site_url = site_url,
    site = site,
    call = call
  )

  resp <- sp_list_rest_request(
    sp_list,
    "views?$expand=ViewFields",
    call = call
  )

  views <- purrr::map(resp[["value"]], clean_view)

  if (!hidden) {
    views <- purrr::discard(views, \(view) isTRUE(view[["Hidden"]]))
  }

  if (!as_data_frame) {
    return(views)
  }

  views_as_table(views)
}

#' Prototype for a data frame of views
#'
#' Has a column for each SP.View property kept by `clean_view()`.
#' @noRd
sp_view_table_ptype <- function() {
  vctrs::data_frame(
    Id = character(),
    Title = character(),
    DefaultView = logical(),
    Hidden = logical(),
    ViewFields = list(),
    ViewQuery = character(),
    RowLimit = integer(),
    Paged = logical(),
    Scope = integer(),
    CustomFormatter = character(),
    MobileView = logical(),
    MobileDefaultView = logical(),
    ServerRelativeUrl = character(),
    ViewType = character(),
    PersonalView = logical()
  )
}

#' Convert a list of views to a data frame
#'
#' Returns the same columns and column types for any views (including no
#' views). Missing properties are `NA` and `ViewFields` is a list column.
#' @noRd
views_as_table <- function(views) {
  cols <- purrr::imap(
    sp_view_table_ptype(),
    \(ptype, prop) {
      values <- purrr::map(views, prop)

      if (is.list(ptype)) {
        return(purrr::map(values, \(x) x %||% character()))
      }

      values <- purrr::map(values, \(x) x %||% vctrs::vec_init(ptype))
      purrr::list_c(values, ptype = ptype)
    }
  )

  vctrs::new_data_frame(cols, n = length(views))
}

#' Get a `ms_list` for the view functions
#' @noRd
get_view_sp_list <- function(
  sp_list = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
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
  sp_list
}

#' @rdname list_sp_list_views
#' @param view_title,view_id Title or ID of an existing view. If both are
#'   `NULL`, [get_sp_list_view()] returns the default view.
#' @export
get_sp_list_view <- function(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  check_string(view_title, allow_null = TRUE, call = call)
  check_string(view_id, allow_null = TRUE, call = call)

  if (!is.null(view_title) && !is.null(view_id)) {
    cli_abort(
      "Supply {.arg view_title} or {.arg view_id}, not both.",
      call = call
    )
  }

  sp_list <- get_view_sp_list(
    sp_list,
    ...,
    list_name = list_name,
    site_url = site_url,
    site = site,
    call = call
  )

  view <- sp_list_rest_request(
    sp_list,
    paste0(sp_view_path(view_title, view_id), "?$expand=ViewFields"),
    call = call
  )

  clean_view(view)
}

#' @rdname list_sp_list_views
#' @param title View title. Required for [create_sp_list_view()] unless
#'   supplied with `view_definition`. For [update_sp_list_view()], a new title
#'   for the view. SP.View property: `Title`.
#' @param view_fields Character vector of internal column names to show in
#'   the view, in order. Use `"LinkTitle"` for the title column with a link to
#'   the item. For [create_sp_list_view()], defaults to the fields of the
#'   default view. SP.View property: `ViewFields`.
#' @param view_query A CAML query used to filter, sort, or group items (see
#'   details). SP.View property: `ViewQuery`.
#' @param row_limit Number of items to show per page. SP.View property:
#'   `RowLimit`.
#' @param paged If `TRUE`, show items in pages of `row_limit` items. SP.View
#'   property: `Paged`.
#' @param default_view If `TRUE`, make the view the default view for the
#'   list. The current default view is no longer the default. SP.View
#'   property: `DefaultView`.
#' @param scope For lists with folders, whether to show items in folders.
#'   One of `0` (default), `1` (recursive), `2` (recursive all), or `3` (files
#'   only). SP.View property: `Scope`.
#' @param custom_formatter JSON view formatting as a JSON string or a list.
#'   See [Use view formatting to customize SharePoint](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/view-formatting).
#'   SP.View property: `CustomFormatter`.
#' @param view_definition Optional. A named list of SP.View properties (e.g.
#'   `list(Title = "Active", RowLimit = 50)`). Used in place of the other view
#'   arguments, which can't be supplied with `view_definition`.
#' @export
create_sp_list_view <- function(
  sp_list = NULL,
  title = NULL,
  ...,
  view_fields = NULL,
  view_query = NULL,
  row_limit = NULL,
  paged = NULL,
  default_view = NULL,
  hidden = NULL,
  scope = NULL,
  custom_formatter = NULL,
  view_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  view <- view_args_as_definition(view_definition, call = call)

  view <- validate_view_definition(view, call = call)
  view <- drop_view_read_only(view)

  sp_list <- get_view_sp_list(
    sp_list,
    ...,
    list_name = list_name,
    site_url = site_url,
    site = site,
    call = call
  )

  view_id <- add_sp_list_view(sp_list, view, call = call)

  invisible(get_sp_list_view(sp_list, view_id = view_id, call = call))
}

#' Add a view without getting the new view
#'
#' Used by [create_sp_list_view()] and [sync_sp_list()].
#' @param view A validated view definition without read-only properties.
#' @returns The `Id` of the new view.
#' @noRd
add_sp_list_view <- function(sp_list, view, call = caller_env()) {
  if (is.null(view[["ViewFields"]])) {
    view[["ViewFields"]] <- get_sp_list_view(sp_list, call = call)[["ViewFields"]]
  }

  # SP.ViewCreationInformation properties
  parameters <- purrr::compact(list(
    Title = view[["Title"]],
    ViewFields = as.list(view[["ViewFields"]]),
    Query = view[["ViewQuery"]],
    RowLimit = view[["RowLimit"]],
    Paged = view[["Paged"]],
    SetAsDefaultView = view[["DefaultView"]],
    CustomFormatter = view[["CustomFormatter"]],
    PersonalView = FALSE
  ))

  cli_progress_step("Creating view {.val {view[['Title']]}}")

  resp <- sp_list_rest_request(
    sp_list,
    "views/add",
    method = "POST",
    body = list(parameters = parameters),
    call = call
  )

  # Properties that can't be set when a view is created
  other <- view[intersect(names(view), c("Hidden", "Scope", "MobileView", "MobileDefaultView"))]

  if (length(other) > 0) {
    sp_list_rest_request(
      sp_list,
      sp_view_path(view_id = resp[["Id"]]),
      method = "POST",
      body = other,
      merge = TRUE,
      call = call
    )
  }

  resp[["Id"]]
}

#' @rdname list_sp_list_views
#' @export
update_sp_list_view <- function(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  title = NULL,
  view_fields = NULL,
  view_query = NULL,
  row_limit = NULL,
  paged = NULL,
  default_view = NULL,
  hidden = NULL,
  scope = NULL,
  custom_formatter = NULL,
  view_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  proposed <- view_args_as_definition(view_definition, call = call)

  proposed <- validate_view_definition(proposed, require_title = FALSE, call = call)

  sp_list <- get_view_sp_list(
    sp_list,
    ...,
    list_name = list_name,
    site_url = site_url,
    site = site,
    call = call
  )

  current <- get_sp_list_view(
    sp_list,
    view_title = view_title,
    view_id = view_id %||% proposed[["Id"]],
    call = call
  )

  view_id <- current[["Id"]]

  if (isTRUE(current[["DefaultView"]]) && isFALSE(proposed[["DefaultView"]])) {
    cli_abort(
      c(
        "{.val {current[['Title']]}} is the default view.",
        "i" = "Set another view as the default view instead."
      ),
      call = call
    )
  }

  changed <- purrr::keep(
    names(proposed[intersect(names(proposed), names(sp_view_props))]),
    \(prop) !same_view_value(proposed[[prop]], current[[prop]], prop)
  )

  if (length(changed) == 0) {
    cli_inform(c("i" = "View {.val {current[['Title']]}} is unchanged."))
    return(invisible(current))
  }

  cli_progress_step("Updating view {.val {current[['Title']]}}")

  set_sp_list_view_props(sp_list, view_id, proposed[changed], call = call)

  invisible(get_sp_list_view(sp_list, view_id = view_id, call = call))
}

#' Set view properties without getting the view
#'
#' Used by [update_sp_list_view()] and [sync_sp_list()] (which have already
#' compared the view with the proposed properties).
#' @param props A named list of validated SP.View properties to set.
#' @returns Invisibly returns `sp_list`.
#' @noRd
set_sp_list_view_props <- function(
  sp_list,
  view_id,
  props,
  call = caller_env()
) {
  merge_props <- props[setdiff(names(props), "ViewFields")]

  if (length(merge_props) > 0) {
    sp_list_rest_request(
      sp_list,
      sp_view_path(view_id = view_id),
      method = "POST",
      body = merge_props,
      merge = TRUE,
      call = call
    )
  }

  if (has_name(props, "ViewFields")) {
    set_sp_list_view_fields(sp_list, view_id, props[["ViewFields"]], call = call)
  }

  invisible(sp_list)
}

#' Replace the fields shown in a view
#' @noRd
set_sp_list_view_fields <- function(
  sp_list,
  view_id,
  view_fields,
  call = caller_env()
) {
  path <- paste0(sp_view_path(view_id = view_id), "/viewfields")

  sp_list_rest_request(
    sp_list,
    paste0(path, "/removeallviewfields"),
    method = "POST",
    call = call
  )

  for (field in view_fields) {
    sp_list_rest_request(
      sp_list,
      paste0(path, "/addviewfield('", sp_rest_string(field), "')"),
      method = "POST",
      call = call
    )
  }

  invisible(sp_list)
}

#' @rdname list_sp_list_views
#' @param confirm If `TRUE` (default), ask for confirmation before deleting a
#'   view.
#' @export
delete_sp_list_view <- function(
  sp_list = NULL,
  view_title = NULL,
  view_id = NULL,
  ...,
  confirm = TRUE,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  check_bool(confirm, call = call)

  if (is.null(view_title) && is.null(view_id)) {
    cli_abort(
      "{.arg view_title} or {.arg view_id} must be supplied.",
      call = call
    )
  }

  sp_list <- get_view_sp_list(
    sp_list,
    ...,
    list_name = list_name,
    site_url = site_url,
    site = site,
    call = call
  )

  view <- get_sp_list_view(
    sp_list,
    view_title = view_title,
    view_id = view_id,
    call = call
  )

  # SharePoint allows deleting the default view, which leaves a list without
  # a default view
  if (isTRUE(view[["DefaultView"]])) {
    cli_abort(
      c(
        "{.val {view[['Title']]}} is the default view and can't be deleted.",
        "i" = "Set another view as the default view first."
      ),
      call = call
    )
  }

  if (confirm) {
    check_yes(
      cli::format_inline(
        "Do you want to delete the view {.val {view[['Title']]}}?"
      ),
      call = call
    )
  }

  cli_progress_step("Deleting view {.val {view[['Title']]}}")

  remove_sp_list_view(sp_list, view[["Id"]], call = call)

  invisible(NULL)
}

#' Delete a view without getting the view
#'
#' Used by [delete_sp_list_view()] and [sync_sp_list()] (if the view can't be
#' the default view).
#' @noRd
remove_sp_list_view <- function(sp_list, view_id, call = caller_env()) {
  sp_list_rest_request(
    sp_list,
    sp_view_path(view_id = view_id),
    method = "DELETE",
    call = call
  )
}
