test_that("get_sp_site() adds a hint for token refresh errors", {
  local_mocked_bindings(
    get_sharepoint_site = function(...) stop("Unable to refresh token"),
    .package = "Microsoft365R"
  )

  expect_error(
    get_sp_site(site_url = "https://contoso.sharepoint.com/sites/x"),
    "clean_token_directory",
    fixed = TRUE
  )
})
