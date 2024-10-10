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
#' - [sf::write_sf()] if x is an `sf` object
#' - [readr::write_csv()] if x is a `data.frame` and file does not include a xlsx extension
#' - [openxlsx2::write_xlsx()] if x is a `data.frame` file does include a xlsx extension
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
write_sharepoint <- function(x,
                             file,
                             dest,
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
                             call = caller_env()) {
  check_string(file, call = call)
  file <- str_c_fsep(new_path, file)

  if (!is.null(.f)) {
    .f <- as_function(.f, call = call)
    .f(x, file, ...)
  } else if (inherits(x, "sf")) {
    check_installed("sf", call = call)
    sf::write_sf(x, dsn = file, ...)
  } else if (inherits(x, "data.frame") && !stringr::str_detect(file, ".xlsx$")) {
    check_installed("readr", call = call)
    readr::write_csv(x, file = file, ...)
  } else if (inherits(x, "data.frame") && stringr::str_detect(file, ".xlsx$")) {
    check_installed("openxlsx2", call = call)
    openxlsx2::write_xlsx(x, file = file, ...)
  } else if (inherits(x, c("rdocx", "rpptx", "rxslx"))) {
    check_installed("officer", call = call)
    print(x, target = file, ...)
  } else {
    check_installed("readr", call = call)
    readr::write_rds(x, file = file, ...)
  }

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
#' @param dest Destination on SharePoint for file to upload. SharePoint folder
#'   URLs are supported.
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
#' @export
upload_sp_item <- function(file = NULL,
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
                           call = caller_env()) {
  if (!is_string(src) && !is_string(file)) {
    cli_abort(
      "One of {.arg file} or {.arg src} must be a string.",
      call = call
    )
  } else if (!is_string(src)) {
    src <- file
  }

  if (is_sp_url(dest)) {
    url <- dest

    sp_url_parts <- sp_url_parse(url, call = call)
    file_path <- sp_url_parts[["file_path"]] |>
      str_remove_slash()

    dest <- str_c_url(file_path, basename(src))
    drive_name <- url
  }

  check_string(dest, allow_empty = FALSE, call = call)

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      call = call
    )

  check_ms_drive(drive, call = call)

  if (!overwrite) {
    file_list <- sp_dir_info(drive = drive, path = file_path, call = call)

    if (basename(src) %in% file_list[["name"]]) {
      cli_abort(
        c(
          "{.file {basename(src)}} already exists on SharePoint drive at {.arg dest}",
          "i" = "Set {.code overwrite = TRUE} to replace the existing item."
        ),
        call = call
      )
    }
  }

  upload_sp_src(
    src = src,
    dest = dest,
    drive = drive,
    overwrite = overwrite,
    blocksize = blocksize,
    recursive = recursive,
    parallel = parallel,
    call = call
  )
}

#' @rdname upload_sp_item
#' @export
upload_sp_items <- function(file = NULL,
                            dest,
                            ...,
                            src = NULL,
                            call = caller_env()) {
  if (!is_character(src) && !is_character(file)) {
    cli_abort(
      "One of {.arg file} or {.arg src} must be a character vector",
      call = call
    )
  } else if (!is_character(src)) {
    src <- file
  }

  check_character(src, call = call)

  if (is_url(dest) && has_length(dest, 1)) {
    dest <- map_chr(
      src,
      \(x) {
        sp_url_as_src_dest(
          url = dest,
          src = x
        )
      }
    )
  }

  dest <- vctrs::vec_recycle(
    dest,
    size = length(src)
  )

  dest_list <- map2_chr(
    src, dest,
    \(x, y) {
      upload_sp_src(
        src = x,
        dest = y,
        ...,
        call = call
      )
    }
  )

  invisible(dest_list)
}

#' @noRd
upload_sp_src <- function(src,
                          dest = NULL,
                          drive = NULL,
                          blocksize = 327680000,
                          recursive = FALSE,
                          parallel = FALSE,
                          overwrite = FALSE,
                          call = caller_env()) {
  if (dir.exists(src)) {
    cli_progress_step(
      msg = "Uploading directory to SharePoint drive",
      msg_done = "Directory upload complete"
    )

    drive$upload_folder(
      src = src,
      dest = dest,
      blocksize = blocksize,
      recursive = recursive,
      parallel = parallel
    )

    return(invisible(dest))
  }

  if (file.exists(src)) {
    cli_progress_step(
      msg = "Uploading file {.file {basename(src)}} to SharePoint drive",
      msg_done = "File upload complete"
    )

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
