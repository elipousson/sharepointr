#' Get a SharePoint item
#'
#' @description
#' [get_sp_item()] wraps the `get_item` method for `ms_drive` objects and
#' returns a `ms_drive_item` object by default. Additional parameters in `...`
#' are passed to [get_sp_drive()].
#'
#' Use [get_sp_item_properties()] to get the item properties instead. Setting
#' `properties = TRUE` returns the same properties, but only
#' [get_sp_item_properties()] can include the document library column values
#' (fields) for the item.
#'
#' If `path` or `item_url` is a SharePoint URL for a file or folder (e.g. a
#' link from "Copy link" in SharePoint, a document URL, or a document library
#' URL) and `item_id`, `drive_name`, `drive_id`, and `drive` aren't supplied,
#' [get_sp_item()] gets the item with the [Microsoft Graph shares
#' API](https://learn.microsoft.com/en-us/graph/api/shares-get). This works for
#' items in any document library and for links to items that have been moved.
#' The Microsoft Graph login uses `site`, `site_url`, or the site in the URL.
#' If the shares API request fails, the site, drive, and path or item ID are
#' parsed from the URL instead.
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
#' @seealso [get_sp_item_properties()], [Microsoft365R::ms_drive_item]
#' @returns A `ms_drive_item` object (or a list of item properties if
#'   `properties = TRUE`), or a 1 row data frame if `as_data_frame = TRUE`.
#' @examples
#' sp_item_url <- "<SharePoint item url>"
#'
#' if (is_sp_url(sp_item_url)) {
#'   get_sp_item(
#'     item_url = sp_item_url
#'   )
#' }
#'
#' @keywords items
#' @export
get_sp_item <- function(
  path = NULL,
  item_id = NULL,
  item_url = NULL,
  ...,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  properties = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  if (is.null(drive)) {
    if (is_url(path)) {
      item_url <- path
      path <- NULL
    }

    # Use the Graph shares API to get the item from the URL. If the request
    # fails, fall back to the site, drive, and path or item ID parsed from the
    # URL.
    shares_cnd <- NULL

    if (
      is_null(c(item_id, drive_name, drive_id)) && is_sp_shares_url(item_url)
    ) {
      item <- try_fetch(
        sp_shares_get_item(item_url, ..., site_url = site_url, call = call),
        error = function(cnd) {
          shares_cnd <<- cnd
          NULL
        }
      )

      if (!is.null(item)) {
        return(sp_item_as_output(item, properties, as_data_frame, call = call))
      }
    }

    if (is_url(item_url)) {
      sp_url_parts <- try_fetch(
        sp_url_parse(url = item_url, call = call),
        error = function(cnd) {
          if (is.null(shares_cnd)) {
            cnd_signal(cnd)
          }

          cli_abort(
            "Can't get a SharePoint item from {.url {item_url}}.",
            parent = shares_cnd,
            call = call
          )
        }
      )

      if (is_null(item_id) && is_null(sp_url_parts[["item_id"]])) {
        path <- sp_url_parts[["file_path"]]
      }

      drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
      item_id <- item_id %||% sp_url_parts[["item_id"]]
      site_url <- site_url %||% sp_url_parts[["site_url"]]
    }
  }

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
  check_exclusive_strings(path, item_id, call = call)

  item <- drive$get_item(path = path, itemid = item_id)

  sp_item_as_output(item, properties, as_data_frame, call = call)
}

