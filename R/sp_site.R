#' Get a SharePoint site or set a default SharePoint site
#'
#' [get_sp_site()] is a wrapper for [Microsoft365R::get_sharepoint_site()] and
#' returns a `ms_site` object. [set_sp_site()] allows you to set a default
#' SharePoint site for use by other functions. [get_sp_site_group()] gets the
#' group associated with an individual site using the `get_group` method.
#'
#' @name sp_site
#' @seealso [Microsoft365R::ms_site]
NULL

#' @rdname sp_site
#' @name get_sp_site
#' @param site_url A SharePoint site URL in the format "https://\[tenant
#'   name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or document
#'   URL can also be parsed to build a site URL using the tenant and site name
#'   included in the URL.
#' @param site_name,site_id Site name or ID of the SharePoint site as an
#'   alternative to the SharePoint site URL. Exactly one of  `site_url`,
#'   `site_name`, and `site_id` must be supplied.
#' @param ... Additional parameters passed to
#'   [Microsoft365R::get_sharepoint_site()] or [get_sp_site()].
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
#' @param site A `ms_site` object. If `site` is supplied, `site_url`,
#'   `site_name`, and `site_id` are ignored.
#' @param overwrite If `TRUE`, replace the existing option for
#'   `sharepointr.default_site`. Error if `FALSE` and the option is a `ms_site`
#'   object.
#' @export
set_sp_site <- function(...,
                        site = NULL,
                        overwrite = FALSE,
                        call = caller_env()) {
  new_default_site <- site %||% get_sp_site(..., call = call)

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

#' @rdname sp_site
#' @name get_sp_site_group
#' @export
get_sp_site_group <- function(site_url = NULL,
                              site_name = NULL,
                              site_id = NULL,
                              ...,
                              site = NULL,
                              call = caller_env()) {
  site <- site %||% get_sp_site(
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    ...,
    call = call
  )

  check_ms_site(site, call = call)

  site$get_group()
}
