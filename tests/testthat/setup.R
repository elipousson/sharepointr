skip_if_no_ms_site <- function(url) {
  url_parts <- sp_url_parse(url, call = call)
  site_url <- url_parts[["site_url"]]

  if (!is_sp_site_url(site_url)) {
    return(skip("`url` must be a valid SharePoint site URL"))
  }

  sp_site <- rlang::try_fetch(
    suppressMessages(get_sp_site(site_url)),
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

skip_if_no_ms_team <- function(team_name = NULL, team_id = NULL, ...) {
  ms_team <- rlang::try_fetch(
    suppressMessages(get_ms_team(
      team_name = team_name,
      team_id = team_id,
      ...
    )),
    error = function(cnd) {
      NULL
    }
  )

  skip_if_not(
    inherits(ms_team, "ms_team"),
    message = glue::glue(
      "User must have access to the Microsoft Team {team_name %||% team_id}"
    )
  )
}

#' Build a unique marker string used to find list items created by a test
#' @noRd
sp_test_marker <- function(label) {
  paste0(
    "sharepointr-test-",
    label,
    "-",
    as.integer(Sys.time()),
    "-",
    sample.int(1e6, 1)
  )
}

withr::local_options(
  list(
    sharepointr.cache = FALSE,
    sharepointr.refresh = FALSE,
    sharepointr.cache_dir = fs::path_temp()
  ),
  .local_envir = teardown_env()
)
