#' Get a SharePoint drive or set a default SharePoint drive
#'
#' @description
#' [get_sp_drive()] wraps the `get_drive` method returns a `ms_drive` object.
#'
#' [cache_sp_drive()] allows you to cache a default SharePoint drive for use by
#' other functions. Additional parameters in `...` are passed to
#' [get_sp_drive()].
#'
#' @name sp_drive
#' @seealso [Microsoft365R::ms_drive]
NULL

#' @rdname sp_drive
#' @name get_sp_drive
#' @param drive_name,drive_id SharePoint Drive name or ID passed to `get_drive`
#'   method for SharePoint site object.
#' @param drive_url A SharePoint Drive URL to parse for a Drive name and other
#'   information. If `drive_name` is a URL, it is used as `drive_url`.
#' @param properties If `TRUE`, return the drive properties instead of the
#'   `ms_drive` object. Defaults to `FALSE`.
#' @inheritParams sp_site
#' @inheritDotParams get_sp_site
#' @param default_drive_name Drive name string used only if input is a document
#'   URL and drive name is not part of the URL. Defaults to
#'   `getOption("sharepointr.default_drive_name", "Documents")`
#' @param cache If `TRUE`, cache drive to a file using [cache_sp_drive()].
#' @param refresh If `TRUE`, get a new drive even if the existing drive is
#'   cached as a local option. If `FALSE`, use the cached `ms_drive` object if
#'   it exists.
#' @export
get_sp_drive <- function(drive_name = NULL,
                         drive_id = NULL,
                         drive_url = NULL,
                         properties = FALSE,
                         ...,
                         site_url = NULL,
                         site = NULL,
                         default_drive_name = getOption(
                           "sharepointr.default_drive_name",
                           "Documents"
                         ),
                         cache = FALSE,
                         refresh = TRUE,
                         overwrite = FALSE,
                         cache_file = getOption(
                           "sharepointr.cache_file_drive",
                           "sp_drive.rds"
                         ),
                         call = caller_env()) {
  if (!refresh && sp_cache_file_exists(cache_file, call = call)) {
    drive <- withCallingHandlers(
      get_sp_cache(cache_file = cache_file, what = "ms_drive", call = call),
      warning = function(cnd) NULL,
      error = function(cnd) NULL
    )

    if (is_ms_drive(drive)) {
      return(drive)
    }

    refresh <- TRUE
  }

  if (!is.null(drive_name) && is_sp_url(drive_name)) {
    drive_url <- drive_name
    drive_name <- NULL
  }

  if (!is.null(drive_url)) {
    if (!is.null(drive_name)) {
      cli::cli_bullets(
        c("!" = "Any SharePoint Drive name contained in {.arg drive_url}
          is ignored if {.arg drive_name} is also supplied.")
      )
    }

    sp_url_parts <- sp_url_parse(drive_url, call = call)
    site_url <- site_url %||% sp_url_parts[["site_url"]]
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
    drive_id <- drive_id %||% sp_url_parts[["drive_id"]]

    if (is.null(drive_id)) {
      drive_name <- drive_name %||% default_drive_name
    }

    # FIXME: This is a work-around for incomplete URL parsing
    if (identical(drive_name, "Lists")) {
      drive_name <- default_drive_name
    }
  }

  site <- site %||% get_sp_site(
    site_url = site_url,
    ...,
    refresh = refresh,
    call = call
  )

  check_ms_site(site, call = call)

  check_exclusive_strings(drive_name, drive_id, call = call)

  drive <- site$get_drive(drive_name = drive_name, drive_id = drive_id)

  if (cache) {
    cache_sp_drive(
      drive = drive,
      cache_file = cache_file,
      overwrite = overwrite,
      call = call
    )
  }

  if (properties) {
    return(drive$properties)
  }

  drive
}

#' @rdname sp_drive
#' @name cache_sp_drive
#' @param drive description
#' @param drive A `ms_drive` object. If `drive` is supplied, `drive_name` and
#'   `drive_id` are ignored.
#' @param cache_file File name for cached drive if `cache = TRUE`. Defaults to a
#'   option set with `sharepointr.cache_file_drive` (which defaults to
#'   `"sp_drive.rds"`).
#' @inheritParams cache_ms_obj
#' @export
cache_sp_drive <- function(...,
                           drive = NULL,
                           cache_file = getOption(
                             "sharepointr.cache_file_drive",
                             "sp_drive.rds"
                           ),
                           overwrite = FALSE,
                           call = caller_env()) {
  drive <- drive %||% get_sp_drive(..., call = call)

  check_ms_drive(drive, call = call)

  cache_ms_obj(
    drive,
    cache_file = cache_file,
    overwrite = overwrite,
    what = "ms_drive",
    call = call
  )
}

#' List drives for a SharePoint site
#'
#' [list_sp_drives()] loads a SharePoint site uses the `list_drives` method to
#' returns a data frame with a list column or `ms_drive` objects or, if
#' `as_data_frame = FALSE`. This is helpful if a drive has been renamed and
#' can't easily be identified using a Drive URL alone.
#'
#' @seealso [Microsoft365R::ms_site]
#' @inheritDotParams get_sp_site
#' @param filter Filter to apply to query
#' @param n Max number of drives to return
#' @export
list_sp_drives <- function(
    ...,
    site = NULL,
    filter = NULL,
    n = NULL,
    as_data_frame = TRUE,
    call = caller_env()
) {
  sp_site <- site %||% get_sp_site(..., call = call)

  site_drives <- sp_site$list_drives(filter = filter, n = n %||% Inf)

  if (!as_data_frame) {
    return(site_drives)
  }

  # TODO: Move name column to the front
  ms_obj_list_as_data_frame(
    site_drives,
    obj_col = "ms_drive",
    keep_list_cols = c("lastModifiedBy", "createdBy"),
    .error_call = call
  )
}
