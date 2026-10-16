# Mock the Graph API $batch endpoint. `respond` is called with the requests in
# each $batch request and returns the status for each request. A status named
# with an error message (e.g. `c("Database Is Read Only" = 500L)`) returns that
# error message in the response body.
local_mock_batch_endpoint <- function(respond, env = parent.frame()) {
  calls <- new.env()
  calls$batches <- list()

  local_mocked_bindings(
    call_graph_endpoint = function(token, operation, body = NULL, ...) {
      requests <- body[["requests"]]
      calls$batches <- c(calls$batches, list(requests))
      status <- respond(requests, length(calls$batches))

      messages <- names(status) %||% rep("", length(status))

      responses <- purrr::pmap(
        list(requests, unname(status), messages),
        \(request, status, message) {
          body <- list(url = request[["url"]])

          if (nzchar(message)) {
            body[["error"]] <- list(code = "generalException", message = message)
          }

          list(
            id = request[["id"]],
            status = status,
            headers = if (status %in% c(429L, 503L)) list(`Retry-After` = "0"),
            body = body
          )
        }
      )

      # The Graph API doesn't return responses in order
      list(responses = rev(responses))
    },
    .package = "AzureGraph",
    .env = env
  )

  calls
}

new_requests <- function(n) {
  purrr::map(seq_len(n), \(i) list(method = "DELETE", url = paste0("/items/", i)))
}

test_that("sp_graph_batch_requests() sends up to 20 requests per $batch request in order", {
  calls <- local_mock_batch_endpoint(\(requests, n) rep(204L, length(requests)))

  responses <- sp_graph_batch_requests(NULL, new_requests(45), .progress = FALSE)

  expect_identical(lengths(calls$batches), c(20L, 20L, 5L))
  # Request ids within each $batch request start at 1
  expect_identical(purrr::map_chr(calls$batches[[2]], "id"), as.character(1:20))

  # Responses are in the same order as the requests (including ids "10" and
  # "2" which are out of order as strings)
  expect_identical(
    purrr::map_chr(responses, \(x) x[["body"]][["url"]]),
    paste0("/items/", 1:45)
  )

  expect_identical(sp_graph_batch_requests(NULL, list(), .progress = FALSE), list())
})

test_that("sp_graph_batch_requests() retries throttled requests", {
  # Requests 2 and 3 are throttled the first time
  calls <- local_mock_batch_endpoint(\(requests, n) {
    if (n == 1) c(204L, 429L, 429L, 204L) else rep(204L, length(requests))
  })

  expect_message(
    responses <- sp_graph_batch_requests(NULL, new_requests(4), .progress = FALSE),
    "2 requests were throttled or temporarily unavailable"
  )

  # Only the throttled requests are sent again
  expect_identical(
    purrr::map_chr(calls$batches[[2]], "url"),
    c("/items/2", "/items/3")
  )
  expect_identical(purrr::map_int(responses, "status"), rep(204L, 4))
  expect_identical(
    purrr::map_chr(responses, \(x) x[["body"]][["url"]]),
    paste0("/items/", 1:4)
  )

  # Throttled requests are returned after `max_retries`
  calls <- local_mock_batch_endpoint(\(requests, n) rep(429L, length(requests)))

  responses <- suppressMessages(
    sp_graph_batch_requests(NULL, new_requests(2), max_retries = 1, .progress = FALSE)
  )
  expect_length(calls$batches, 2)
  expect_identical(purrr::map_int(responses, "status"), c(429L, 429L))
})

