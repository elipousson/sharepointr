test_that("get_sp_item works", {
  skip_if_no_ms_site(
    "https://bmore.sharepoint.com/sites/DOP-ALL"
  )

  sp_item <- get_sp_item(
    "https://bmore.sharepoint.com/:b:/r/sites/DOP-ALL/Shared%20Documents/General/Benton-Building-Directory_By-Agency.pdf?csf=1&web=1&e=m8M5KO"
  )

  expect_s3_class(
    sp_item,
    "ms_drive_item"
  )
})
