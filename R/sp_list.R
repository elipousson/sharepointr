#' Get drive or site for list
#'
#' @noRd
get_ms_list_obj <- function(list_name = NULL,
                            list_id = NULL,
                            ...,
                            site_url = NULL,
                            site = NULL,
                            drive_name = NULL,
                            drive_id = NULL,
                            drive = NULL,
                            call = caller_env()) {
  if (!is.null(drive) ||
    (!is.null(drive_name) && !identical(drive_name, "Lists")) ||
    !is.null(drive_id)) {
    drive <- drive %||% get_sp_drive(
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

  site <- site %||% get_sp_site(
    site_url = site_url,
    ...,
    call = call
  )

  check_ms_site(site, call = call)

  site
}

#' Shared general definitions for Microsoft Graph API parameters
#'
#' @name ms_graph_terms
#' @param filter A string with [an OData
#'   expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
#'   apply as a filter to the results. Learn more in the [Microsoft Graph API
#'   documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
#'   on using filter query parameters.
#' @param n Maximum number of lists, plans, tasks, or other items to return.
#'   Defaults to `NULL` which sets n to `Inf`.
#' @keywords internal
NULL

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
get_sp_list <- function(list_name = NULL,
                        list_id = NULL,
                        ...,
                        site_url = NULL,
                        site = NULL,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        metadata = FALSE,
                        as_data_frame = FALSE,
                        call = caller_env()) {
  # FIXME: URL parsing is not set up for links to SharePoint lists
  if (is_url(list_name)) {
    url <- list_name
    list_name <- NULL

    sp_url_parts <- sp_url_parse(
      url = url,
      call = call
    )

    # FIXME: Parsing the drive_name for lists does not typically work
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]

    if (is_null(list_id) && is_null(sp_url_parts[["item_id"]])) {
      list_name <- sp_url_parts[["file_path"]]
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
#' @inheritParams ms_graph_terms
#' @export
list_sp_lists <- function(site_url = NULL,
                          filter = NULL,
                          n = Inf,
                          ...,
                          site = NULL,
                          drive_name = NULL,
                          drive_id = NULL,
                          drive = NULL,
                          as_data_frame = TRUE,
                          call = caller_env()) {
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
    keep_list_cols = c("createdBy", "lastModifiedBy")
  )
}

#' @rdname sp_list
#' @name get_sp_list_metadata
#' @param sp_list A `ms_list` object. If supplied, `list_name`, `list_id`,
#'   `site_url`, `site`, `drive_name`, `drive_id`, `drive`, and any additional
#'   parameters passed to `...` are all ignored.
#' @export
get_sp_list_metadata <- function(list_name = NULL,
                                 list_id = NULL,
                                 sp_list = NULL,
                                 ...,
                                 site_url = NULL,
                                 site = NULL,
                                 drive_name = NULL,
                                 drive_id = NULL,
                                 drive = NULL,
                                 call = caller_env()) {
  if (is.null(sp_list)) {
    sp_list_metadata <- get_sp_list(
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

    return(sp_list_metadata)
  }

  check_ms(sp_list, "ms_list", call = call)

  sp_list$get_column_info()
}


#' @rdname sp_list
#' @name delete_sp_list
#' @param confirm If `TRUE`, confirm deletion of list before proceeding.
#' @export
delete_sp_list <- function(list_name = NULL,
                           list_id = NULL,
                           sp_list = NULL,
                           confirm = TRUE,
                           ...,
                           site_url = NULL,
                           site = NULL,
                           drive_name = NULL,
                           drive_id = NULL,
                           drive = NULL,
                           call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
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

  check_ms(sp_list, "ms_list", call = call)

  sp_list$delete(confirm = confirm)
}