test_that("sp_graph_batch_requests() retries 'Database is read only' errors", {
  calls <- local_mock_batch_endpoint(\(requests, n) {
    if (n == 1) {
      c(204L, "Database Is Read Only" = 500L, 204L)
    } else {
      rep(204L, length(requests))
    }
  })

  local_mocked_bindings(Sys.sleep = function(time) NULL, .package = "base")

  responses <- suppressMessages(
    sp_graph_batch_requests(NULL, new_requests(3), .progress = FALSE)
  )

  expect_identical(purrr::map_chr(calls$batches[[2]], "url"), "/items/2")
  expect_identical(purrr::map_int(responses, "status"), rep(204L, 3))

  # Other errors aren't retried
  calls <- local_mock_batch_endpoint(\(requests, n) {
    c(204L, "Item not found" = 404L, "Internal error" = 500L)
  })

  responses <- sp_graph_batch_requests(NULL, new_requests(3), .progress = FALSE)

  expect_length(calls$batches, 1)
  expect_identical(purrr::map_int(responses, "status"), c(204L, 404L, 500L))
})

test_that("sp_batch_is_retryable() checks the status and error message", {
  error_response <- function(status, message = NULL) {
    list(status = status, body = list(error = list(message = message)))
  }

  expect_true(sp_batch_is_retryable(error_response(429L)))
  expect_true(sp_batch_is_retryable(error_response(503L)))
  expect_true(sp_batch_is_retryable(error_response(504L)))
  expect_true(sp_batch_is_retryable(error_response(500L, "Database Is Read Only")))
  expect_true(sp_batch_is_retryable(error_response(423L, "database is read-only")))

  expect_false(sp_batch_is_retryable(error_response(204L)))
  expect_false(sp_batch_is_retryable(error_response(500L, "Internal error")))
  # A read-only field error isn't a temporary error
  expect_false(
    sp_batch_is_retryable(error_response(400L, "Field 'Created' is read-only"))
  )
})

test_that("sp_batch_retry_after() uses the Retry-After header or a backoff", {
  expect_identical(
    sp_batch_retry_after(list(
      list(headers = list(`Retry-After` = "3")),
      list(headers = list(`retry-after` = "5")),
      list(headers = NULL)
    )),
    5
  )
  expect_identical(sp_batch_retry_after(list(list(headers = NULL)), attempt = 0), 2)
  expect_identical(sp_batch_retry_after(list(list(headers = NULL)), attempt = 2), 8)
  # The backoff is capped
  expect_identical(sp_batch_retry_after(list(list(headers = NULL)), attempt = 10), 60)
})

test_that("check_sp_batch_responses() lists failed requests", {
  responses <- purrr::map(
    c(201L, 400L, 201L, 404L),
    \(status) {
      list(
        status = status,
        body = if (status >= 300) {
          list(
            error = list(
              code = if (status == 404L) "itemNotFound",
              message = paste("Error", status)
            )
          )
        }
      )
    }
  )

  expect_identical(
    check_sp_batch_responses(responses[c(1, 3)], labels = c("A", "C"), action = "be created"),
    responses[c(1, 3)]
  )

  cnd <- expect_error(
    check_sp_batch_responses(
      responses,
      labels = paste("Record", 1:4),
      action = "be created"
    ),
    "2 list items couldn't be created"
  )
  expect_match(conditionMessage(cnd), "2 other list items were completed")
  # Failed requests include the HTTP status and Graph error code
  expect_match(conditionMessage(cnd), "Record 2: Error 400 (HTTP 400)", fixed = TRUE)
  expect_match(
    conditionMessage(cnd),
    "Record 4: Error 404 (HTTP 404 itemNotFound)",
    fixed = TRUE
  )
  expect_identical(cnd$responses, responses)
})

test_that("sp_list_item_request() builds list item requests", {
  sp_list <- list(
    properties = list(id = "list-1", parentReference = list(siteId = "site-1"))
  )

  expect_identical(
    sp_list_item_request(sp_list, "POST", fields = list(Title = "A")),
    list(
      method = "POST",
      url = "/sites/site-1/lists/list-1/items",
      headers = list(`Content-Type` = "application/json"),
      body = list(fields = list(Title = "A"))
    )
  )
  expect_identical(
    sp_list_item_request(sp_list, "DELETE", item_id = "5"),
    list(method = "DELETE", url = "/sites/site-1/lists/list-1/items/5")
  )
})
