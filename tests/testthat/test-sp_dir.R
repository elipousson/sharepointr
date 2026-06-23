test_that("sp_drive functions work", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  sp_drive_list_df <- list_sp_drives(
    site_url = test_site_url
  )

  expect_s3_class(
    sp_drive_list_df,
    "data.frame"
  )

  sp_drive_list <- list_sp_drives(
    site_url = test_site_url,
    as_data_frame = FALSE
  )

  expect_type(
    sp_drive_list,
    "list"
  )
})

test_that("sp_dir functions work", {
  test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

  skip_if_no_ms_site(test_dir_url)

  expect_type(
    sp_dir_ls(
      test_dir_url
    ),
    "character"
  )

  expect_s3_class(
    sp_dir_info(test_dir_url),
    "data.frame"
  )
})
