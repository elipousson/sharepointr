# SharePoint REST API helpers
#
# The Graph API can't change some list column settings that SharePoint stores
# as separate field types (single and multiple lines of text, single and
# multiple choice) and can't set column validation. These helpers use the
# SharePoint REST API for those changes.

#' SharePoint REST field type kinds
#' <https://learn.microsoft.com/en-us/dotnet/api/microsoft.sharepoint.client.fieldtype>
#' @noRd
sp_field_type_kind <- c(
  Text = 2L,
  Note = 3L,
  Choice = 6L,
  MultiChoice = 15L
)

# Cache of SharePoint-scoped access tokens keyed by host
sp_rest_tokens <- new.env(parent = emptyenv())

#' Get a SharePoint-scoped access token for a `ms_list`
#'
#' Exchanges the refresh token from the Microsoft Graph login used by
#' `sp_list` for an access token scoped to the SharePoint host. This requires a
#' delegated (user) login. Service principal logins can't use this approach
#' and SharePoint app-only REST access requires certificate authentication.
#' @noRd
sp_rest_token <- function(sp_list, host, call = caller_env()) {
  cached <- sp_rest_tokens[[host]]

  if (!is.null(cached) && cached[["expires_at"]] > Sys.time() + 60) {
    return(cached[["access_token"]])
  }

  token <- sp_list[["token"]]
  refresh_token <- token[["credentials"]][["refresh_token"]]

  if (is.null(refresh_token) || !identical(as.integer(token[["version"]]), 2L)) {
    cli_abort(
      c(
        "Can't get a SharePoint REST API token from the current Microsoft
        Graph login.",
        "i" = "This change requires a delegated (user) login with a refresh
        token, e.g. the default {.pkg Microsoft365R} login."
      ),
      call = call
    )
  }

  aad_host <- token[["aad_host"]] %||% "https://login.microsoftonline.com/"

  req <- httr2::request(aad_host) |>
    httr2::req_url_path_append(token[["tenant"]], "oauth2", "v2.0", "token") |>
    httr2::req_body_form(
      grant_type = "refresh_token",
      client_id = token[["client"]][["client_id"]],
      client_secret = token[["client"]][["client_secret"]],
      refresh_token = refresh_token,
      scope = paste0(host, "/.default offline_access")
    ) |>
    httr2::req_error(is_error = \(resp) FALSE)

  resp <- httr2::req_perform(req)
  body <- httr2::resp_body_json(resp)

  if (httr2::resp_status(resp) != 200) {
    cli_abort(
      c(
        "Can't get a SharePoint REST API token for {.url {host}}.",
        "x" = "{body[['error_description']] %||% body[['error']]}"
      ),
      call = call
    )
  }

  sp_rest_tokens[[host]] <- list(
    access_token = body[["access_token"]],
    expires_at = Sys.time() + as.numeric(body[["expires_in"]] %||% 3600)
  )

  body[["access_token"]]
}

#' Get the site web URL for a `ms_list`
#' @noRd
sp_list_web_url <- function(sp_list, call = caller_env()) {
  site <- AzureGraph::call_graph_endpoint(
    sp_list[["token"]],
    paste0("sites/", sp_list_site_id(sp_list)),
    options = list(`$select` = "webUrl")
  )

  site[["webUrl"]]
}

