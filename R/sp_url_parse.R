#' Parse a SharePoint URL using `httr2::url_parse`
#'
#' @description
#' [sp_url_parse()] parses a URL into a named list of parts.
#'
#' @details Types of SharePoint URLs
#'
#' SharePoint site URL:
#'
#' https://\[tenant\].sharepoint.com/sites/\[site name\]
#'
#' SharePoint document editor URL:
#'
#' https://\[tenant\].sharepoint.com/:\[url
#' type\]:/\[permissions\]/sites/\[site
#' name\]/_layouts/15/Doc.aspx?sourcedoc={\[item id\]}&file=\[file
#' name\]&\[additional query parameters\]
#'
#' SharePoint List URL:
#'
#' https://\[tenant\].sharepoint.com/sites/\[site name\]/Lists/\[list
#' name\]/AllItems.aspx?env=WebViewList
#'
#' https://\[tenant\].sharepoint.com/:l:/r/sites/\[site name\]/Lists/\[list
#' name\]
#'
#' SharePoint folder URL:
#'
#' https://\[tenant\].sharepoint.com/:\[url type\]:/\[permissions\]/sites/\[site
#' name\]/\[drive name (with possible "Shared" prefix)\]/\[folder path\]/\[folder
#' name\]/?\[additional query parameters\]
#'
#' SharePoint Planner URL:
#'
#' https://tasks.office.com/\[tenant\].onmicrosoft.com/en-US/Home/Planner/#/plantaskboard?groupId=\[Group
#' ID\]&planId=\[Plan ID\]
#'
#' @keywords internal
#' @export
#' @importFrom httr2 url_parse
#' @importFrom stringr str_detect
sp_url_parse <- function(url, call = caller_env()) {
  check_url(url, call = call)

  if (is_sp_site_page_url(url)) {
    return(sp_site_page_url_parse(url))
  }

  if (is_sp_webview_list_url(url)) {
    return(sp_webview_list_url_parse(url))
  }

  if (is_sp_site_url(url)) {
    return(sp_site_url_parse(url))
  }

  parts <- httr2::url_parse(url)

  sp_url_parts <- sp_url_parse_hostname(parts[["hostname"]])

  # FIXME: Should this be list_replace_na?
  sp_url_parts <- list_replace_empty(
    c(
      sp_url_parts,
      sp_url_parse_path(parts[["path"]]),
      sp_url_parse_query(parts[["query"]])
    )
  )

  sp_url_parts[["site_url"]] <- sp_site_url_build(sp_url_parts)

  sp_url_parts
}

#' @noRd
sp_site_url_build <- function(url) {
  paste0(url[["base_url"]], "/sites/", url[["site_name"]])
}

#' @description
#' [sp_url_parse_hostname()] parses the hostname into a tenant and base_url.
#'
#' @rdname sp_url_parse
#' @name sp_url_parse_hostname
#' @export
#' @importFrom httr2 url_parse
sp_url_parse_hostname <- function(hostname,
                                  tenant = "[a-zA-Z0-9.-]+",
                                  scheme = "https") {
  if (is_url(hostname)) {
    hostname <- httr2::url_parse(hostname)[["hostname"]]
  }

  parts <- str_match_list(
    hostname,
    pattern = glue("({tenant})\\.sharepoint\\.com"),
    nm = c("base_url", "tenant")
  )

  parts[["base_url"]] <- paste0(scheme, "://", parts[["base_url"]])

  parts
}

