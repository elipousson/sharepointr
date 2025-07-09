test_that("sp_dir functions work", {
  dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

  skip_if_no_ms_site(dir_url)

  expect_type(
    sp_dir_ls(
      dir_url
    ),
    "character"
  )

  expect_s3_class(
    sp_dir_info(dir_url),
    "data.frame"
  )
})
