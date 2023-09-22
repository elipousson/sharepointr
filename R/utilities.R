#' Does x match the pattern of a URL?
#'
#' @noRd
is_url <- function(x) {
  if (!is_vector(x) || is_empty(x)) {
    return(FALSE)
  }

  grepl(
    "http[s]?://(?:[[:alnum:]]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+",
    x
  )
}

#' Check is a URL is valid
#'
#' @noRd
check_url <- function(url,
                      allow_null = FALSE,
                      call = caller_env()) {
  check_string(url, allow_empty = FALSE, allow_null = allow_null, call = call)

  if (allow_null && is_null(url)) {
    return(invisible(NULL))
  }

  if (is_url(url)) {
    return(invisible(NULL))
  }

  stop_input_type(
    url,
    what = "a valid url",
    call = call
  )
}


#' Does x use the supplied file extension?
#'
#' @noRd
is_fileext_path <- function(x, fileext, ignore.case = TRUE) {
  grepl(
    paste0(
      "\\.",
      paste0(fileext, collapse = "|"),
      "$(?!\\.)"
    ),
    x,
    ignore.case = ignore.case,
    perl = TRUE
  )
}

#' @noRd
check_ms_drive <- function(x, allow_null = FALSE) {
  if (inherits(x, "ms_drive")) {
    return(invisible(NULL))
  }

  stop_input_type(
    x,
    what = "a `ms_drive` object",
    allow_null = allow_null
  )
}

#' @noRd
is_sp_url <- function(x) {
  is_url(x) & grepl("\\.sharepoint.com/", x)
}


#' @noRd
is_sp_site_url <- function(x) {
  is_sp_url(x) & grepl("\\.sharepoint.com/sites/", x)
}


#' @noRd
is_sp_doc_url <- function(x) {
  is_sp_url(x) & grepl("sourcedoc=", x)
}

#' Build a SharePoint site URL from a tenant and site name
#'
#' @noRd
sp_site_url_build <- function(tenant, site_name, error_call = caller_env()) {
  check_string(tenant, allow_empty = FALSE, call = error_call)
  check_string(site_name, allow_empty = FALSE, call = error_call)
  paste0(
    "https://",
    tenant,
    ".sharepoint.com/sites/",
    site_name
  )
}


sp_url_parse <- function(url, ...) {
  if (is_sp_doc_url(url)) {
    return(sp_doc_url_parse(url))
  }

  sp_site_url_parse(url)
}


#' Parse a SharePoint document URL to get a site and item ID
#'
#' @noRd
#' @importFrom stringr str_match
sp_doc_url_parse <- function(url) {
  matches <- stringr::str_match(
    utils::URLdecode(url),
    paste0(
      "https://([a-zA-Z0-9.-]+)\\.sharepoint\\.com",
      "/:w:/r/sites/([a-zA-Z0-9-]+)",
      # FIXME: Check if a more general pattern may be required
      "(?:/_layouts/15/Doc.aspx\\?sourcedoc=\\{([a-zA-Z0-9-]+)\\}",
      "&file=([^&]+))"
    )
  )

  list(
    tenant = matches[1, 2],
    site_name = matches[1, 3],
    item_id = matches[1, 4],
    file = matches[1, 5]
  )
}

#' Parse a SharePoint file URL to get a site, drive, and file name
#'
#' @noRd
#' @importFrom stringr str_match str_split_i str_remove
#' @importFrom utils URLdecode
sp_site_url_parse <- function(url, remove_drive_prefix = "^Shared ") {
  # regex created with support from GPT-3.5 on 2023-09-21
  # https://chat.openai.com/share/a7885919-bbbe-489a-9fd7-37d71567a1f7
  matches <- stringr::str_match(
    utils::URLdecode(url),
    paste0(
      "https://([a-zA-Z0-9.-]+)\\.sharepoint\\.com",
      "/:[w|u]:/r/sites/([a-zA-Z0-9-]+)",
      "(?:/(.+[/$])+)?(?:([^?]+))?"
    )
  )

  tenant <- matches[1, 2]
  site_name <- matches[1, 3]
  path <- matches[1, 4]
  file <- matches[1, 5]

  drive_name <- stringr::str_split_i(path, "/", 1)

  path <- stringr::str_remove(path, paste0("^", drive_name, "/"))
  path <- stringr::str_remove(path, "/$")

  drive_name <- str_remove(drive_name, pattern = remove_drive_prefix)

  list(
    tenant = tenant,
    site_name = site_name,
    drive_name = drive_name,
    path = path,
    file = file
  )
}
