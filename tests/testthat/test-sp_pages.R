test_that("list_sp_pages works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  sp_site_pages <- list_sp_pages(
    site_url = test_site_url
  )

  expect_s3_class(
    sp_site_pages,
    "data.frame"
  )
})
