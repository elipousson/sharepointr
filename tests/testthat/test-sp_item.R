test_that("get_sp_item and get_sp_item_properties works", {
  test_item_url <- "https://bmore.sharepoint.com/:b:/r/sites/DOP-ALL/Shared%20Documents/General/Benton-Building-Directory_By-Agency.pdf?csf=1&web=1&e=m8M5KO"

  skip_if_no_ms_site(test_item_url)

  sp_item <- get_sp_item(test_item_url)

  expect_s3_class(
    sp_item,
    "ms_drive_item"
  )

  sp_item_properties <- get_sp_item_properties(test_item_url)

  expect_type(
    sp_item_properties,
    "list"
  )

  withr::with_tempdir(
    {
      download_sp_item(
        item = sp_item,
        new_path = "Benton-Building-Directory_By-Agency.pdf"
      )

      expect_true(
        fs::file_exists("Benton-Building-Directory_By-Agency.pdf")
      )
    }
  )
})
