test_that("get_sp_item and get_sp_item_properties works", {
  test_item_url <- "https://bmore.sharepoint.com/:x:/r/sites/DOP-CPR/Shared%20Documents/INSPIRE%20Program%20%F0%9F%8F%AB%F0%9F%9A%B8%F0%9F%8C%B3/INSPIRE%20Program%20Calendar.xlsx?d=w371f5202107241378dd79ad5d09c40f9&csf=1&web=1&e=87t30L"

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
        new_path = "INSPIRE Program Calendar.xlsx"
      )

      expect_true(
        fs::file_exists("INSPIRE Program Calendar.xlsx")
      )
    }
  )
})
