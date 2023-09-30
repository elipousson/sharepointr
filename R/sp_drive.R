#' Get a SharePoint drive or set a default SharePoint drive
#'
#' @description
#' [get_sp_drive()] wraps the `get_drive` method returns a `ms_drive` object.
#'
#' [set_sp_drive()] allows you to set a default SharePoint drive for use by
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
#' @inheritParams sp_site
#' @inheritDotParams get_sp_site
#' @param .default_drive_name Drive name string used only if input is a document
#'   URL and drive name is not part of the URL. Defaults to
#'   `getOption("sharepointr.default_drive_name", "Documents")`
#' @param properties If `TRUE`, return the drive properties instead of the
#'   `ms_drive` object.
#' @export
get_sp_drive <- function(drive_name = NULL,
                         drive_id = NULL,
                         ...,
                         site_url = NULL,
                         site = NULL,
                         .default_drive_name = getOption(
                           "sharepointr.default_drive_name",
                           "Documents"
                         ),
                         properties = FALSE,
                         call = caller_env()) {
  if (is_ms_drive(getOption("sharepointr.default_drive"))) {
    return(getOption("sharepointr.default_drive"))
  }

  if (!is.null(drive_name) && is_sp_url(drive_name)) {
    url <- drive_name
    drive_name <- NULL

    sp_url_parts <- sp_url_parse(url, call = call)
    site_url <- site_url %||% sp_url_parts[["site_url"]]
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]
    drive_id <- drive_id %||% sp_url_parts[["drive_id"]]

    if (is.null(drive_id)) {
      drive_name <- drive_name %||% .default_drive_name
    }
  }

  site <- site %||% get_sp_site(
    site_url = site_url,
    ...,
    call = call
    )

  check_ms_site(site, call = call)
  check_exclusive_strings(drive_name, drive_id, call = call)

  drive <- site$get_drive(drive_name = drive_name, drive_id = drive_id)

  if (properties) {
    return(drive$properties)
  }

  drive
}

#' @rdname sp_drive
#' @name set_sp_drive
#' @param overwrite If `TRUE`, replace the existing option for
#'   `sharepointr.default_drive`. If `FALSE` and the option is a `ms_drive`
#'   object, return an error.
#' @export
set_sp_drive <- function(..., overwrite = FALSE, call = caller_env()) {
  new_sp_drive <- get_sp_drive(..., call = call)

  if (is_ms_drive(getOption("sharepointr.default_drive")) && !overwrite) {
    cli_abort(
      "Set {.code overwrite = TRUE} to replace existing
      {.envvar sharepointr.default_drive} option.",
      call = call
    )
  }

  options(
    "sharepointr.default_drive" = new_sp_drive
  )
}
