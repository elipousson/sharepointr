# Microsoft Graph JSON batching
#
# A $batch request combines up to 20 Graph API requests into one HTTP request,
# which is much faster than sending each request separately when writing many
# list items. See:
# <https://learn.microsoft.com/en-us/graph/json-batching>

# Maximum number of requests in a single $batch request
sp_batch_size <- 20L

# Statuses for throttled requests that can be sent again
sp_batch_retry_status <- c(429L, 503L)

#' Send Graph API requests with $batch requests
#'
#' Splits `requests` into $batch requests of up to 20 requests each. The
#' $batch requests are sent with [purrr::in_parallel()] (so they are sent in
#' parallel if the user has set [mirai::daemons()]). Throttled requests (status
#' 429 or 503) are sent again after the delay from the `Retry-After` header, up
#' to `max_retries` times.
#'
#' AzureGraph::call_batch_endpoint() isn't used since it errors if any request
#' fails (dropping the responses to the other requests) and orders responses by
#' id as a string (e.g. "10" before "2").
#' @param token A Microsoft Graph token (e.g. from a `ms_list` object).
#' @param requests A list of requests, each a list with `method`, `url` (a
#'   path relative to the Graph API version, e.g. `"/sites/..."`), and
#'   optionally `headers` and `body`.
#' @param max_retries Maximum number of times to send throttled requests again.
#' @returns A list of responses (each with `id`, `status`, and optionally
#'   `headers` and `body`) in the same order as `requests`.
#' @noRd
sp_graph_batch_requests <- function(
  token,
  requests,
  max_retries = 3,
  .progress = TRUE,
  call = caller_env()
) {
  responses <- vector("list", length(requests))
  pending <- seq_along(requests)

  for (attempt in seq(0, max_retries)) {
    chunks <- unname(split(pending, ceiling(seq_along(pending) / sp_batch_size)))

    chunk_responses <- purrr::map(
      purrr::map(chunks, \(i) requests[i]),
      purrr::in_parallel(
        \(chunk) fn(token, chunk),
        fn = sp_graph_batch,
        token = token
      ),
      .progress = .progress && attempt == 0
    )

    responses[pending] <- purrr::list_flatten(chunk_responses)

    status <- purrr::map_int(responses[pending], \(x) as.integer(x[["status"]]))
    throttled <- status %in% sp_batch_retry_status

    if (!any(throttled) || attempt == max_retries) {
      break
    }

    pending <- pending[throttled]
    wait <- sp_batch_retry_after(responses[pending], attempt = attempt)

    cli::cli_inform(
      c(
        "!" = "{length(pending)} request{?s} {?was/were} throttled by the
        Microsoft Graph API.",
        "i" = "Retrying in {wait} second{?s}."
      )
    )

    Sys.sleep(wait)
  }

  responses
}

#' Send a single $batch request
#' @param requests A list of up to 20 requests.
#' @returns A list of responses in the same order as `requests`.
#' @noRd
sp_graph_batch <- function(token, requests) {
  requests <- purrr::imap(
    unname(requests),
    \(request, i) c(list(id = as.character(i)), request)
  )

  resp <- AzureGraph::call_graph_endpoint(
    token,
    "$batch",
    body = list(requests = requests),
    encode = "json",
    http_verb = "POST"
  )

  responses <- resp[["responses"]]
  ids <- as.integer(purrr::map_chr(responses, "id"))

  responses[order(ids)]
}

#' Get the number of seconds to wait before retrying throttled requests
#'
#' Uses the longest `Retry-After` header value or, if there isn't one, an
#' exponential backoff (1, 2, 4, ... seconds).
#' @returns A number of seconds.
#' @noRd
sp_batch_retry_after <- function(responses, attempt = 0) {
  retry_after <- purrr::map_dbl(
    responses,
    \(x) {
      headers <- x[["headers"]]
      value <- headers[[match("retry-after", tolower(names(headers)))]] %||% NA

      suppressWarnings(as.numeric(value))
    }
  )

  retry_after <- retry_after[!is.na(retry_after)]

  if (length(retry_after) == 0) {
    return(2^attempt)
  }

  max(retry_after)
}

#' Abort if any batch responses have an error status
#'
#' @param responses Responses from `sp_graph_batch_requests()`.
#' @param labels Labels for each response used in the error message (e.g.
#'   item ids).
#' @param action Description of the action for the error message (e.g. "be
#'   created").
#' @returns `responses` invisibly. Errors if any response has a status of 300
#'   or higher, after reporting how many requests succeeded.
#' @noRd
check_sp_batch_responses <- function(
  responses,
  labels,
  action,
  call = caller_env()
) {
  status <- purrr::map_int(responses, \(x) as.integer(x[["status"]]))
  failed <- which(status >= 300)

  if (length(failed) == 0) {
    return(invisible(responses))
  }

  messages <- purrr::map_chr(
    responses[failed],
    \(x) {
      x[["body"]][["error"]][["message"]] %||% paste("HTTP", x[["status"]])
    }
  )

  shown <- utils::head(seq_along(failed), 5)
  n_failed <- length(failed)
  n_ok <- length(responses) - n_failed

  cli_abort(
    c(
      "{n_failed} list item{?s} couldn't {action}.",
      "i" = "{n_ok} other list item{?s} {?was/were} completed.",
      set_names(
        paste0(labels[failed[shown]], ": ", messages[shown]),
        rep("x", length(shown))
      ),
      if (n_failed > length(shown)) {
        c(" " = "... and {n_failed - length(shown)} more.")
      }
    ),
    responses = responses,
    call = call
  )
}

#' Build a request for a list item for a $batch request
#'
#' Uses the same path as the `do_operation` method for `ms_list` objects.
#' @param item_id Optional. Item id for an update or delete request.
#' @param fields Optional. Item fields for a create or update request.
#' @returns A request list with `method`, `url`, and (if `fields` is supplied)
#'   `headers` and `body`.
#' @noRd
sp_list_item_request <- function(
  sp_list,
  method,
  item_id = NULL,
  fields = NULL
) {
  url <- paste0(
    "/sites/",
    sp_list_site_id(sp_list),
    "/lists/",
    sp_list[["properties"]][["id"]],
    "/items",
    if (!is.null(item_id)) paste0("/", item_id)
  )

  if (is.null(fields)) {
    return(list(method = method, url = url))
  }

  list(
    method = method,
    url = url,
    headers = list(`Content-Type` = "application/json"),
    body = list(fields = fields)
  )
}
