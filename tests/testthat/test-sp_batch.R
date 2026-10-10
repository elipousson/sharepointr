# Mock the Graph API $batch endpoint. `respond` is called with the requests in
# each $batch request and returns the status for each request.
local_mock_batch_endpoint <- function(respond, env = parent.frame()) {
  calls <- new.env()
  calls$batches <- list()

  local_mocked_bindings(
    call_graph_endpoint = function(token, operation, body = NULL, ...) {
      requests <- body[["requests"]]
      calls$batches <- c(calls$batches, list(requests))
      status <- respond(requests, length(calls$batches))

      responses <- purrr::map2(
        requests,
        status,
        \(request, status) {
          list(
            id = request[["id"]],
            status = status,
            headers = if (status == 429L) list(`Retry-After` = "0"),
            body = list(url = request[["url"]])
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
    "2 requests were throttled"
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

test_that("sp_batch_retry_after() uses the Retry-After header or a backoff", {
  expect_identical(
    sp_batch_retry_after(list(
      list(headers = list(`Retry-After` = "3")),
      list(headers = list(`retry-after` = "5")),
      list(headers = NULL)
    )),
    5
  )
  expect_identical(sp_batch_retry_after(list(list(headers = NULL)), attempt = 2), 4)
})

test_that("check_sp_batch_responses() lists failed requests", {
  responses <- purrr::map(
    c(201L, 400L, 201L, 404L),
    \(status) {
      list(
        status = status,
        body = if (status >= 300) list(error = list(message = paste("Error", status)))
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
  expect_match(conditionMessage(cnd), "Record 2: Error 400")
  expect_match(conditionMessage(cnd), "Record 4: Error 404")
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
