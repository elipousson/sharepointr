#' List SharePoint files
#'
#' @description
#'
#' [sp_dir_info()] is a wrapper for the `list_files` method.
#'
#' @param path Path to directory or folder. SharePoint folder URLs are allowed.
#'   If `NULL`, path is set to default "/".
#' @inheritDotParams get_sp_drive -properties
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @export
sp_dir_info <- function(path = NULL,
                        ...,
                        drive_name = NULL,
                        drive = NULL,
                        call = caller_env()) {
  if (is_sp_url(path)) {
    sp_url_parts <- sp_url_parse(path, call = call)

    drive_name <- path
    site_url <- path
    path <- sp_url_parts[["file_path"]]
  }

  drive <- drive %||% get_sp_drive(
    drive_name = drive_name,
    ...,
    call = call
  )

  check_ms_drive(drive, call = call)

  path <- path %||% "/"

  drive$list_files(path = path)
}
