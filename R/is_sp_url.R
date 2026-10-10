#' Is x a SharePoint URL?
#'
#' @param x Object to test if it is a URL.
#' @keywords internal
#' @export
is_sp_url <- function(x) {
  if (!is_vector(x) || is_empty(x)) {
    return(FALSE)
  }

  is_url(x) & grepl("\\.sharepoint.com/", x)
}

#' @rdname is_sp_url
#' @name is_sp_site_url
#' @export
is_sp_site_url <- function(x) {
  is_sp_url(x) & grepl("\\.sharepoint.com/sites/[^/]+/?$", x)
}

#' @rdname is_sp_url
#' @name is_sp_drive_url
#' @export
is_sp_drive_url <- function(x) {
  is_sp_url(x) & grepl("/Forms/AllItems\\.aspx$", x)
}

#' @rdname is_sp_url
#' @name is_sp_site_page_url
#' @export
is_sp_site_page_url <- function(x) {
  is_sp_url(x) & grepl("/SitePages/", x)
}

#' @returns A logical vector the same length as `x`, `TRUE` for elements that
#'   are SharePoint "Forms" URLs.
#' @noRd
is_sp_site_form_url <- function(x) {
  is_sp_url(x) & grepl("/Forms/", x)
}

#' @rdname is_sp_url
#' @name is_sp_doc_url
#' @export
is_sp_doc_url <- function(x) {
  is_sp_url(x) & grepl("sourcedoc=", x)
}

#' @rdname is_sp_url
#' @name is_sp_type_url
#' @param type Type of URL to test against.
#' @export
is_sp_type_url <- function(x, type = "w") {
  type_pattern <- paste0("\\.sharepoint.com/:", type, ":/")
  is_sp_url(x) & grepl(type_pattern, x)
}

#' @rdname is_sp_url
#' @name is_sp_folder_url
#' @export
is_sp_folder_url <- function(x) {
  is_sp_type_url(x, type = "f")
}

#' @returns A logical vector the same length as `x`, `TRUE` for elements that
#'   are SharePoint list "webview" URLs (a list URL, with or without a view
#'   page, that isn't already matched by [is_sp_type_url()]).
#' @noRd
is_sp_webview_list_url <- function(x) {
  # A view URL (e.g. "/Lists/{list name}/AllItems.aspx") or a list URL with no
  # view (e.g. "/Lists/{list name}")
  is_webview_list <- !is_sp_type_url(x, type = "l") &
    (grepl("/Lists/.+\\.aspx", x) |
      grepl("/Lists/[^/?#]+/?([?#].*)?$", x))

  is_sp_url(x) & is_webview_list
}
