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
#' @param items If `TRUE`, use the `list_items` method to return a data frame
#'   with all items in the specified list.
#' @export
get_sp_list <- function(list_name = NULL,
                        list_id = NULL,
                        ...,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        site_url = NULL,
                        .default_drive_name = getOption(
                          "sharepointr.default_drive_name",
                          "Documents"
                        ),
                        items = FALSE,
                        call = caller_env()) {
  cli::cli_progress_step(
    "Getting list from SharePoint"
  )

  # FIXME: URL parsing is not set up for links to SharePoint lists
  # if (is_url(list_name)) {
  #   sp_url_parts <- sp_url_parse(
  #     url = list_name,
  #     call = call
  #   )
  #
  #   list_name <- NULL
  #
  #   drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
  #
  #   # FIXME: Check if this works
  #   # if (is_null(list_id) && is_null(sp_url_parts[["item_id"]])) {
  #   #   list_name <- sp_url_parts[["file_path"]]
  #   # }
  #   #
  #   # list_id <- list_id %||% sp_url_parts[["item_id"]]
  #
  #   site_url <- site_url %||% sp_url_parts[["site_url"]]
  # }

  drive <- drive %||% get_sp_drive(
    drive_name = drive_name,
    drive_id = drive_id,
    ...,
    .default_drive_name = .default_drive_name,
    site_url = site_url,
    call = call
  )

  check_ms_drive(drive, call = call)

  if (!is_string(list_name) && !is_string(list_id)) {
    cli_abort(
      "A {.arg list_name} or {.arg list_id} string must be supplied.",
      call = call
    )
  }

  drive_list <- drive$get_list(list_name = list_name, list_id = list_id)

  if (!items) {
    return(drive_list)
  }

  drive_list$list_items()
}
