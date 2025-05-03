#' Get drive or site for list
#'
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

  if (!is.null(list_name)) {
    # FIXME: This is a work around to handle lists that have been renamed

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

    sp_list_id_pairs <- map(
      sp_lists,
      \(x) {
        list(
          name = x$properties$name,
          id = x$properties$id
        )
      }
    )

    nm_values <- map_chr(
      sp_list_id_pairs,
      \(x) {
        x[["name"]]
      }
    )

    list_name <- arg_match(list_name, values = nm_values, error_call = call)

    list_ids <- map_chr(
      sp_list_id_pairs,
      \(x) {
        x[["id"]]
      }
    )

    list_id <- list_ids[nm_values == list_name]
    list_name <- NULL
  }

  cli::cli_progress_step(
    "Getting list from SharePoint"
  )

  sp_list <- ms_list_obj$get_list(list_name = list_name, list_id = list_id)

  if (metadata) {
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
#' @param keep One of "all" (default), "editable", "visible" (not yet
#'   supported). Argument determines if the returned list metadata includes read
#'   only columns or hidden columns.
#' @param sync_fields If `TRUE`, use the `sync_fields` method to sync the fields
#'   of the local `ms_list` object with the fields of the SharePoint List source
#'   before retrieving list metadata.
#' @export
get_sp_list_metadata <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  keep = c("all", "editable", "visible"),
  sync_fields = FALSE,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  if (is.null(sp_list)) {
    sp_list_meta <- get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      metadata = TRUE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )
  } else {
    check_ms_obj(sp_list, "ms_list", call = call)

    if (sync_fields) {
      sp_list <- sp_list$sync_fields()
    }

    sp_list_meta <- sp_list$get_column_info()
  }

  keep <- arg_match(keep, error_call = call)
  # FIXME: keep = "visible" is not yet supported
  stopifnot(keep != "visible")

  if (keep == "editable") {
    sp_list_meta <- sp_list_meta[!sp_list_meta[["readOnly"]], ]
  }

  sp_list_meta
}


#' @rdname sp_list
#' @name delete_sp_list
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
      metadata = TRUE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  check_ms_obj(sp_list, "ms_list", call = call)

  sp_list$delete(confirm = confirm)
}

#' Create a SharePoint List
#'
#' [create_sp_list()] allows the creation of a SharePoint list for a site. See:
#' <https://learn.microsoft.com/en-us/graph/api/list-create?view=graph-rest-1.0&tabs=http>
#'
#' @param list_name Required. List name used as `displayName` property.
#' @param description Optional description.
#' @param columns Optional. Use [create_column_definition()] to create a single
#' column definition or use [create_column_definition_list()] to create a list
#' of column definitions.
#' @inheritParams create_list_info
#' @inheritParams get_sp_site
#' @keywords internal
#' @export
create_sp_list <- function(
  list_name,
  ...,
  description = NULL,
  columns = NULL,
  template = "genericList",
  content_types = NULL,
  hidden = NULL,
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

  body <- vctrs::list_drop_empty(
    list(
      displayName = list_name,
      description = description,
      columns = columns,
      list = create_list_info(
        hidden = hidden,
        content_types = content_types,
        template = template,
        call = call
      )
    )
  )

  site$do_operation(
    op = "lists",
    body = body,
    encode = "json",
    http_verb = "POST"
  )
}

#' Create listinfo object
#'
#' Helper function to create a listInfo object for use internally by [create_sp_list()].
#' See: <https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0>
#'
#' @param template Type of template to use in creating the list.
#' @param content_types Optional. Set `TRUE` for `contentTypesEnabled` to be enabled.
#' @param hidden Optional. Set `TRUE` for list to be hidden.
#' @keywords internal
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

  vctrs::list_drop_empty(
    list(
      hidden = hidden,
      contentTypesEnabled = content_types,
      template = template
    )
  )
}
