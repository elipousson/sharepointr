#' Is x a SharePoint URL?
#'
#' @param x Object to test if it is a URL.
#' @keywords internal
#' @export
is_sp_url <- function(x) {
  is_url(x) & grepl("\\.sharepoint.com/", x)
}

#' @rdname is_sp_url
#' @name is_sp_site_url
#' @export
is_sp_site_url <- function(x) {
  is_sp_url(x) & grepl("\\.sharepoint.com/sites/", x)
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