#' Return a drive item, its properties, or a data frame
#'
#' @returns `item`, `item$properties` if `properties = TRUE`, or a 1 row data
#'   frame if `as_data_frame = TRUE`.
#' @noRd
sp_item_as_output <- function(
  item,
  properties = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  if (properties) {
    item_properties <- item$properties

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

#' Get or update the properties of a SharePoint file or folder
#'
#' @description
#' [get_sp_item_properties()] gets the properties of a file or folder, such as
#' the name, size, and creation date. Set `fields = TRUE` to also get the
#' values of the document library columns (fields) for the item. To get the
#' fields for many items, use [get_sp_list()] to get the document library as a
#' list and use [list_sp_list_items()] or [get_sp_list_item()] instead.
#'
#' `r lifecycle::badge("experimental")`
#'
#' [update_sp_item_properties()] renames a file or folder or updates the values
#' of document library columns for the item. Field values are updated with
#' [update_sp_list_item()] using the list for the document library, so the
#' same field name checks and formatting (e.g. for multi-choice columns) are
#' used. To move an item to another folder, use [sp_item_move()] instead.
#'
#' @inheritParams get_sp_item
#' @param ... For [get_sp_item_properties()], additional parameters passed to
#'   [get_sp_drive()]. For [update_sp_item_properties()], named field values to
#'   update, e.g. `Title = "Annual report"`. Names can be column names or
#'   display names. Ignored if `.data` is supplied.
#' @param fields If `TRUE`, add a `fields` element with the document library
#'   column values for the item (a named list). The `id` field is the list
#'   item id (not the drive item id). If `as_data_frame = TRUE`, `fields` is a
#'   list column with a 1 row data frame of the field values (use
#'   `tidyr::unnest(data, fields, names_sep = "_")` to add the fields as
#'   columns). Defaults to `FALSE`. Fields are only available for items in a
#'   SharePoint document library.
#' @param as_data_frame If `TRUE`, return a 1 row data frame. If `FALSE`
#'   (default), return a list of item properties.
#' @param .data A named list or a single row data frame with field values to
#'   update. Optional.
#' @param name A new name for the item. Optional. `name` must not include a
#'   folder path. An error is returned if an item with the same name already
#'   exists in the folder.
#' @param item A `ms_drive_item` object. If `item` is supplied, `path`,
#'   `item_id`, `item_url`, and the drive arguments are ignored.
#' @inheritParams update_sp_list_item
#' @returns A list of item properties, or a 1 row data frame if
#'   `as_data_frame = TRUE`. [update_sp_item_properties()] returns the
#'   properties after the update.
#' @seealso [get_sp_item()], [get_sp_list_item()]
#' @examples
#' sp_item_url <- "<SharePoint item url>"
#'
#' if (is_sp_url(sp_item_url)) {
#'   get_sp_item_properties(sp_item_url, fields = TRUE)
#'
#'   update_sp_item_properties(
#'     sp_item_url,
#'     Title = "Annual report",
#'     name = "annual-report-2026.docx"
#'   )
#' }
#'
#' @name sp_item_properties
#' @keywords items
NULL

#' @rdname sp_item_properties
#' @export
get_sp_item_properties <- function(
  path = NULL,
  item_id = NULL,
  item_url = NULL,
  ...,
  drive = NULL,
  drive_name = NULL,
  drive_id = NULL,
  site_url = NULL,
  fields = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  check_bool(fields, call = call)

  if (!fields) {
    return(
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
    )
  }

  item <- get_sp_item(
    path = path,
    item_id = item_id,
    item_url = item_url,
    ...,
    drive = drive,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    call = call
  )

  sp_item_properties_output(
    item,
    fields = fields,
    as_data_frame = as_data_frame,
    call = call
  )
}

#' Get the properties of a drive item, optionally with field values
#'
#' @returns A list of item properties or a 1 row data frame. If `fields =
#'   TRUE`, a `fields` element is added (a named list or, for a data frame, a
#'   list column with a 1 row data frame).
#' @noRd
sp_item_properties_output <- function(
  item,
  fields = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  item_properties <- item[["properties"]]

  if (fields) {
    item_properties[["fields"]] <- sp_drive_item_fields(item, call = call)
  }

  if (!as_data_frame) {
    return(item_properties)
  }

  item_properties_df <- ms_obj_as_data_frame(
    item_properties,
    obj_col = "ms_item_properties",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
  )

  if (fields) {
    fields_df <- ms_obj_as_data_frame(
      item_properties[["fields"]],
      obj_col = ".fields",
      .error_call = call
    )

    fields_df[[".fields"]] <- NULL
    item_properties_df[["fields"]] <- list(fields_df)
  }

  item_properties_df
}

#' Get the document library field values for a drive item
#'
#' @returns A named list of field values without the `"@odata"` annotations.
#' @noRd
sp_drive_item_fields <- function(item, call = caller_env()) {
  item_fields <- tryCatch(
    item$do_operation("listItem/fields"),
    error = function(cnd) {
      cli_abort(
        c(
          "Can't get fields for {.val {item[['properties']][['name']]}}.",
          "i" = "Fields are only available for items in a SharePoint document
          library."
        ),
        parent = cnd,
        call = call
      )
    }
  )

  attr(item_fields, "status") <- NULL

  item_fields[!startsWith(names(item_fields), "@odata.")]
}

#' @rdname sp_item_properties
#' @export
update_sp_item_properties <- function(
  path = NULL,
  ...,
  .data = NULL,
  name = NULL,
  item_id = NULL,
  item_url = NULL,
  item = NULL,
  check_fields = TRUE,
  na_fields = c("drop", "replace"),
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  fields = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  .data <- .data %||% list2(...)
  check_bool(fields, call = call)
  check_string(name, allow_null = TRUE, call = call)
  check_bool(as_data_frame, call = call)

  if (is_empty(.data) && is.null(name)) {
    cli_abort(
      "Field values (with {.arg ...} or {.arg .data}) or {.arg name} must be
      supplied.",
      call = call
    )
  }

  if (!is.null(name) && (!nzchar(name) || grepl("/", name, fixed = TRUE))) {
    cli_abort(
      c(
        "{.arg name} must be a name without a folder path.",
        "i" = "Use {.fn sp_item_move} to move an item to another folder."
      ),
      call = call
    )
  }

  item <- item %||%
    get_sp_item(
      path = path,
      item_id = item_id,
      item_url = item_url,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      site_url = site_url,
      call = call
    )

  check_ms_obj(item, "ms_drive_item", call = call)

  if (!is_empty(.data)) {
    update_sp_list_item(
      .data = .data,
      item_id = sp_drive_item_list_item_id(item, call = call),
      sp_list = sp_drive_item_list(item),
      check_fields = check_fields,
      na_fields = na_fields,
      call = call
    )
  }

  if (!is.null(name)) {
    resp <- item$do_operation(
      body = list(name = name),
      encode = "json",
      http_verb = "PATCH",
      options = sp_conflict_option(FALSE),
      http_status_handler = "pass"
    )

    check_sp_transfer_response(resp, item, "rename", call = call)
  }

  item$sync_fields()

  sp_item_properties_output(
    item,
    fields = fields,
    as_data_frame = as_data_frame,
    call = call
  )
}

#' Get the list item id for a drive item
#' @noRd
sp_drive_item_list_item_id <- function(item, call = caller_env()) {
  list_item <- tryCatch(
    item$do_operation("listItem", options = list(`$select` = "id")),
    error = function(cnd) {
      cli_abort(
        c(
          "Can't update fields for {.val {item[['properties']][['name']]}}.",
          "i" = "Fields can only be updated for items in a SharePoint document
          library."
        ),
        parent = cnd,
        call = call
      )
    }
  )

  list_item[["id"]]
}

#' Get the document library list for a drive item
#' @noRd
sp_drive_item_list <- function(item) {
  drive_id <- item[["properties"]][["parentReference"]][["driveId"]]

  Microsoft365R::ms_list$new(
    item[["token"]],
    item[["tenant"]],
    AzureGraph::call_graph_endpoint(
      item[["token"]],
      file.path("drives", drive_id, "list")
    )
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
#' @returns Invisibly returns `NULL`.
#' @keywords items
#' @export
delete_sp_item <- function(
  path = NULL,
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
  call = caller_env()
) {
  item <- item %||%
    get_sp_item(
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
#' `dest` can be inferred from the item properties. If `{carrier}` and
#' `{mirai}` are installed and [mirai::daemons()] are set, items are downloaded
#' in parallel. The `parallel` argument is separate: it is passed to the
#' `download` method to download the contents of a folder in parallel.
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
#' @keywords items
#' @export
download_sp_item <- function(
  path = NULL,
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
  call = caller_env()
) {
  # Check if item requires a batch download approach
  is_batch_item <- (length(path) > 1) ||
    (length(item_id) > 1) ||
    (is_bare_list(item) && (length(item) > 1))

  if (is_batch_item) {
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

  item <- item %||%
    get_sp_item(
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

  check_ms_obj(item, "ms_drive_item", call = call)

  # FIXME: Take a closer look at why this is needed
  if ((new_path == "") || is.null(new_path)) {
    if (is_empty(dest) || dest == "") {
      dest <- NULL
    }

    # dest defaults to the SharePoint item name
    dest <- dest %||% item[["properties"]][["name"]]
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
  item_is_folder <- item$is_folder()

  # Append file name to dest path if dest is a folder
  # TODO: Consider if this should trigger a warning
  # FIXME: This doesn't work if dest is a nonexistent folder
  if (fs::is_dir(dest) && !item_is_folder) {
    dest_dir <- dest
    dest <- fs::path(dest, item[["properties"]][["name"]])
  } else {
    dest_dir <- fs::path_dir(dest)
  }

  dest_dir_exists <- fs::dir_exists(dest_dir)

  # Validate parameters for folder items
  if (item_is_folder) {
    if (!dest_dir_exists) {
      # TODO: Consider if this requirement is necessary
      cli::cli_abort(
        c(
          "{.arg new_path} or {.arg dest} must exist if item is a folder.",
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
    # Create destination directory
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
download_sp_file <- function(file, new_path = "", ..., call = caller_env()) {
  download_sp_item(
    path = file,
    new_path = new_path,
    ...,
    call = call
  )
}

#' Set a file destination for a SharePoint file before downloading
#'
#' @returns A string combining `path` with the basename of `file` (parsed
#'   from a SharePoint URL if needed).
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

#' @returns Invisibly returns a character vector of destination paths, one
#'   per downloaded item.
#' @noRd
batch_download_sp_item <- function(
  path = NULL,
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
  call = caller_env()
) {
  # TODO: Should a list of item values just be unlists
  if (is_bare_list(item)) {
    size <- length(item)
    # A NULL dest is set from the properties of each item
    dest <- dest %||% rep(list(NULL), size)
  } else {
    size <- max(c(length(path), length(item_id)))

    if (is.null(dest)) {
      dest <- vctrs::vec_recycle(
        new_path,
        size,
        x_arg = "new_path",
        call = call
      )
    } else {
      dest <- vctrs::vec_recycle(dest, size, x_arg = "dest", call = call)
    }
  }

  if (length(path) > 1) {
    arg <- "path"
    values <- path
  } else if (length(item_id) > 1) {
    arg <- "item_id"
    values <- item_id
  } else {
    arg <- "item"
    values <- item
  }

  # Get the drive once (instead of for each item) unless items are found from
  # URLs (which may each refer to a different drive)
  if (is.null(drive) && arg != "item" && !any(is_url(path))) {
    drive <- get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      site_url = site_url,
      call = call
    )
  }

  dest_list <- purrr::map2_chr(
    values,
    dest,
    sp_in_parallel(
      \(x, y) {
        do.call(
          fn,
          c(
            rlang::set_names(list(x), arg),
            list(
              dest = y,
              new_path = new_path,
              drive_name = drive_name,
              drive_id = drive_id,
              drive = drive,
              site_url = site_url,
              overwrite = overwrite,
              recursive = recursive,
              parallel = parallel
            ),
            dots
          )
        )
      },
      fn = download_sp_item,
      arg = arg,
      dots = list2(...),
      new_path = new_path,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      site_url = site_url,
      overwrite = overwrite,
      recursive = recursive,
      parallel = parallel
    )
  )

  invisible(dest_list)
}

#' Download a SharePoint List
#'
#' [download_sp_list()] downloads a SharePoint list to a CSV or XLSX file.
#' `keep_list_cols` is intended to allow the preservation of list columns but it
#'  is not yet supported.
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
#' @returns Invisibly returns the path to the downloaded file.
#' @export
download_sp_list <- function(
  ...,
  new_path = "",
  sp_list = NULL,
  fileext = "csv",
  keep_list_cols = c("createdBy", "lastModifiedBy"),
  call = caller_env()
) {
  sp_list_df <- list_sp_list_items(
    sp_list = sp_list,
    ...
  )

  # FIXME: This is not working as expected
  for (col in keep_list_cols) {
    sp_list_df <- fmt_sp_list_col(sp_list_df, col = col)
  }

  if (new_path == "") {
    new_path <- NULL
  }

  list_filename <- paste0(sp_list[["properties"]][["name"]], ".", fileext)

  if (is_installed("fs")) {
    list_filename <- fs::path_sanitize(list_filename)
  }

  new_path <- new_path %||% list_filename

  # TODO: Add option to write list directly to Google Sheets
  if (stringr::str_detect(new_path, "\\.csv$")) {
    check_installed("readr", call = call)
    readr::write_csv(sp_list_df, file = new_path)
  } else if (stringr::str_detect(new_path, "\\.xlsx$")) {
    check_installed("openxlsx2", call = call)
    openxlsx2::write_xlsx(sp_list_df, file = new_path)
  }

  return(invisible(new_path))
}
