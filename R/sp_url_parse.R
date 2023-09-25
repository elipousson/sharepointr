#' Parse a SharePoint URL using `httr2::url_parse`
#'
#' @keywords internal
#' @export
#' @importFrom httr2 url_parse
sp_url_parse <- function(url, call = caller_env()) {
  check_url(url, call = call)

  url <- httr2::url_parse(url)

  sp_url_parts <- list_replace_empty(
    c(
      sp_url_parse_hostname(url[["hostname"]]),
      sp_url_parse_path(url[["path"]]),
      sp_url_parse_query(url[["query"]])
    )
  )

  sp_url_parts[["site_url"]] <- paste0(
    sp_url_parts[["base_url"]], "/sites/",
    sp_url_parts[["site_name"]]
  )

  sp_url_parts
}

#' @rdname sp_url_parse
#' @name sp_url_parse_hostname
#' @export
sp_url_parse_hostname <- function(hostname,
                                  tenant = "[a-zA-Z0-9.-]+",
                                  scheme = "https") {
  parts <- str_match_list(
    hostname,
    pattern = glue("({tenant})\\.sharepoint\\.com"),
    nm = c("base_url", "tenant")
  )

  parts[["base_url"]] <- paste0(
    scheme, "://", parts[["base_url"]]
  )

  parts
}

#' @noRd
str_match_sp_url_path <- function(path,
                                  url_type = "w|x|p|o|b|t|i|v|f|u|li",
                                  permissions = "r|s|t|u|g") {
  str_match_list(
    utils::URLdecode(path),
    # regex created with support from GPT-3.5 on 2023-09-21
    # https://chat.openai.com/share/a7885919-bbbe-489a-9fd7-37d71567a1f7
    pattern = glue(
      "/:([{url_type}]):/([{permissions}])(?:/sites)?/([a-zA-Z0-9-]+)",
      "(?:/(.+[/$])+)?(?:([^?]+))?"
    ),
    nm = c("path", "url_type", "permissions", "site_name", "file_path", "file")
  )
}

#' @rdname sp_url_parse
#' @name sp_url_parse_path
#' @export
sp_url_parse_path <- function(path,
                              url_type = "w|x|p|o|b|t|i|v|f|u|li",
                              permissions = "r|s|t|u|g",
                              drive_name_prefix = "Shared ",
                              .default_drive_name = "Documents") {
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
    parts[["drive_name"]] <- .default_drive_name
    return(parts[c("url_type", "permissions", "site_name", "drive_name")])
  }

  parts[["drive_name"]] <- parts[["file_path"]] |>
    str_split_i(pattern = "/", i = 1)

  parts[["file_path"]] <- parts[["file_path"]] |>
    str_remove(paste0("^", parts[["drive_name"]], "/")) |>
    str_remove("/$")

  if (is_string(drive_name_prefix)) {
    parts[["drive_name"]] <- parts[["drive_name"]] |>
      str_remove(drive_name_prefix)
  }

  parts[["file"]] <- parts[["file"]] |>
    str_remove("^/")

  parts
}

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
