# Live Microsoft Graph tests must never fall through to AzureAuth's
# interactive login flow: AzureAuth::select_auth_type() picks
# "authorization_code" whenever no password/username/certificate is supplied,
# regardless of `interactive()` -- so in a headless environment (CI, or any
# sandboxed agent without access to the real $HOME token cache) a live call
# with no usable credentials doesn't error, it hangs waiting for a browser
# redirect that will never come. Gate every live test on a credential check
# first so those environments skip cleanly and fast instead.

#' Does a Microsoft Graph login cache already exist on disk?
#'
#' A cheap, side-effect-free check for the presence of AzureR's
#' "graph_logins.json" registry. It doesn't guarantee any entry is still
#' valid/unexpired (a stale entry can still trigger an interactive refresh),
#' but its absence guarantees no cached login exists at all.
#' @noRd
has_cached_ms_graph_login <- function() {
  path <- tryCatch(AzureR_set_path(), error = function(cnd) NA_character_)

  if (is.na(path) || !fs::dir_exists(path)) {
    return(FALSE)
  }

  length(
    suppressWarnings(fs::dir_ls(path, glob = "*graph_logins.json", fail = FALSE))
  ) >
    0
}

#' Are non-interactive service-principal credentials configured?
#'
#' Checks for the tenant, app (client) ID, and client secret needed for a
#' non-interactive `"client_credentials"` login. `CLIMICROSOFT365_TENANT` and
#' `CLIMICROSOFT365_AADAPPID` match the env vars `Microsoft365R::
#' get_sharepoint_site()` already reads by default;
#' `CLIMICROSOFT365_AADAPPSECRET` is specific to sharepointr's test suite.
#' @noRd
has_ms_graph_service_principal <- function() {
  nzchar(Sys.getenv("CLIMICROSOFT365_TENANT")) &&
    nzchar(Sys.getenv("CLIMICROSOFT365_AADAPPID")) &&
    nzchar(Sys.getenv("CLIMICROSOFT365_AADAPPSECRET"))
}

#' Get a `ms_site`/`ms_team` object using a service-principal login if
#' configured, falling back to the (potentially cached) default login
#' otherwise.
#' @noRd
ms_graph_test_login_args <- function() {
  if (!has_ms_graph_service_principal()) {
    return(list())
  }

  list(
    tenant = Sys.getenv("CLIMICROSOFT365_TENANT"),
    app = Sys.getenv("CLIMICROSOFT365_AADAPPID"),
    password = Sys.getenv("CLIMICROSOFT365_AADAPPSECRET"),
    auth_type = "client_credentials"
  )
}

skip_if_no_ms_graph_credentials <- function() {
  skip_if_not(
    has_cached_ms_graph_login() || has_ms_graph_service_principal(),
    message = paste(
      "No cached Microsoft Graph login and no CLIMICROSOFT365_TENANT /",
      "CLIMICROSOFT365_AADAPPID / CLIMICROSOFT365_AADAPPSECRET",
      "service-principal credentials are configured; skipping to avoid",
      "an interactive login prompt."
    )
  )
}

skip_if_no_ms_site <- function(url) {
  url_parts <- sp_url_parse(url, call = call)
  site_url <- url_parts[["site_url"]]

  if (!is_sp_site_url(site_url)) {
    return(skip("`url` must be a valid SharePoint site URL"))
  }

  skip_if_no_ms_graph_credentials()

  sp_site <- rlang::try_fetch(
    suppressMessages(
      rlang::exec(get_sp_site, site_url, !!!ms_graph_test_login_args())
    ),
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
  skip_if_no_ms_graph_credentials()

  ms_team <- rlang::try_fetch(
    suppressMessages(rlang::exec(
      get_ms_team,
      team_name = team_name,
      team_id = team_id,
      ...,
      !!!ms_graph_test_login_args()
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
