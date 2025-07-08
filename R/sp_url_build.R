#' Build a SharePoint site URL from a tenant and site name
#'
#' @noRd
sp_site_url_build <- function(
  tenant = NULL,
  site_name = NULL,
  scheme = "https",
  pattern = NULL
) {
  pattern <- pattern %||%
    "{scheme}://{tenant}.sharepoint.com/sites/{site_name}"
  glue(pattern)
}