#' Perform a SharePoint REST API request for a list
#'
#' @param path Path relative to `{site}/_api/web/lists(guid'{id}')/`.
#' @param body Optional named list sent as JSON.
#' @param merge If `TRUE`, send a MERGE request (an update).
#' @returns The parsed response body (or `NULL` for an empty response).
#' @noRd
sp_list_rest_request <- function(
  sp_list,
  path = NULL,
  method = "GET",
  body = NULL,
  merge = FALSE,
  call = caller_env()
) {
  check_ms_obj(sp_list, "ms_list", call = call)

  web_url <- sp_list_web_url(sp_list, call = call)
  url_parts <- httr2::url_parse(web_url)
  host <- paste0(url_parts[["scheme"]], "://", url_parts[["hostname"]])
  token <- sp_rest_token(sp_list, host = host, call = call)

  url <- paste0(
    sub("/$", "", web_url),
    "/_api/web/lists(guid'",
    sp_list[["properties"]][["id"]],
    "')",
    if (!is.null(path)) paste0("/", path)
  )

  req <- httr2::request(url) |>
    httr2::req_auth_bearer_token(token) |>
    httr2::req_headers(Accept = "application/json;odata=nometadata") |>
    httr2::req_method(method) |>
    httr2::req_error(is_error = \(resp) FALSE)

  if (merge) {
    req <- httr2::req_headers(
      req,
      `X-HTTP-Method` = "MERGE",
      `IF-MATCH` = "*"
    )
  }

  # Action endpoints (e.g. `views(guid'...')/viewfields/addviewfield('X')`)
  # return HTTP 411 (Length Required) for a POST without a body
  if (is.null(body) && method == "POST") {
    body <- set_names(list(), character(0))
  }

  if (!is.null(body)) {
    req <- req |>
      httr2::req_body_json(body, auto_unbox = TRUE) |>
      httr2::req_headers(
        `Content-Type` = "application/json;odata=nometadata"
      )
  }

  resp <- httr2::req_perform(req)
  resp_body <- tryCatch(
    httr2::resp_body_json(resp),
    error = \(cnd) NULL
  )

  if (httr2::resp_status(resp) >= 400) {
    message <- resp_body[["odata.error"]][["message"]][["value"]] %||%
      httr2::resp_status_desc(resp)

    cli_abort(
      c(
        "SharePoint REST API request failed (HTTP {httr2::resp_status(resp)}).",
        "x" = "{message}"
      ),
      call = call
    )
  }

  resp_body
}

#' Update a list field with the SharePoint REST API
#'
#' @param column_name Internal column name.
#' @param fields Named list of SP.Field properties, e.g.
#'   `list(FieldTypeKind = 3L)`.
#' @noRd
update_sp_list_field_rest <- function(
  sp_list,
  column_name,
  fields,
  call = caller_env()
) {
  sp_list_rest_request(
    sp_list,
    path = sp_rest_field_path(column_name),
    method = "POST",
    body = fields,
    merge = TRUE,
    call = call
  )

  invisible(sp_list)
}

#' @noRd
sp_rest_field_path <- function(column_name) {
  paste0(
    "fields/getbyinternalnameortitle('",
    sp_rest_string(column_name),
    "')"
  )
}

#' Format a string for use in a SharePoint REST API URL path
#'
#' Single quotes in OData string literals are escaped by doubling and the
#' string is URL encoded (e.g. a space as `%20`).
#' @noRd
sp_rest_string <- function(x) {
  utils::URLencode(gsub("'", "''", x, fixed = TRUE), reserved = TRUE)
}

#' Convert a columnValidation to SharePoint REST field properties
#' @noRd
sp_validation_as_rest_fields <- function(validation) {
  language <- validation[["defaultLanguage"]]
  descriptions <- validation[["descriptions"]]
  message <- NULL

  if (length(descriptions) > 0) {
    tags <- purrr::map_chr(descriptions, "languageTag")
    match <- which(tolower(tags) == tolower(language %||% ""))
    message <- descriptions[[match[1] %|% 1L]][["displayName"]]
  }

  purrr::compact(
    list(
      ValidationFormula = validation[["formula"]],
      ValidationMessage = message
    )
  )
}

#' Set column validation with the SharePoint REST API
#' @noRd
update_sp_list_column_validation <- function(
  sp_list,
  column_name,
  validation,
  call = caller_env()
) {
  update_sp_list_field_rest(
    sp_list,
    column_name = column_name,
    fields = sp_validation_as_rest_fields(validation),
    call = call
  )
}
