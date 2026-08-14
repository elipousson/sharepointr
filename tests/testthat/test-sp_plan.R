test_that("get_sp_plan works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/SitePages/CollabHome.aspx"

  skip_if_no_ms_site(test_site_url)

  expect_r6_class(
    get_sp_plan(
      plan_id = "eCf2Z3GuE0K_03VJn9iRMoIAC45e",
      site_url = test_site_url
    ),
    "ms_plan"
  )
})

test_that("list_sp_plans works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/SitePages/CollabHome.aspx"

  skip_if_no_ms_site(test_site_url)

  expect_s3_class(
    list_sp_plans(
      site_url = test_site_url
    ),
    "data.frame"
  )
})
