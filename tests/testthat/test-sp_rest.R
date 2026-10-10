test_that("sp_list_web_url() caches the site web URL by site ID", {
  n_calls <- 0

  local_mocked_bindings(
    call_graph_endpoint = function(token, operation, ...) {
      n_calls <<- n_calls + 1
      list(webUrl = "https://example.sharepoint.com/sites/test")
    },
    .package = "AzureGraph"
  )

  site_id <- "test-sp-list-web-url-site"
  withr::defer(rm(list = site_id, envir = sp_site_web_urls))

  sp_list <- list(
    token = NULL,
    properties = list(parentReference = list(siteId = site_id))
  )

  expect_identical(
    sp_list_web_url(sp_list),
    "https://example.sharepoint.com/sites/test"
  )
  expect_identical(
    sp_list_web_url(sp_list),
    "https://example.sharepoint.com/sites/test"
  )
  expect_identical(n_calls, 1)
})
