test_that("list_sp_site_user_info works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  expect_s3_class(
    list_sp_site_user_info(
      site_url = test_site_url
    ),
    "data.frame"
  )
})
