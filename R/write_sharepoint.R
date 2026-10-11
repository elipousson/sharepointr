#' @returns A string combining the file path parsed from `url` with the
#'   basename of `src`.
#' @noRd
sp_url_as_src_dest <- function(url, src, call = caller_env()) {
  sp_url_parts <- sp_url_parse(url, call = call)
  file_path <- str_remove_slash(sp_url_parts[["file_path"]])
  str_c_url(file_path, basename(src))
}

#' Write an object to file and upload file to SharePoint
#'
#' @description
#' [write_sharepoint()] uses [upload_sp_item()] to upload an object created
#' using:
#'
#' - [sf::write_sf()] if x is an `sf` object (shapefiles are not supported)
#' - [readr::write_csv()] if x is a `data.frame` and file does not have a xlsx extension
#' - [openxlsx2::write_xlsx()] if x is a `data.frame` and file has a xlsx extension
#' - The [print()] method from `{officer}` if x is a `rdocx`, `rpptx`, or `rxlsx` object
#' - [readr::write_rds()] if x is any other class
#'
#' @param x Object to write to file and upload to SharePoint. `sf`, `rdocx`,
#'   `rpptx`, `rxlsx`, and `data.frame` objects are saved with the functions
#'   noted in the description. All other object types are saved as `rds`
#'   outputs.
#' @param file File to write to. Passed to `file` parameter for
#'   [readr::write_csv()] or [readr::write_rds()], `dsn` for `sf::write_sf()`,
#'   or `target` for `print()` (when working with `{officer}` class objects).
#'   A shapefile writes more than one file, so `file` can't use a "shp"
#'   extension for `sf` objects. Use a single file format like GeoPackage
#'   ("gpkg") or GeoJSON ("geojson") instead.
#' @param .f Optional function to write the input data to disk before uploading
#'   file to SharePoint.
#' @param ... Additional parameters passed to write function.
#' @param new_path Path to write file to. Defaults to [tempdir()]
#' @param blocksize Additional parameter passed to `upload_folder` or
#'   `upload_file` method for `ms_drive` objects.
#' @inheritParams upload_sp_item
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_site
#' @returns Invisibly returns the input object x.
#' @export
write_sharepoint <- function(
  x,
  file,
  dest = NULL,
  ...,
  .f = NULL,
  new_path = tempdir(),
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  site = NULL,
  blocksize = 327680000,
  call = caller_env()
) {
  check_string(file, call = call)
  file <- str_c_fsep(new_path, file)
  file_ext <- tolower(fs::path_ext(file))

  if (!is.null(.f)) {
    .f <- as_function(.f, call = call)
    .f(x, file, ...)
  } else if (inherits(x, "sf")) {
    if (file_ext == "shp") {
      cli_abort(
        c(
          "{.arg file} can't be a shapefile.",
          "i" = "Use a single file format like GeoPackage ({.file .gpkg}) or
          GeoJSON ({.file .geojson}) instead."
        ),
        call = call
      )
    }

    check_installed("sf", call = call)
    sf::write_sf(x, dsn = file, ...)
  } else if (inherits(x, "data.frame") && file_ext == "xlsx") {
    check_installed("openxlsx2", call = call)
    openxlsx2::write_xlsx(x, file = file, ...)
  } else if (inherits(x, "data.frame")) {
    check_installed("readr", call = call)
    readr::write_csv(x, file = file, ...)
  } else if (inherits(x, c("rdocx", "rpptx", "rxlsx"))) {
    check_installed("officer", call = call)
    print(x, target = file, ...)
  } else {
    check_installed("readr", call = call)
    readr::write_rds(x, file = file, ...)
  }

  # TODO: Explore if write_sharepoint should include support for creating list
  # items comparable to read_sharepoint support for ms_list objects and list URLs

  upload_sp_item(
    file = file,
    dest = dest,
    overwrite = overwrite,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    site = site,
    blocksize = blocksize,
    call = call
  )

  invisible(x)
}

