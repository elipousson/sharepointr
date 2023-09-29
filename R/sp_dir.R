#' List SharePoint files and folders
#'
#' @description
#'
#' [sp_dir_info()] is a wrapper for the `list_files` method.
#'
#' @param path Path to directory or folder. SharePoint folder URLs are allowed.
#'   If `NULL`, path is set to default "/".
#' @param info The information to return: "partial", "name" or "all". If
#'   "partial", a data frame is returned containing the name, size, ID and
#'   whether the item is a file or folder. If "all", a data frame is returned containing all the
#'   properties for each item (this can be large).
#' @param full_name If `TRUE` (default), return the full file path as the name
#'   for each item.
#' @param pagesize Maximum number of items to return. Defaults to 1000. Decrease
#'   if you are experiencing timeouts.
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @export
sp_dir_info <- function(path = NULL,
                        ...,
                        info = "partial",
                        full_names = TRUE,
                        pagesize = 1000,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        call = caller_env()) {
  if (!is.null(path) && is_sp_url(path)) {
    sp_url_parts <- sp_url_parse(path, call = call)
    drive_name <- path
    path <- sp_url_parts[["file_path"]]
  }

  drive <- drive %||% get_sp_drive(
    drive_name = drive_name,
    drive_id = drive_id,
    ...,
    properties = FALSE,
    call = call
  )

  check_ms_drive(drive, call = call)

  path <- path %||% "/"

  info <- arg_match(info, values = c("partial", "name", "all"), call = call)

  drive$list_items(
    path = path,
    info = info,
    full_names = full_names,
    pagesize = pagesize
    )
}

#' @rdname sp_dir_info
#' @name sp_dir_ls
#' @export
sp_dir_ls <- function(path = NULL,
                      ...,
                      full_names = TRUE,
                      pagesize = 1000,
                      drive_name = NULL,
                      drive_id = NULL,
                      drive = NULL,
                      call = caller_env()) {
  sp_dir_info(
    path = path,
    ...,
    info = "name",
    full_names = full_names,
    pagesize = pagesize,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )
}

#' Create SharePoint folders
#'
#' [sp_dir_create()] is a wrapper for the `create_folder` method that handles
#' character vectors.
#'
#' @param path A character vector of one or more paths.
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @inheritDotParams get_sp_drive
#' @export
sp_dir_create <- function(path,
                          ...,
                          drive_name = NULL,
                          drive_id = NULL,
                          drive = NULL,
                          call = caller_env()) {
  drive <- drive %||%
    get_sp_drive(drive_name = drive_name, drive_id = drive_id, ..., call = call)

  for (dir in path) {
    drive$create_folder(path = path)
  }

  invisible(path)
}
