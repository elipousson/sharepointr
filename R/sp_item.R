#' Get a SharePoint item based on a file URL or file name and site
#'
#' [get_sp_item()] is a helper for the `{Microsoft365R}` methods that makes it
#' easier to get an `ms_item` object based on a file URL.
#'
#' @keywords internal
#' @param file A SharePoint file URL or the relative path to a file located in a
#'   SharePoint drive. If file is a relative path, the string should *not*
#'   include the drive name. If file is a shared file URL, the text "Shared " is
#'   removed from the start of the SharePoint drive name by default. If file is
#'   a document URL, the `.default` argument is used as the drive_name and
#'   the `item_id` is extracted from the URL.
#' @param item_id A SharePoint item ID passed to the `itemid` parameter of the
#'   `get_item` method for `ms_drive` objects.
#' @param .default Default drive name string used only if file is a document URL.
#' @param drive A `ms_drive` object. If drive is supplied, `drive_name`,
#'   `site_url`, and any additional parameters passed to `...` are ignored.
#' @inheritParams get_sp_drive
#' @export
get_sp_item <- function(file = NULL,
                        item_id = NULL,
                        drive = NULL,
                        drive_name = NULL,
                        site_url = NULL,
                        ...,
                        .default = "Documents",
                        call = caller_env()) {
  if (is_url(file)) {
    if (is_sp_doc_url(file)) {
      sp_url <- sp_doc_url_parse(file)
      file <- NULL

      drive_name <- drive_name %||% .default
      stopifnot(is.null(item_id))
      item_id <- sp_url[["item_id"]]

      check_string(item_id, allow_empty = FALSE, call = call)
    } else {
      sp_url <- sp_site_url_parse(file)

      file <- paste0(sp_url[["path"]], "/", sp_url[["file"]])

      check_string(item_id, allow_empty = FALSE, call = call)

      drive_name <- drive_name %||% sp_url[["drive_name"]]
    }

    site_url <- site_url %||%
      sp_site_url_build(
        sp_url[["tenant"]],
        sp_url[["site_name"]]
      )
  }

  drive <- drive %||% get_sp_drive(
    site_url = site_url,
    drive_name = drive_name,
    ...,
    call = call
  )

  stopifnot(
    is_string(file) || is_string(item_id)
  )

  drive$get_item(path = file, itemid = item_id)
}

#' @rdname get_sp_item
#' @param drive_name,drive_id Passed to `get_drive` method for SharePoint site
#'   object.
#' @param site_url A SharePoint site URL in the format "https://<tenant
#'   name>.sharepoint.com/sites/<site name>". A SharePoint file or document URL
#'   will be parsed and a site URL built using the tenant and site name if
#'   found.
#' @param site A `ms_site` object. If site is supplied, `site_url` and any
#'   additional parameters passed to `...` are ignored.
#' @inheritParams rlang::args_error_context
#' @keywords internal
#' @export
get_sp_drive <- function(drive_name = NULL,
                         drive_id = NULL,
                         site_url = NULL,
                         site = NULL,
                         ...,
                         call = caller_env()) {
  site <- site %||% get_sp_site(site_url, ...)

  if (!is_string(drive_name) && !is_string(drive_id)) {
    cli_abort(
      "A {.arg drive_name} or {.arg drive_id} string must be supplied.",
      call = call
    )
  }

  site$get_drive(drive_name = drive_name, drive_id = drive_id)
}

#' @rdname get_sp_item
#' @inheritParams Microsoft365R::get_sharepoint_site
#' @keywords internal
#' @export
#' @importFrom Microsoft365R get_sharepoint_site
get_sp_site <- function(site_url = NULL,
                        ...,
                        call = caller_env()) {
  if (!is_sp_site_url(site_url)) {
    sp_url <- sp_site_url_parse(site_url)
    site_url <- sp_site_url_build(sp_url[["tenant"]], sp_url[["site_name"]])
  }

  check_url(site_url, call = call)

  Microsoft365R::get_sharepoint_site(site_url = site_url, ...)
}

#' Download one or more items from SharePoint to a file
#'
#' [download_sp_item()] wraps the `download` method for SharePoint items making
#' it easier to download items based on a shared file URL or document URL. The
#' default valye for `path` is `""` so, by default, SharePoint items are
#' downloaded to the current working directory. Set `overwrite = TRUE` to allow
#' this function to overwrite an existing file.
#'
#' @name download_sp_item
#' @param file Required. A SharePoint shared file URL, document URL, or, if
#'   `item_id` is supplied, a file name to use with `path` to set `dest` with
#'   location and filename for downloaded item.
#' @param path Path to directory for downloaded item. Optional if `dest` is
#'   supplied.
#' @inheritParams get_sp_item
#' @param path description
#' @param dest,overwrite,recursive,parallel Parameters passed to `download`
#'   method for `ms_item` object.
#' @export
download_sp_item <- function(file,
                             path = "",
                             drive_name = NULL,
                             drive_id = NULL,
                             site_url = NULL,
                             dest = NULL,
                             overwrite = FALSE,
                             recursive = FALSE,
                             parallel = FALSE,
                             ...,
                             call = caller_env()) {
  cli::cli_progress_step(
    "Getting item from SharePoint"
  )

  item <- get_sp_item(
    file = file,
    drive_name = drive_name,
    drive_id = drive_id,
    site_url = site_url,
    ...,
    call = call
  )

  dest <- dest %||% sp_file_dest(file, path = path)

  check_string(dest, call = call)

  cli::cli_progress_step(
    "Downloading SharePoint item to {.file {dest}}"
  )

  dest <- utils::URLencode(dest)

  item$download(
    dest = dest,
    overwrite = overwrite,
    recursive = recursive,
    parallel = parallel
  )

  invisible(dest)
}

#' Set a file destination for a SharePoint file before downloading
#'
#' @noRd
sp_file_dest <- function(file, path = tempdir(), fsep = .Platform$file.sep) {
  if (is_sp_site_url(file)) {
    file <- sp_site_url_parse(file)[["file"]]
  } else if (is_sp_doc_url(file)) {
    file <- sp_doc_url_parse(file)[["file"]]
  }

  file.path(path, basename(file), fsep = fsep)
}
