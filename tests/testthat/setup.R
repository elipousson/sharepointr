skip_if_no_ms_site <- function(url) {
  url_parts <- sp_url_parse(url, call = call)
  site_url <- url_parts[["site_url"]]

  if (!is_sp_site_url(site_url)) {
    return(skip("{.arg url} must be a valid SharePoint site URL"))
  }

  sp_site <- rlang::try_fetch(
    get_sp_site(site_url),
    error = function(cnd) {
      NULL
    }
  )

  skip_if_not(
    inherits(sp_site, "ms_site"),
    message = glue::glue(
      "User must have access to the SharePoint site at {site_url}"
    )
  )
}

withr::local_options(
  list(
    sharepointr.cache = TRUE,
    sharepointr.refresh = FALSE,
    sharepointr.cache_dir = fs::path_temp()
  ),
  .local_envir = teardown_env()
)