#' @description
#' [sp_url_parse_path()] parses the path into a URL type, permissions, drive
#' name, file path, and file name.
#'
#' @rdname sp_url_parse
#' @name sp_url_parse_path
#' @export
sp_url_parse_path <- function(path,
                              url_type = "w|x|p|o|b|t|i|v|f|u|li",
                              permissions = "r|s|t|u|g",
                              drive_name_prefix = "Shared ",
                              default_drive_name = "Documents") {
  if (is.null(path)) {
    return(path)
  }

  parts <- str_match_sp_url_path(
    path,
    url_type = url_type,
    permissions = permissions
  )

  if (str_detect(path, "_layouts")) {
    # If path is part a document URL, the parsed drive_name, file_path, and file
    # are assumed to be invalid
    parts[["drive_name"]] <- default_drive_name
    return(parts[c("url_type", "permissions", "site_name", "drive_name")])
  }

  parts[["drive_name"]] <- parts[["file_path"]] |>
    str_split_i(pattern = "/", i = 1)

  parts[["drive_name"]] <- utils::URLdecode(parts[["drive_name"]])

  parts[["file_path"]] <- parts[["file_path"]] |>
    str_remove(paste0("^", parts[["drive_name"]], "/")) |>
    str_remove_slash(after = TRUE)

  if (is_string(drive_name_prefix)) {
    parts[["drive_name"]] <- parts[["drive_name"]] |>
      str_remove(drive_name_prefix)
  }

  parts[["file"]] <- parts[["file"]] |>
    str_remove_slash()

  parts[["file_path"]] <- str_c_url(parts[["file_path"]], parts[["file"]])

  if (identical(parts[["url_type"]], "f")) {
    parts[["file"]] <- NULL
  }

  parts
}

#' @description
#' [sp_url_parse_query()] parses the item ID from a query.
#'
#' @rdname sp_url_parse
#' @name sp_url_parse_query
#' @export
sp_url_parse_query <- function(query) {
  if (is.null(query)) {
    return(query)
  }

  item_id <- NULL

  if (has_name(query, "sourcedoc")) {
    item_id <- str_remove_all(query[["sourcedoc"]], "\\{|\\}")
  }

  c(list(item_id = item_id), as.list(query))
}

#' Helper to get matches from the path of a SharePoint URL
#' @noRd
#' @importFrom utils URLdecode
str_match_sp_url_path <- function(path,
                                  url_type = "w|x|p|o|b|t|i|v|f|u|li",
                                  permissions = "r|s|t|u|g",
                                  nm = c(
                                    "path", "url_type", "permissions",
                                    "site_name", "file_path", "file"
                                  )) {
  str_match_list(
    utils::URLdecode(path),
    # regex created with support from GPT-3.5 on 2023-09-21
    # https://chat.openai.com/share/a7885919-bbbe-489a-9fd7-37d71567a1f7
    pattern = glue(
      "/:([{url_type}]):/([{permissions}])(?:/sites)?/([a-zA-Z0-9-]+)",
      "(?:/(.+[/$])+)?(?:([^?]+))?"
    ),
    nm = nm
  )
}

#' Helper for parsing a SharePoint List webview URL
#' @noRd
#' @importFrom stringr str_extract
#' @importFrom utils URLdecode
sp_webview_list_url_parse <- function(url) {
  parts <- httr2::url_parse(url)

  sp_url_parts <- sp_url_parse_hostname(parts[["hostname"]])

  sp_url_parts[["site_name"]] <- stringr::str_extract(
    parts[["path"]],
    "(?<=/sites/)([:alnum:]|-)+(?=/)"
  )

  sp_url_parts[["list_name"]] <- stringr::str_extract(
    parts[["path"]],
    "(?<=/Lists/).+(?=/AllItems\\.aspx)"
  )

  sp_url_parts[["list_name"]] <- utils::URLdecode(sp_url_parts[["list_name"]])

  sp_url_parts[["site_url"]] <- sp_site_url_build(sp_url_parts)

  sp_url_parts
}

#' Helper for parsing a SharePoint site page URL
#' @noRd
#' @importFrom stringr str_remove
sp_site_page_url_parse <- function(url) {
  c(
    sp_url_parse_hostname(url),
    list(
      "site_url" = stringr::str_remove(url, "/SitePages/[:graph:]+$"),
      "page_name" = basename(url)
    )
  )
}


#' Helper for parsing a SharePoint site URL
#' @noRd
sp_site_url_parse <- function(url) {
  c(
    sp_url_parse_hostname(url),
    list("site_url" = url)
  )
}
