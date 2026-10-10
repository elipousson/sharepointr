# Microsoft Graph shares API
#
# The shares API resolves a SharePoint URL (a sharing link from "Copy link", a
# document URL, or an item, folder, or document library URL) to a drive item,
# without parsing the site, drive, or path from the URL. See:
# <https://learn.microsoft.com/en-us/graph/api/shares-get>

#' Encode a URL as a sharing token for the Graph shares API
#'
#' Base64url encodes `url` without padding and adds a `"u!"` prefix.
#' @returns A string.
#' @noRd
sp_share_id <- function(url) {
  encoded <- jsonlite::base64_enc(charToRaw(enc2utf8(url)))
  encoded <- gsub("[\r\n]", "", encoded)
  paste0("u!", sub("=+$", "", chartr("+/", "-_", encoded)))
}

#' Can a URL be used with the Graph shares API?
#'
#' The shares API only returns drive items, so site, site page, and list URLs
#' aren't supported.
#' @returns `TRUE` or `FALSE`.
#' @noRd
is_sp_shares_url <- function(x) {
  is_string(x) &&
    is_sp_url(x) &&
    !is_sp_site_url(x) &&
    !is_sp_site_page_url(x) &&
    !is_sp_type_url(x, type = "l") &&
    !grepl("/Lists/", x)
}

#' Get the site URL from the path of a SharePoint URL
#'
#' Used to get a Microsoft Graph login before calling the shares API (a login
#' for any site in a tenant can be used to get an item from another site).
#' @returns A site URL or `NULL` if `url` has no "/sites/{site name}" path.
#' @noRd
sp_url_site_url <- function(url) {
  site_url <- stringr::str_extract(
    url,
    "^https://[^/]+(?=/)"
  )

  site_name <- stringr::str_match(
    url,
    "^https://[^/]+/(?::[a-z]+:/[a-z]/)?sites/([^/?#]+)"
  )[, 2]

  if (is.na(site_url) || is.na(site_name)) {
    return(NULL)
  }

  paste0(site_url, "/sites/", site_name)
}

#' Get a drive item from a SharePoint URL with the Graph shares API
#'
#' @param url A SharePoint URL that passes `is_sp_shares_url()`.
#' @param site A `ms_site` object used for the Microsoft Graph login. If
#'   `NULL`, the site is retrieved with [get_sp_site()] using `site_url` or
#'   the site in `url`.
#' @param ... Additional parameters passed to [get_sp_site()].
#' @param drive_url,default_drive_name Ignored. These [get_sp_drive()]
#'   arguments may be passed to [get_sp_item()] but aren't used by
#'   [get_sp_site()].
#' @returns A `ms_drive_item` object, or `NULL` if no site can be found for the
#'   login. Errors if the shares API request fails.
#' @noRd
sp_shares_get_item <- function(
  url,
  ...,
  site = NULL,
  site_url = NULL,
  drive_url = NULL,
  default_drive_name = NULL,
  call = caller_env()
) {
  if (is.null(site)) {
    site_url <- site_url %||% sp_url_site_url(url)

    if (is.null(site_url)) {
      return(NULL)
    }

    site <- get_sp_site(site_url = site_url, ..., call = call)
  }

  check_ms_site(site, call = call)

  properties <- AzureGraph::call_graph_endpoint(
    site$token,
    paste0("shares/", sp_share_id(url), "/driveItem"),
    # Get the item from a sharing link without granting lasting access
    httr::add_headers(Prefer = "redeemSharingLinkIfNecessary")
  )

  Microsoft365R::ms_drive_item$new(site$token, site$tenant, properties)
}

#' Get the drive and path for a SharePoint URL with the Graph shares API
#'
#' @inheritParams sp_shares_get_item
#' @returns A list with `drive` (a `ms_drive` object for the item's document
#'   library), `path` (the item path relative to the drive root, or `""` for
#'   the drive root), and `is_folder` (`TRUE` for a folder or drive root), or
#'   `NULL` if no site can be found for the login. Errors if a request fails.
#' @noRd
sp_shares_get_drive_path <- function(url, ..., call = caller_env()) {
  item <- sp_shares_get_item(url, ..., call = call)

  if (is.null(item)) {
    return(NULL)
  }

  properties <- item$properties

  drive_properties <- AzureGraph::call_graph_endpoint(
    item$token,
    file.path("drives", properties[["parentReference"]][["driveId"]])
  )

  list(
    drive = Microsoft365R::ms_drive$new(
      item$token,
      item$tenant,
      drive_properties
    ),
    path = sp_drive_item_path(properties),
    is_folder = !is.null(properties[["folder"]]) ||
      !is.null(properties[["root"]])
  )
}

#' Get the path of a drive item relative to the drive root
#'
#' @param properties Drive item properties.
#' @returns A string, e.g. `"Folder/Subfolder"`, or `""` for the drive root.
#' @noRd
sp_drive_item_path <- function(properties) {
  if (!is.null(properties[["root"]])) {
    return("")
  }

  # e.g. "/drives/{drive-id}/root:/Folder" -> "Folder"
  parent_path <- sub(
    "^/drives/[^/]+/root:/?",
    "",
    properties[["parentReference"]][["path"]] %||% ""
  )

  if (parent_path == "") {
    return(properties[["name"]])
  }

  paste0(parent_path, "/", properties[["name"]])
}
