#' Get a SharePoint site or set a default SharePoint site
#'
#' [get_sp_site()] is a wrapper for [Microsoft365R::get_sharepoint_site()] and
#' returns a `ms_site` object. [set_sp_site()] allows you to set a default
#' SharePoint site for use by other functions.
#'
#' @name sp_site
NULL

#' @rdname sp_site
#' @name get_sp_site
#' @param site_url A SharePoint site URL in the format "https://\[tenant
#'   name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or document
#'   URL will be parsed and a site URL built using the tenant and site name if
#'   found.
#' @param site_name,site_id Site name or ID of the SharePoint site as an
#'   alternative to the SharePoint site URL. Only one of the three arguments
#'   should be supplied.
#' @param ... For [get_sp_drive()], additional parameters passed to
#'   [Microsoft365R::get_sharepoint_site()]. For [set_sp_site()], parameters
#'   passed to [get_sp_site()].
#' @inheritDotParams Microsoft365R::get_sharepoint_site
#' @inheritParams rlang::args_error_context
#' @export
#' @importFrom Microsoft365R get_sharepoint_site
get_sp_site <- function(site_url = NULL,
                        site_name = NULL,
                        site_id = NULL,
                        ...,
                        call = caller_env()) {
  if (is_ms_site(getOption("sharepointr.default_site"))) {
    return(getOption("sharepointr.default_site"))
  }

  if (!is.null(site_url)) {
    check_url(site_url, call = call)

    if (!is_sp_site_url(site_url)) {
      parts <- sp_url_parse(site_url, call = call)

      site_url <- sp_site_url_build(
        parts[["tenant"]],
        parts[["site_name"]]
      )
    }
  }

  if (is_empty(list(site_url, site_name, site_id))) {
    cli_abort(
      "{.arg site_url}, {.arg site_name}, or {.arg site_id} must be supplied.",
      call = call
    )
  }

  Microsoft365R::get_sharepoint_site(
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    ...
  )
}

#' @rdname sp_site
#' @name set_sp_site
#' @param overwrite If `TRUE`, replace the existing option for
#'   `sharepointr.default_site`. If `FALSE` and the option is a `ms_site`
#'   object, return an error.
#' @export
set_sp_site <- function(..., overwrite = FALSE, call = caller_env()) {
  new_default_site <- get_sp_site(..., call = call)

  if (is_ms_site(getOption("sharepointr.default_site")) && !overwrite) {
    cli_abort(
      "Set {.code overwrite = TRUE} to replace existing
      {.envvar sharepointr.default_site} option.",
      call = call
    )
  }

  options(
    "sharepointr.default_site" = new_default_site
  )
}
