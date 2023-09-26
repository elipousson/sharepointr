#' Get a SharePoint list
#'
#' [get_sp_list()] is a wrapper for the `get_list` and `list_items` methods.
#' This function is still under development and does not support the URL parsing
#' used by [get_sp_item()].
#'
#' @param list_name,list_id SharePoint List name or ID string.
#' @inheritDotParams get_sp_drive
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @param items If `TRUE` (default), use the `list_items` method to return a
#'   data frame with all items in the specified list. If `FALSE`, return a
#'   `ms_list` class object.
#' @export
get_sp_list <- function(list_name = NULL,
                        list_id = NULL,
                        ...,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        site_url = NULL,
                        site = NULL,
                        .default_drive_name = getOption(
                          "sharepointr.default_drive_name",
                          "Documents"
                        ),
                        items = TRUE,
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

  if (!is.null(drive) || !identical(drive_name, "Lists")) {
    site_list <- FALSE

    drive <- drive %||% get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      .default_drive_name = .default_drive_name,
      site_url = site_url,
      call = call
    )

    check_ms_drive(drive, call = call)
  } else {
    site <- get_sp_site(
      site_url = site_url,
      call = call
    )

    check_ms_site(site, call = call)
  }

  if (!is_string(list_name) && !is_string(list_id)) {
    cli_abort(
      "A {.arg list_name} or {.arg list_id} string must be supplied.",
      call = call
    )
  }

  if (site_list) {
    sp_list <- site$get_list(list_name = list_name, list_id = list_id)
  } else {
    sp_list <- drive$get_list(list_name = list_name, list_id = list_id)
  }

  if (items) {
    return(sp_list$list_items())
  }

  sp_list
}
