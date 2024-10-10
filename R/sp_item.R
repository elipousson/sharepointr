#' Get a SharePoint item or item properties
#'
#' @description
#' [get_sp_item()] wraps the `get_item` method for `ms_drive` objects and
#' returns a `ms_drive_item` object by default. [get_sp_item_properties()] uses
#' the `get_item_properties` method (also available by setting `properties =
#' TRUE` for [get_sp_item()]).
#'
#' Additional parameters in `...` are passed to [get_sp_drive()] by
#' [get_sp_item()] or to [get_sp_item()] by [get_sp_item_properties()] or
#' [delete_sp_item()].
#'
#' @param path A SharePoint file URL or the relative path to a file located in a
#'   SharePoint drive. If input is a relative path, the string should *not*
#'   include the drive name. If input is a shared file URL, the text "Shared "
#'   is removed from the start of the SharePoint drive name by default. If file
#'   is a document URL, the `default_drive_name` argument is used as the
#'   `drive_name` and the `item_id` is extracted from the URL.
#' @param item_id A SharePoint item ID passed to the `itemid` parameter of the
#'   `get_item` method for `ms_drive` objects.
#' @param item_url A SharePoint item URL used to parse the item ID, drive name,
#'   and site URL.
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
#' @examples
#' sp_item_url <- "<SharePoint item url>"
#'
#' if (is_sp_url(sp_item_url)) {
#'   get_sp_item(
#'     item_url = sp_item_url
#'   )
#' }
#'
#' @export
get_sp_item <- function(path = NULL,
                        item_id = NULL,
                        item_url = NULL,
                        ...,
                        drive_name = NULL,
                        drive_id = NULL,
                        drive = NULL,
                        site_url = NULL,
                        properties = FALSE,
                        as_data_frame = FALSE,
                        call = caller_env()) {
  if (is.null(drive)) {
    if (is_url(path)) {
      item_url <- path
      path <- NULL
    }

    if (is_url(item_url)) {
      sp_url_parts <- sp_url_parse(
        url = item_url,
        call = call
      )

      if (is_null(item_id) && is_null(sp_url_parts[["item_id"]])) {
        path <- sp_url_parts[["file_path"]]
      }

      drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
      item_id <- item_id %||% sp_url_parts[["item_id"]]
      site_url <- site_url %||% sp_url_parts[["site_url"]]
    }
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
                                   item_url = NULL,
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
    item_url = item_url,
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
#' [delete_sp_item()] deletes items including files and directories using the
#' `delete` method for . By default `confirm = TRUE`, which requires the user to
#' respond to a prompt: "Do you really want to delete the drive item ...?
#' (yes/No/cancel)" to continue.
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
#' @inheritDotParams get_sp_item -properties
#' @inheritParams download_sp_item
#' @export
delete_sp_item <- function(path = NULL,
                           confirm = TRUE,
                           by_item = FALSE,
                           ...,
                           item_id = NULL,
                           item_url = NULL,
                           item = NULL,
                           drive_name = NULL,
                           drive_id = NULL,
                           drive = NULL,
                           site_url = NULL,
                           call = caller_env()) {
  item <- item %||% get_sp_item(
    path = path,
    item_id = item_id,
    item_url = item_url,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    ...,
    properties = FALSE,
    call = call
  )

  check_ms_obj(item, "ms_drive_item", call = call)

  if (!is_interactive() && is_true(confirm)) {
    cli_abort(
      "{.arg confirm} must be {.code FALSE} if the session is not interactive.",
      call = call
    )
  }

  withCallingHandlers(
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
#' it easier to download items based on a shared file URL or document URL.
#'
#' @details
#' The default value for `path` is `""` so, by default, SharePoint items are
#' downloaded to the current working directory. Set `overwrite = TRUE` to allow
#' this function to overwrite an existing file. [download_sp_file()] is
#' identical except for the name of the path parameter (which is file instead of
#' path).
#'
#' Note, if the selected item is a folder and `recurse = TRUE`, it may
#' take some time to download the enclosed items and `{Microsoft365R}` does not
#' provide a progress bar for that operation.
#'
#' @name download_sp_item
#' @param path,file Required. A SharePoint shared file URL, document URL, or, if
#'   `item_id` is supplied, a file name to use with `path` to set `dest` with
#'   location and filename for downloaded item.
#' @param new_path Path to directory for downloaded item. Optional if `dest` is
#'   supplied. If path contains a file name, the item will be downloaded using
#'   that file name instead of the file name of the original item. If `new_path`
#'   refers to a nonexistent directory and the item is a file, the directory
#'   will be silently created using [fs::dir_create()].
#' @inheritParams get_sp_item
#' @param dest,overwrite,recursive,parallel Parameters passed to `download`
#'   method for `ms_drive_item` object.
#' @param item A `ms_drive_item` class object. Optional if path or other
#'   parameters to get an SharePoint item are supplied.
#' @returns Invisibly returns the input `dest` or the `dest` parsed from the
#'   input path or item properties.
#' @inheritDotParams get_sp_item
#' @aliases sp_item_download
#'
#' @section Batch downloads for SharePoint items:
#'
#' If provided with a vector of paths or a vector of item ID values,
#' [download_sp_item()] can execute a batch download on a set of files or
#' folders. Make sure to supply a vector to `new_path` or `dest` vector with the
#' directory names or file names to use as a destination for the downloads. With
#' either option, you must supply a `drive`, a `drive_name` and `site`, or a
#' `drive_url`. You can also pass a bare list of items and the value for the
#' `dest` can be inferred from the item properties.
#'
#' @examples
#'
#' # Download a single directory
#'
#' sp_dir_url <- "<SharePoint directory url>"
#'
#' new_path <- "local file path"
#'
#' if (is_sp_url(sp_dir_url)) {
#'   download_sp_item(
#'     sp_dir_url,
#'     new_path = new_path,
#'     recursive = TRUE
#'   )
#' }
#'
#' # Batch download multiple directories from a SharePoint Drive
#'
#' sp_drive_url <- "<SharePoint Drive url>"
#'
#' if (is_sp_url(sp_drive_url)) {
#'   drive <- get_sp_drive(drive_name = sp_drive_url)
#'
#'   drive_dir_list <- sp_dir_info(
#'     drive = drive,
#'     recurse = TRUE,
#'     type = "dir"
#'   )
#'
#'   download_sp_item(
#'     item_id = drive_dir_list$id,
#'     dest = drive_dir_list$name,
#'     recursive = TRUE,
#'     drive = drive
#'   )
#' }
#'
#' @export
download_sp_item <- function(path = NULL,
                             new_path = "",
                             ...,
                             item_id = NULL,
                             item_url = NULL,
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
  if ((length(path) > 1) || (length(item_id) > 1) ||
    (is_bare_list(item) && (length(item) > 1))) {
    dest_list <- batch_download_sp_item(
      path = path,
      new_path = new_path,
      ...,
      item_id = item_id,
      item = item,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      site_url = site_url,
      dest = dest,
      overwrite = overwrite,
      recursive = recursive,
      parallel = parallel,
      call = call
    )

    return(invisible(dest_list))
  }

  if (is.null(item)) {
    item <- get_sp_item(
      path = path,
      item_id = item_id,
      item_url = item_url,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      site_url = site_url,
      ...,
      call = call
    )
  }

  check_ms_obj(item, "ms_drive_item", call = call)

  # FIXME: Take a closer look at why this is needed
  if ((new_path == "") || is.null(new_path)) {
    if (is_empty(dest) || dest == "") {
      dest <- NULL
    }

    dest <- dest %||% item$properties$name
  } else if (is.null(dest)) {
    # FIXME: Consider adding a helper function to handle this or addressing the
    # issue in sp_file_dest
    # Added 2024-03-06 to fix issue when new_path contains a file name
    if (fs::path_ext(new_path) != "") {
      dest <- new_path
    } else {
      dest <- sp_file_dest(file = path, path = new_path)
    }
  }

  check_string(dest, call = call)

  dest_dir <- dirname(dest)
  dest_dir_exists <- dir.exists(dest_dir)

  if (item$is_folder()) {
    if (!dest_dir_exists) {
      cli::cli_abort(
        c("{.arg new_path} or {.arg dest} must exist if item is a folder.",
          "i" = "Create a new folder at {.path {dirname(dest)}} to
          download the item."
        ),
        call = call
      )
    }

    if (!recursive) {
      cli::cli_bullets(
        c(
          "!" = "If the SharePoint item is a folder and {.arg recursive = FALSE},
          only the folder is downloaded.",
          "i" = "Set {.arg recursive = TRUE} to download folder contents."
        )
      )
    }
  } else {
    fs::dir_create(dest_dir)
  }

  cli::cli_progress_step(
    "Downloading SharePoint item to {.file {dest}}"
  )

  if (overwrite && fs::file_exists(dest)) {
    fs::file_delete(dest)
  }

  # TODO: Compare using the item level download method and the download_file and
  # download_folder methods available for ms_drive objects
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
#' @aliases sp_file_download
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
sp_file_dest <- function(file = NULL, path = tempdir()) {
  if (is_sp_url(file)) {
    sp_url_parts <- sp_url_parse(file)

    file <- sp_url_parts[["file"]] %||%
      sp_url_parts[["file_path"]]
  }

  if (!is.null(file)) {
    file <- basename(file)
  }

  str_c_fsep(path, file)
}

#' @noRd
batch_download_sp_item <- function(path = NULL,
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
  if (is_bare_list(item)) {
    size <- length(item)
  } else {
    size <- max(c(length(path), length(item_id)))

    if (is.null(dest)) {
      dest <- vctrs::vec_recycle(new_path, size, x_arg = "new_path", call = call)
    } else {
      dest <- vctrs::vec_recycle(dest, size, x_arg = "dest", call = call)
    }
  }

  if (length(path) > 1) {
    dest_list <- map2_chr(
      path, dest,
      \(x, y) {
        download_sp_item(
          path = x, dest = y,
          ...,
          drive_name = drive_name,
          drive_id = drive_id,
          drive = drive,
          site_url = site_url,
          overwrite = overwrite,
          recursive = recursive,
          parallel = parallel,
          call = call
        )
      }
    )
  }

  if (length(item_id) > 1) {
    dest_list <- map2_chr(
      item_id, dest,
      \(x, y) {
        download_sp_item(
          item_id = x, dest = y,
          ...,
          drive_name = drive_name,
          drive_id = drive_id,
          drive = drive,
          site_url = site_url,
          overwrite = overwrite,
          recursive = recursive,
          parallel = parallel,
          call = call
        )
      }
    )
  }

  if (is_bare_list(item) && (length(item) > 1)) {
    dest_list <- map2_chr(
      item,
      \(x) {
        download_sp_item(
          item = x, dest = dest, new_path = new_path,
          ...,
          drive_name = drive_name,
          drive_id = drive_id,
          drive = drive,
          site_url = site_url,
          overwrite = overwrite,
          recursive = recursive,
          parallel = parallel,
          call = call
        )
      }
    )
  }

  invisible(dest_list)
}

#' Download a SharePoint List
#'
#' [download_sp_list()] downloads a SharePoint list to a CSV or XLSX file.
#'
#' @param sp_list SharePoint list object. If supplied, all parameters supplied
#'   to `...` are ignored.
#' @param fileext File extension to use for output file. Must be `"csv"` or
#'   `"xlsx"`.
#' @param new_path Optional path to new file. If not `new_path` provided, the
#'   file name is pulled from the name of the SharePoint list using the provided
#'   `fileext`. If `new_path` is provided, `fileext` is ignored.
#' @inheritDotParams get_sp_list
#' @inheritParams rlang::args_error_context
#' @inheritParams ms_obj_as_data_frame
#' @export
download_sp_list <- function(...,
                             new_path = "",
                             sp_list = NULL,
                             fileext = "csv",
                             keep_list_cols = c("createdBy", "lastModifiedBy"),
                             call = caller_env()) {
  sp_list <- sp_list %||% get_sp_list(
    ...
  )

  sp_list_df <- ms_obj_as_data_frame(
    sp_list,
    obj_col = "ms_list",
    keep_list_cols = keep_list_cols,
    .error_call = call
  )

  sp_list_df <- fmt_sp_list_col(sp_list_df)

  if (new_path == "") {
    new_path <- NULL
  }

  list_filename <- paste0(sp_list[["properties"]][["name"]], ".", fileext)

  if (is_installed("fs")) {
    list_filename <- fs::path_sanitize(list_filename)
  }

  new_path <- new_path %||% list_filename

  # TODO: Add option to write list directly to Google Sheets
  if (stringr::str_detect(new_path, "csv$")) {
    check_installed("readr", call = call)
    readr::write_csv(sp_list_df, file = new_path, ...)
  } else if (stringr::str_detect(new_path, ".xlsx$")) {
    check_installed("openxlsx2", call = call)
    openxlsx2::write_xlsx(sp_list_df, file = new_path, ...)
  }
}
