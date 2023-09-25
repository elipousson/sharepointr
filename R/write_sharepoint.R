#' Write an object to file and upload file to SharePoint
#'
#' @description
#' [write_sharepoint()] uses [upload_sp_item()] to upload an object created
#' using:
#'
#' - [sf::write_sf()] if x is an `sf` object
#' - [readr::write_csv()] if x is a `data.frame`
#' - The [print()] method from `{officer}` if x is a `rdocx`, `rpptx`, or `rxlsx` object
#' - [readr::write_rds()] if x is any other class
#'
#' @param x Object to write to file and upload to SharePoint.
#' @param ... Additional parameters passed to write function.
#' @param new_path Path to write file to. Defaults to [tempdir()]
#' @inheritParams upload_sp_item
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_site
#' @export
write_sharepoint <- function(x,
                             file,
                             dest,
                             ...,
                             new_path = tempdir(),
                             drive_name = NULL,
                             drive_id = NULL,
                             drive = NULL,
                             site_url = NULL,
                             site_name = NULL,
                             site_id = NULL,
                             site = NULL,
                             blocksize = 327680000,
                             recursive = FALSE,
                             parallel = FALSE,
                             call = caller_env()) {
  check_string(file, call = call)
  file <- str_c_fsep(new_path, file)

  if (inherits(x, "sf")) {
    check_installed("sf", call = call)
    sf::write_sf(x, file, ...)
  } else if (inherits(x, "data.frame")) {
    check_installed("readr", call = call)
    readr::write_csv(x, file, ...)
  } else if (inherits(x, c("rdocx", "rpptx", "rxslx"))) {
    check_installed("officer", call = call)
    print(x, target = file, ...)
  } else {
    check_installed("readr")
    readr::write_rds(x, file, ...)
  }

  upload_sp_item(
    file = file,
    dest = dest,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    site = site,
    blocksize = blocksize,
    recursive = recursive,
    parallel = parallel,
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
#' @inheritParams get_sp_drive
#' @param blocksize,recursive,parallel Additional parameters passed to
#'   `upload_folder` or `upload_file` method for `ms_drive` objects.
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @export
upload_sp_item <- function(file = NULL,
                           dest,
                           ...,
                           src = NULL,
                           drive_name = NULL,
                           drive_id = NULL,
                           drive = NULL,
                           overwrite = FALSE,
                           blocksize = 327680000,
                           recursive = FALSE,
                           parallel = FALSE,
                           call = caller_env()) {
  if (!is_string(file) && !is_string(src)) {
    cli_abort(
      "{.arg file} or {.arg src} must be supplied",
      call = call
    )
  }

  src <- src %||% file

  if (is_sp_url(dest)) {
    url <- dest

    sp_url_parts <- sp_url_parse(url, call = call)
    file_path <- sp_url_parts[["file_path"]] |>
      str_remove_slash()

    dest <- str_c_url(file_path, basename(src))
    drive_name <- url
  }

  drive <- drive %||%
    get_sp_drive(
      drive_name = drive_name,
      drive_id = drive_id,
      ...,
      call = call
    )

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

  check_ms_drive(drive, call = call)

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
  } else if (file.exists(src)) {
    cli_progress_step(
      msg = "Uploading file {.file {basename(src)}} to SharePoint drive",
      msg_done = "File upload complete"
    )

    drive$upload_file(
      src = src,
      blocksize = blocksize,
      dest = dest
    )
  } else {
    cli_abort(
      "{.arg file} or {.arg src} must be an existing file or directory",
      call = call
    )
  }

  invisible(dest)
}
