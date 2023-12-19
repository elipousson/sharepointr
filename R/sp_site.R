#' Get a SharePoint site or set a default SharePoint site
#'
#' [get_sp_site()] is a wrapper for [Microsoft365R::get_sharepoint_site()] and
#' returns a `ms_site` object. [cache_sp_site()] allows you to cache a default
#' SharePoint site for use by other functions.
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
#' @param ... Additional parameters passed to [get_sp_site()] or
#'   [Microsoft365R::get_sharepoint_site()].
#' @inheritDotParams Microsoft365R::get_sharepoint_site -site_url -site_name -site_id
#' @param refresh If `TRUE`, get a new site even if the existing site is cached
#'   as a local option. If `FALSE`, use the cached `ms_site` object.
#' @param cache If `TRUE`, cache site to a file using [cache_sp_site()].
#' @inheritParams rlang::args_error_context
#' @export
#' @importFrom Microsoft365R get_sharepoint_site
get_sp_site <- function(site_url = NULL,
                        site_name = NULL,
                        site_id = NULL,
                        ...,
                        cache = FALSE,
                        refresh = TRUE,
                        overwrite = FALSE,
                        cache_file = getOption(
                          "sharepointr.cache_file_site",
                          "sp_site.rds"
                        ),
                        call = caller_env()) {
  if (!refresh && sp_cache_file_exists(cache_file, call = call)) {
    site <- withCallingHandlers(
      get_sp_cache(cache_file = cache_file, what = "ms_site", call = call),
      warning = function(cnd) NULL,
      error = function(cnd) NULL
    )

    if (is_ms_site(site)) {
      return(site)
    }

    refresh <- TRUE
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

  if (is.null(site_url) && is.null(site_name) && is.null(site_id)) {
    cli_abort(
      "{.arg site_url}, {.arg site_name}, or {.arg site_id} must be supplied.",
      call = call
    )
  } else {
    # FIXME: These may give confusing error messages
    check_exclusive_strings(site_url, site_name, call = call)
    check_exclusive_strings(site_url, site_id, call = call)
  }

  site <- withCallingHandlers(
    Microsoft365R::get_sharepoint_site(
      site_url = site_url,
      site_name = site_name,
      site_id = site_id,
      ...
    ),
    error = function(cnd) {
      cli_abort(
        cnd$message,
        call = call
      )
    }
  )

  if (cache) {
    cache_sp_site(
      site = site,
      cache_file = cache_file,
      overwrite = overwrite,
      call = call
    )
  }

  site
}

#' @rdname sp_site
#' @name cache_sp_site
#' @inheritParams ms_graph_obj_terms
#' @param cache_file File name for cached file if `cache = TRUE`. Defaults to
#'   `"sp_site.rds"` or option set with `sharepointr.cache_file_site`.
#' @inheritParams cache_ms_obj
#' @export
cache_sp_site <- function(...,
                          site = NULL,
                          cache_file = getOption(
                            "sharepointr.cache_file_site",
                            "sp_site.rds"
                          ),
                          cache_dir = "sharepointr.cache_dir",
                          overwrite = FALSE,
                          call = caller_env()) {
  site <- site %||% get_sp_site(..., call = call)

  cache_ms_obj(
    site,
    what = "ms_site",
    overwrite = overwrite,
    cache_file = cache_file,
    cache_dir = cache_dir,
    call = call
  )
}