#' Upload a file or folder to a SharePoint Drive
#'
#' [upload_sp_item()] wraps the `upload_folder` and `upload_file` method for
#' `ms_drive` objects.
#'
#' @name upload_sp_item
#' @param file Path for file or directory to upload. Optional if `src` is
#'   supplied.
#' @param dest Destination on SharePoint for file to upload. Must be a
#'  `ms_drive_item` for a folder, a SharePoint folder URL, or a drive path. If a
#'  `ms_drive_item` is provided and `drive_name` is `NULL`, the item URL is
#'  used to determine the drive. If `NULL`, the top level of the provided drive
#'  is used as the destination. If file is a directory, `dest` must be an
#'  *existing* directory. If `dest` is a SharePoint folder or document library
#'  URL and `drive_name`, `drive_id`, and `drive` aren't supplied, the drive and
#'  folder are found with the [Microsoft Graph shares
#'  API](https://learn.microsoft.com/en-us/graph/api/shares-get) (see
#'  [get_sp_item()]). If the request fails, the drive and folder path are parsed
#'  from the URL instead. For [upload_sp_items()], `dest` can also be a
#'  character vector with one destination for each file. Destinations can be
#'  in different drives.
#' @param src Data source path passed to `upload_folder` or `upload_file`
#'   method. Defaults to `NULL` and set to use file value by default.
#' @param overwrite If `FALSE` (default), error if an item with the name
#'   specified in `file` or `src` already exists at the specified destination.
#'   If `TRUE`, overwrite any existing items with the same name. The latter is
#'   the default for the `upload_file` method.
#' @inheritParams get_sp_item
#' @inheritParams get_sp_drive
#' @param blocksize,recursive,parallel Additional parameters passed to
#'   `upload_folder` or `upload_file` method for `ms_drive` objects.
#' @returns Invisibly returns the destination path (`dest`) for the uploaded
#'   file or directory.
#' @export
upload_sp_item <- function(
  file = NULL,
  dest = NULL,
  ...,
  src = NULL,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
) {
  if (!is_string(src) && !is_string(file)) {
    cli_abort(
      "One of {.arg file} or {.arg src} must be a string.",
      call = call
    )
  } else if (!is_string(src)) {
    src <- file
  }

  # NOTE: This is duplicative with a check in the `upload_sp_src` internal
  # function
  if (!fs::file_exists(src) && !fs::dir_exists(src)) {
    cli_abort(
      "{.arg file} or {.arg src} does not exist.",
      call = call
    )
  }

  sp_dest <- sp_upload_dest(
    dest,
    ...,
    overwrite = overwrite,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  upload_sp_dest(
    src = src,
    sp_dest = sp_dest,
    blocksize = blocksize,
    recursive = recursive,
    parallel = parallel,
    call = call
  )
}

#' @rdname upload_sp_item
#' @export
upload_sp_items <- function(
  file = NULL,
  dest,
  ...,
  src = NULL,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
) {
  if (!is_character(src) && !is_character(file)) {
    cli_abort(
      "One of {.arg file} or {.arg src} must be a character vector",
      call = call
    )
  } else if (!is_character(src)) {
    src <- file
  }

  check_character(src, call = call)

  if (is_ms_drive_item(dest, TRUE)) {
    dest <- list(dest)
  } else {
    check_character(dest, call = call)
  }

  dest <- vctrs::vec_recycle(dest, size = length(src), call = call)

  # Get the drive and folder once for each unique destination, so files can be
  # uploaded to folders in different drives
  unique_dest <- unique(dest)
  sp_dest_list <- purrr::map(
    unique_dest,
    \(x) {
      sp_upload_dest(
        x,
        ...,
        overwrite = overwrite,
        drive_name = drive_name,
        drive_id = drive_id,
        drive = drive,
        call = call
      )
    }
  )

  # TODO: Implement parallel option w/ in_parallel
  dest_list <- purrr::map2_chr(
    src,
    sp_dest_list[match(dest, unique_dest)],
    \(x, y) {
      upload_sp_dest(
        src = x,
        sp_dest = y,
        blocksize = blocksize,
        recursive = recursive,
        parallel = parallel,
        call = call
      )
    }
  )

  invisible(dest_list)
}

#' Get the drive and destination path for an upload
#'
#' @param dest A `ms_drive_item` for a folder, a SharePoint folder URL, a drive
#'   path, or `NULL` for the drive root.
#' @param overwrite If `FALSE`, list the names of existing items in the
#'   destination folder, so they only need to be listed once for each `dest`.
#' @returns A list with `drive` (a `ms_drive` object), `file_path` (the
#'   destination folder or file path), `dest` (the destination path, or
#'   `NULL` if the destination is a folder URL and the uploaded item name must
#'   be added to `file_path`), and `existing` (names of existing items in the
#'   destination folder, or `NULL` if `overwrite = TRUE`).
#' @noRd
sp_upload_dest <- function(
  dest = NULL,
  ...,
  overwrite = FALSE,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  file_path <- NULL

  if (is_ms_drive_item(dest, TRUE)) {
    file_path <- dest$get_path()
    drive_name <- drive_name %||% dest$properties$webUrl
    dest <- file_path
  }

  if (is_sp_url(dest)) {
    # Use the Graph shares API to get the drive and folder path from the URL.
    # If the request fails, fall back to the drive and path parsed from the URL.
    folder <- sp_url_get_folder(
      dest,
      ...,
      shares = is.null(c(drive_name, drive_id)) && is.null(drive),
      arg = "dest",
      call = call
    )

    drive <- drive %||% folder[["drive"]]
    drive_name <- folder[["drive_name"]]
    file_path <- folder[["path"]]
    dest <- NULL
  } else {
    # Assume `dest` is a file path if it's not a SharePoint URL
    dest <- dest %||% ""

    if (!is_string(dest)) {
      cli_abort(
        "{.arg dest} must be a SharePoint folder URL, a file path,
        a path to an existing SharePoint folder, or a {.cls ms_drive_item} object.",
        call = call
      )
    }

    file_path <- file_path %||% dest
  }

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      call = call
    )

  check_ms_drive(drive, call = call)

  existing <- NULL

  if (!overwrite) {
    existing <- sp_dir_info(
      drive = drive,
      path = sp_dest_dir(file_path),
      info = "name",
      full_names = FALSE,
      call = call
    )
  }

  list(drive = drive, file_path = file_path, dest = dest, existing = existing)
}

