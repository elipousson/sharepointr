#' Get a SharePoint item or item properties
#'
#' [get_sp_item()] wraps the `get_item` method for `ms_drive` objects and
#' returns a `ms_drive_item` object by default. [get_sp_item_properties()] uses
#' the `get_item_properties` method (also available by setting `properties =
#' TRUE` for [get_sp_item()]). Additional parameters in `...` are passed to
#' [get_sp_drive()] by [get_sp_item()] or to [get_sp_item()] by
#' [get_sp_item_properties()] or [delete_sp_item()].
#'
#' @param path A SharePoint file URL or the relative path to a file located in a
#'   SharePoint drive. If input is a relative path, the string should *not*
#'   include the drive name. If input is a shared file URL, the text "Shared "
#'   is removed from the start of the SharePoint drive name by default. If file
#'   is a document URL, the `.default_drive_name` argument is used as the
#'   `drive_name` and the `item_id` is extracted from the URL.
#' @param item_id A SharePoint item ID passed to the `itemid` parameter of the
#'   `get_item` method for `ms_drive` objects.
#' @inheritDotParams get_sp_drive -properties
#' @param drive_name,drive_id SharePoint drive name or ID.
#' @param drive A `ms_drive` object. If drive is supplied, `drive_name`,
#'   `site_url`, and any additional parameters passed to `...` are ignored.
#' @param properties If `TRUE`, use the `get_item_properties` method and return
#'   item properties instead of the item.
#' @inheritParams get_sp_drive
#' @param as_data_frame If `TRUE`, return a data frame. If `FALSE` (default),
#'   return a `ms_item` or `ms_item_properties` object.
#' @seealso [Microsoft365R::ms_drive_item]
#' @export
get_sp_item <- function(path = NULL,
                        item_id = NULL,
                        ...,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        site_url = NULL,
                        properties = FALSE,
                        as_data_frame = FALSE,
                        call = caller_env()) {
  if (is_url(path)) {
    url <- path
    path <- NULL

    sp_url_parts <- sp_url_parse(
      url = url,
      call = call
    )

    if (is_null(item_id) && is_null(sp_url_parts[["item_id"]])) {
      path <- sp_url_parts[["file_path"]]
    }

    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
    item_id <- item_id %||% sp_url_parts[["item_id"]]
    site_url <- site_url %||% sp_url_parts[["site_url"]]
  }

  drive <- drive %||% get_sp_drive(
    drive_name = drive_name,
    drive_id = drive_id,
    ...,
    properties = FALSE,
    site_url = site_url,
    call = call
  )

  check_ms_drive(drive, call = call)
  check_exclusive_strings(path, item_id, call = call)

  if (properties) {
    item_properties <- drive$get_item_properties(
      path = path,
      itemid = item_id
    )

    if (!as_data_frame) {
      return(item_properties)
    }

    item_properties <- ms_obj_as_data_frame(
      item_properties,
      # TODO: Check if this is the right name
      obj_col = "ms_item_properties",
      keep_list_cols = c("createdBy", "lastModifiedBy")
    )

    return(item_properties)
  }

  item <- drive$get_item(path = path, itemid = item_id)

  if (!as_data_frame) {
    return(item)
  }

  ms_obj_as_data_frame(
    item,
    obj_col = "ms_item",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
    )
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
                                   as_data_frame = FALSE,
                                   call = caller_env()) {
  get_sp_item(
    path = path,
    item_id = item_id,
    ...,
    drive = drive,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    properties = TRUE,
    as_data_frame = as_data_frame,
    call = call
  )
}

#' Delete SharePoint items (files and directories)
#'
#' [delete_sp_item()] deletes items including files and directories using the `delete` method for . By default
#' `confirm = TRUE`, which requires the user to respond to a prompt: "Do you
#' really want to delete the drive item ...? (yes/No/cancel)" to continue.
#'
#' @details Trouble-shooting errors
#'
#' If you get the error: "The resource you are attempting to access is locked",
#' you or another user may have the file or a file within the directory open for
#' editing. Close the file and try deleting the item again.
#'
#' If you get the error: "Request was cancelled by event received. If attempting
#' to delete a non-empty folder, it's possible that it's on hold." set `by_item
#' = TRUE` and try again.
#'
#' @name delete_sp_item
#' @inheritParams get_sp_item
#' @param confirm If `TRUE`, confirm before deleting item. If `TRUE` and session
#'   is not interactive, the function will error.
#' @param by_item For business OneDrive or SharePoint document libraries, you
#'   may need to set `by_item = TRUE` to delete the contents of a folder
#'   depending on the policies set up by your SharePoint administrator policies.
#'   Note, that this method can be slow for large folders.
#' @export
delete_sp_item <- function(path = NULL,
                           ...,
                           item_id = NULL,
                           item = NULL,
                           drive_name = NULL,
                           drive_id = NULL,
                           drive = NULL,
                           site_url = NULL,
                           confirm = TRUE,
                           by_item = FALSE,
                           call = caller_env()) {
  item <- item %||% get_sp_item(
    path = path,
    item_id = item_id,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    ...,
    call = call
  )

  check_ms(item, "ms_drive_item", call = call)

  if (!is_interactive() && is_true(confirm)) {
    cli_abort(
      "{.arg confirm} must be {.code FALSE} if the session is not interactive.",
      call = call
    )
  }

  try_fetch(
    item$delete(confirm = confirm, by_item = by_item),
    error = function(cnd) {
      cli_abort(
        cnd$message,
        call = call
      )
    }
  )
}

#' Download one or more items from SharePoint to a file or folder
#'
#' [download_sp_item()] wraps the `download` method for SharePoint items making
#' it easier to download items based on a shared file URL or document URL. The
#' default valye for `path` is `""` so, by default, SharePoint items are
#' downloaded to the current working directory. Set `overwrite = TRUE` to allow
#' this function to overwrite an existing file. [download_sp_file()] is
#' identical except for the name of the path parameter (which is file instead of
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
#' @param item A `ms_drive_item` class object. Optional if path or other
#'   parameters to get an SharePoint item are supplied.
#' @returns Invisibly returns the input `dest` or the `dest` parsed from the input
#'   path or item properties.
#' @inheritDotParams get_sp_item
#' @export
download_sp_item <- function(path = NULL,
                             new_path = "",
                             ...,
                             item_id = NULL,
                             item = NULL,
                             drive_name = NULL,
                             drive_id = NULL,
                             drive = NULL,
                             site_url = NULL,
                             dest = NULL,
                             overwrite = FALSE,
                             recursive = FALSE,
                             parallel = FALSE,
                             call = caller_env()) {
  if (is.null(item)) {
    cli::cli_progress_step(
      "Getting item from SharePoint"
    )

    item <- get_sp_item(
      path = path,
      item_id = item_id,
      drive_name = drive_name,
      drive_id = drive_id,
      site_url = site_url,
      ...,
      call = call
    )
  }

  check_ms(item, "ms_drive_item", call = call)

  # FIXME: Take a closer look at why this is needed
  if ((new_path == "") || is.null(new_path)) {
    dest <- dest %||% item$properties$name
  } else {
    dest <- dest %||% sp_file_dest(file = path, path = new_path)
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