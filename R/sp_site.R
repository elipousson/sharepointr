#' Get a SharePoint site or set a default SharePoint site
#'
#' [get_sp_site()] is a wrapper for [Microsoft365R::get_sharepoint_site()] and
#' returns a `ms_site` object. [cache_sp_site()] allows you to cache a default
#' SharePoint site for use by other functions. Users seeking to access a
#' SharePoint subsite must provide the `site_id` instead of a `site_url` or
#' `site_name` value. You can see available subsite ID values by using the
#' `list_subsites()` method for `Microsoft365R::ms_site` objects.
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
#' @inheritDotParams Microsoft365R::get_sharepoint_site -site_url -site_name
#' -site_id
#' @param refresh If `TRUE`, get a new site even if the existing site is cached
#'   as a local option. If `FALSE`, use the cached `ms_site` object.
#' @param cache If `TRUE`, cache site to a file using [cache_sp_site()].
#' @inheritParams rlang::args_error_context
#' @export
#' @keywords sites
#' @importFrom Microsoft365R get_sharepoint_site
get_sp_site <- function(
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  ...,
  cache = getOption("sharepointr.cache", FALSE),
  refresh = getOption("sharepointr.refresh", TRUE),
  overwrite = FALSE,
  cache_file = NULL,
  call = caller_env()
) {
  cache_exists <- file.exists(sp_cache_path(
    cache_file,
    what = "ms_site",
    call = call
  ))

  if (cache && cache_exists && !refresh) {
    site <- get_cached_ms_obj(
      cache_file = cache_file,
      what = "ms_site",
      call = call
    )

    if (is_ms_site(site)) {
      return(site)
    } else {
      # TODO: Consider adding warning
      # Treat invalid files as missing
      cache_exists <- FALSE
      overwrite <- TRUE
    }
  }

  if (!is.null(site_url)) {
    check_url(site_url, call = call)

    # FIXME: Does not work for subsite URLs
    if (!is_sp_site_url(site_url)) {
      site_url <- sp_url_parse(site_url, call = call)[["site_url"]]
    }
  }

  message <- "One of {.arg site_url}, {.arg site_name}, or {.arg site_id}
  must be supplied"

  if (is.null(c(site_url, site_name, site_id))) {
    cli_abort(
      paste0(message, "."),
      call = call
    )
  } else if (is.null(site_id)) {
    check_exclusive_strings(
      site_url,
      site_name,
      message = paste0(
        message,
        ", not both {.arg site_url} and {.arg site_name}."
      ),
      call = call
    )
  } else {
    check_exclusive_strings(
      site_url,
      site_id,
      message = paste0(
        message,
        ", not both {.arg site_url} and {.arg site_id}."
      ),
      call = call
    )
  }

  # Get site
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

  # Optionally save site object to file
  if (cache && (refresh || !cache_exists)) {
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
#' @param cache_file File name for cached drive or site. Default `NULL`.
#' @inheritParams cache_ms_obj
#' @export
cache_sp_site <- function(
  ...,
  site = NULL,
  cache_file = NULL,
  cache_dir = NULL,
  overwrite = FALSE,
  call = caller_env()
) {
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
