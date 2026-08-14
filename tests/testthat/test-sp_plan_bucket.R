test_that("list_sp_plan_buckets works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/SitePages/CollabHome.aspx"

  skip_if_no_ms_site(test_site_url)

  expect_s3_class(
    list_sp_plan_buckets(
      plan_id = "eCf2Z3GuE0K_03VJn9iRMoIAC45e",
      site_url = test_site_url
    ),
    "data.frame"
  )
})
