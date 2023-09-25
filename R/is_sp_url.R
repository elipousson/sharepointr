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

#' @noRd
is_sp_type_url <- function(x, type = "w") {
  type_pattern <- paste0("\\.sharepoint.com/:", type, ":/")
  is_sp_url(x) & grepl(type_pattern, x)
}

#' @noRd
is_sp_folder_url <- function(x) {
  is_sp_type_url(x, type = "f")
}
