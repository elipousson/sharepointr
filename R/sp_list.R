#' Get a SharePoint list, list items, or a list of SharePoint lists
#'
#' [get_sp_list()] is a wrapper for the `get_list` and `list_items` methods.
#' This function is still under development and does not support the URL parsing
#' used by [get_sp_item()]. [list_sp_lists()] returns all lists for a SharePoint
#' site or drive as a list or data frame.
#'
#' @inheritDotParams get_sp_drive
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @seealso
#' - [Microsoft365R::ms_list]
#' - [Microsoft365R::ms_list_item]
#' @name sp_list
NULL

#' @rdname sp_list
#' @name get_sp_list
#' @param list_name,list_id SharePoint List name or ID string.
#' @param items If `TRUE` (default), use the `list_items` method to return a
#'   data frame with all items in the specified list. If `FALSE`, return a
#'   `ms_list` class object or, if `as_data_frame` is `TRUE`, a data frame with a "ms_list" column.
#' @param as_data_frame If `TRUE` (default), return a data frame with a
#'   "ms_list" column. [get_sp_list()] returns a 1 row data frame and
#'   [list_sp_lists()] returns a data frame with n rows or all lists available
#'   for the SharePoint site or drive.
#' @export
get_sp_list <- function(list_name = NULL,
                        list_id = NULL,
                        ...,
                        site_url = NULL,
                        site = NULL,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        items = TRUE,
                        as_data_frame = TRUE,
                        call = caller_env()) {
  cli::cli_progress_step(
    "Getting list from SharePoint"
  )

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

  site_list <- TRUE

  if (!is.null(drive) ||
    (!is.null(drive_name) && !identical(drive_name, "Lists")) ||
    !is.null(drive_id)) {
    site_list <- FALSE

    drive <- drive %||% get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      site_url = site_url,
      call = call
    )

    check_ms_drive(drive, call = call)
  } else {
    site <- site %||% get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

    check_ms_site(site, call = call)
  }

  check_exclusive_strings(list_name, list_id, call = call)

  if (site_list) {
    sp_list <- site$get_list(list_name = list_name, list_id = list_id)
  } else {
    sp_list <- drive$get_list(list_name = list_name, list_id = list_id)
  }

  if (items) {
    sp_list_items <- sp_list$list_items()

    return(sp_list_items)
  }

  if (!as_data_frame) {
    return(sp_list)
  }

  ms_obj_as_data_frame(
    sp_list,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy")
  )
}

#' @rdname sp_list
#' @name list_sp_lists
#' @param filter Filter for lists.
#' @param n Number of lists to return.
#' @export
list_sp_lists <- function(site_url = NULL,
                          filter = NULL,
                          n = NULL,
                          ...,
                          site = NULL,
                          drive_name = NULL,
                          drive_id = NULL,
                          drive = NULL,
                          items = TRUE,
                          as_data_frame = TRUE,
                          call = caller_env()) {
  # FIXME: This chunk (128-152) is copied from get_sp_list
  # Put it into a function to avoid duplication
  site_list <- TRUE

  if (!is.null(drive) ||
    (!is.null(drive_name) && !identical(drive_name, "Lists")) ||
    !is.null(drive_id)) {
    site_list <- FALSE

    drive <- drive %||% get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      site_url = site_url,
      call = call
    )

    check_ms_drive(drive, call = call)
  } else {
    site <- site %||% get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

    check_ms_site(site, call = call)
  }

  if (site_list) {
    sp_lists <- site$get_lists(filter = filter, n = n %||% Inf)
  } else {
    sp_lists <- drive$get_lists(filter = filter, n = n %||% Inf)
  }

  if (!as_data_frame) {
    return(sp_lists)
  }

  ms_obj_list_as_data_frame(
    sp_lists,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy")
  )
}
