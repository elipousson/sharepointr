#' Get a SharePoint item or item properties
#'
#' [get_sp_item()] wraps the `get_item` method for `ms_drive` objects and
#' returns a `ms_drive_item` object by default. [get_sp_item_properties()] uses
#' the `get_item_properties` method (also available by setting `properties =
#' TRUE` for [get_sp_item()]).
#'
#' @param path A SharePoint file URL or the relative path to a file located in a
#'   SharePoint drive. If input is a relative path, the string should *not*
#'   include the drive name. If input is a shared file URL, the text "Shared "
#'   is removed from the start of the SharePoint drive name by default. If file
#'   is a document URL, the `.default_drive_name` argument is used as the
#'   `drive_name` and the `item_id` is extracted from the URL.
#' @param item_id A SharePoint item ID passed to the `itemid` parameter of the
#'   `get_item` method for `ms_drive` objects.
#' @inheritDotParams get_sp_drive
#' @param drive_name,drive_id SharePoint drive name or ID.
#' @param drive A `ms_drive` object. If drive is supplied, `drive_name`,
#'   `site_url`, and any additional parameters passed to `...` are ignored.
#' @param properties If `TRUE`, use `get_item_properties` method and return item
#'   properties instead of the item.
#' @inheritParams get_sp_drive
#' @export
get_sp_item <- function(path = NULL,
                        item_id = NULL,
                        ...,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        site_url = NULL,
                        .default_drive_name = getOption(
                          "sharepointr.default_drive_name",
                          "Documents"
                        ),
                        properties = FALSE,
                        call = caller_env()) {
  if (is_url(path)) {
    sp_url_parts <- sp_url_parse(
      url = path,
      call = call
    )

    path <- NULL

    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]

    if (is_null(item_id) && is_null(sp_url_parts[["item_id"]])) {
      path <- sp_url_parts[["file_path"]]
    }

    item_id <- item_id %||% sp_url_parts[["item_id"]]

    site_url <- site_url %||% sp_url_parts[["site_url"]]
  }

  drive <- drive %||% get_sp_drive(
    drive_name = drive_name,
    drive_id = drive_id,
    ...,
    .default_drive_name = .default_drive_name,
    site_url = site_url,
    call = call
  )

  check_ms_drive(drive, call = call)

  if (!is_string(path) && !is_string(item_id)) {
    cli_abort(
      "A {.arg path} or {.arg item_id} string must be supplied.",
      call = call
    )
  }

  if (properties) {
    item_properties <- drive$get_item_properties(
      path = path,
      itemid = item_id
    )

    return(item_properties)
  }

  drive$get_item(path = path, itemid = item_id)
}

#' @rdname get_sp_item
#' @name get_sp_item_properties
#' @export
get_sp_item_properties <- function(path = NULL,
                                   item_id = NULL,
                                   ...,
                                   drive = NULL,
                                   drive_name = NULL,
                                   drive_id = NULL,
                                   site_url = NULL,
                                   .default_drive_name = getOption(
                                     "sharepointr.default_drive_name",
                                     "Documents"
                                   ),
                                   call = caller_env()) {
  get_sp_item(
    path = path,
    item_id = item_id,
    ...,
    drive = drive,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    .default_drive_name = .default_drive_name,
    properties = TRUE,
    call = call
  )
}

#' Download one or more items from SharePoint to a file or folder
#'
#' [download_sp_item()] wraps the `download` method for SharePoint items making
#' it easier to download items based on a shared file URL or document URL. The
#' default valye for `path` is `""` so, by default, SharePoint items are
#' downloaded to the current working directory. Set `overwrite = TRUE` to allow
#' this function to overwrite an existing file. [download_sp_file()] is
#' identical except for the name of the path paramter (which is file instead of
#' path).
#'
#' @name download_sp_item
#' @param path,file Required. A SharePoint shared file URL, document URL, or, if
#'   `item_id` is supplied, a file name to use with `path` to set `dest` with
#'   location and filename for downloaded item.
#' @param new_path Path to directory for downloaded item. Optional if `dest` is
#'   supplied.
#' @inheritParams get_sp_item
#' @param dest,overwrite,recursive,parallel Parameters passed to `download`
#'   method for `ms_drive_item` object.
#' @export
download_sp_item <- function(path,
                             new_path = "",
                             ...,
                             drive_name = NULL,
                             drive_id = NULL,
                             drive = NULL,
                             site_url = NULL,
                             dest = NULL,
                             overwrite = FALSE,
                             recursive = FALSE,
                             parallel = FALSE,
                             call = caller_env()) {
  cli::cli_progress_step(
    "Getting item from SharePoint"
  )

  item <- get_sp_item(
    path = path,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    ...,
    call = call
  )

  check_ms_drive_item(item, call = call)

  # FIXME: Take a closer look at why this is needed
  if ((new_path == "") || is.null(new_path)) {
    dest <- dest %||%
      item$properties$name
  } else {
    dest <- dest %||%
      sp_file_dest(file = path, path = new_path)
  }

  check_string(dest, call = call)

  cli::cli_progress_step(
    "Downloading SharePoint item to {.file {dest}}"
  )

  item$download(
    dest = dest,
    overwrite = overwrite,
    recursive = recursive,
    parallel = parallel
  )

  invisible(dest)
}

#' @rdname download_sp_item
#' @name download_sp_file
#' @export
download_sp_file <- function(file,
                             new_path = "",
                             ...,
                             call = caller_env()) {
  download_sp_item(
    path = file,
    new_path = new_path,
    ...,
    call = call
  )
}

#' Set a file destination for a SharePoint file before downloading
#'
#' @noRd
sp_file_dest <- function(file, path = tempdir()) {
  if (is_sp_url(file)) {
    file <- sp_url_parse(file)[["file"]]
  }

  str_c_fsep(path, basename(file))
}
