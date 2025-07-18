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

#' @noRd
is_sp_webview_list_url <- function(x) {
  is_webview_list <- !is_sp_type_url(x, type = "l") &
    grepl("/Lists/.+AllItems\\.aspx", x)

  is_sp_url(x) & is_webview_list
}
