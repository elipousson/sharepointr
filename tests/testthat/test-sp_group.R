test_that("get_sp_group works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  sp_group <- get_sp_group(
    site_url = test_site_url
  )

  expect_s3_class(
    sp_group,
    "az_group"
  )

  expect_s3_class(
    list_sp_group_members(
      sp_group = sp_group
    ),
    "data.frame"
  )
})