#' Get the folder path for a destination file or folder path
#' @noRd
sp_dest_dir <- function(file_path) {
  # TODO: Check congruence between src file extension and destination file extension
  if (fs::path_ext(file_path) != "") {
    return(fs::path_dir(file_path))
  }

  file_path
}

#' Upload a file or folder to a destination from `sp_upload_dest()`
#'
#' @param sp_dest A list from `sp_upload_dest()`.
#' @returns Invisibly returns the destination path. Errors if an item with the
#'   same name is in `sp_dest$existing`.
#' @noRd
upload_sp_dest <- function(
  src,
  sp_dest,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  call = caller_env()
) {
  drive <- sp_dest[["drive"]]
  file_path <- sp_dest[["file_path"]]
  dest <- sp_dest[["dest"]] %||% str_c_url(file_path, basename(src))

  overwrite_file <- fs::path_file(src)
  if (fs::path_ext(file_path) != "") {
    overwrite_file <- fs::path_file(file_path)
  }

  if (overwrite_file %in% sp_dest[["existing"]]) {
    cli_abort(
      c(
        # TODO: Replace {.arg dest} w/ {.path {sp_dest_dir(file_path)}}
        "{.file {overwrite_file}} already exists on SharePoint drive at {.arg dest}",
        "i" = "Set {.code overwrite = TRUE} to replace the existing item."
      ),
      call = call
    )
  }

  upload_sp_src(
    src = src,
    dest = dest,
    drive = drive,
    blocksize = blocksize,
    recursive = recursive,
    parallel = parallel,
    call = call
  )
}

#' @returns Invisibly returns `dest`. Errors if `src` is not an existing file
#'   or directory.
#' @noRd
upload_sp_src <- function(
  src,
  dest = NULL,
  drive = NULL,
  blocksize = 327680000,
  recursive = FALSE,
  parallel = FALSE,
  overwrite = FALSE,
  call = caller_env()
) {
  if (stringr::str_detect(dest, "^/")) {
    dest <- str_remove_slash(dest)
  }

  if (fs::dir_exists(src)) {
    cli_progress_step(
      msg = "Uploading directory to SharePoint drive",
      msg_done = "Directory upload complete"
    )

    # TODO: Add support for folder uploads when `dest` does not yet exist
    drive$upload_folder(
      src = src,
      dest = dest,
      blocksize = blocksize,
      recursive = recursive,
      parallel = parallel
    )

    return(invisible(dest))
  }

  if (fs::file_exists(src)) {
    cli_progress_step(
      msg = "Uploading file {.file {basename(src)}} to SharePoint drive",
      msg_done = "File upload complete"
    )

    if (dest == "") {
      dest <- fs::path_file(src)
    } else if (fs::path_ext(dest) == "") {
      dest <- fs::path(dest, fs::path_file(src))
    }

    drive$upload_file(
      src = src,
      blocksize = blocksize,
      dest = dest
    )

    return(invisible(dest))
  }

  cli_abort(
    "{.arg file} or {.arg src} must be an existing file or directory",
    call = call
  )
}
