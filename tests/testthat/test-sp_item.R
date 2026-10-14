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

test_that("batch_download_sp_item() gets the drive once and downloads each item", {
  drive_calls <- 0
  downloads <- list()

  # The mocks can't record calls from parallel workers
  local_mocked_bindings(
    sp_use_parallel = function() FALSE,
    get_sp_drive = function(...) {
      drive_calls <<- drive_calls + 1
      "drive"
    },
    download_sp_item = function(..., item_id = NULL, path = NULL, item = NULL, dest = NULL) {
      downloads <<- c(downloads, list(list2(item_id = item_id, path = path, dest = dest, ...)))
      dest %||% item[["properties"]][["name"]]
    }
  )

  dest <- batch_download_sp_item(
    item_id = c("1", "2"),
    dest = c("a.csv", "b.csv"),
    drive_name = "Documents",
    overwrite = TRUE
  )

  expect_identical(dest, c("a.csv", "b.csv"))
  expect_identical(drive_calls, 1)
  expect_identical(purrr::map_chr(downloads, "item_id"), c("1", "2"))
  expect_identical(downloads[[1]][["drive"]], "drive")
  expect_true(downloads[[1]][["overwrite"]])

  # The drive isn't looked up for URLs (which may refer to different drives)
  drive_calls <- 0
  downloads <- list()

  batch_download_sp_item(
    path = c("https://contoso.sharepoint.com/a", "https://contoso.sharepoint.com/b"),
    new_path = "files"
  )

  expect_identical(drive_calls, 0)
  expect_identical(purrr::map_chr(downloads, "dest"), c("files", "files"))

  # A list of items with no dest uses the item names
  items <- list(
    list(properties = list(name = "c.csv")),
    list(properties = list(name = "d.csv"))
  )

  expect_identical(batch_download_sp_item(item = items), c("c.csv", "d.csv"))
  expect_identical(drive_calls, 0)
})
