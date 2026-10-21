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

test_that("sp_drive_item_path() gets an item path relative to the drive root", {
  expect_identical(sp_drive_item_path(list(name = "root", root = list())), "")
  expect_identical(
    sp_drive_item_path(list(
      name = "Folder",
      parentReference = list(path = "/drives/b!abc/root:")
    )),
    "Folder"
  )
  expect_identical(
    sp_drive_item_path(list(
      name = "Sub Folder",
      parentReference = list(path = "/drives/b!abc/root:/Folder A/B")
    )),
    "Folder A/B/Sub Folder"
  )
})

test_that("sp_dir_info() uses the drive and path from the shares API", {
  list_args <- NULL
  drive <- structure(
    list(list_items = function(path, ...) {
      list_args <<- path
      data.frame(name = "Folder/A.csv", size = 1, isdir = FALSE, id = "1")
    }),
    class = c("ms_drive", "ms_object")
  )

  local_mocked_bindings(
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = drive, path = "Folder", is_folder = TRUE)
    },
    get_sp_drive = function(...) stop("get_sp_drive() shouldn't be called")
  )

  items <- sp_dir_info(
    "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FTeam%2FShared%20Documents%2FFolder"
  )

  expect_identical(list_args, "Folder")
  expect_identical(items[["name"]], "Folder/A.csv")
})

test_that("sp_dir_info() errors for a file URL from the shares API", {
  local_mocked_bindings(
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = NULL, path = "Folder/A.csv", is_folder = FALSE)
    }
  )

  expect_snapshot(error = TRUE, {
    sp_dir_info(
      "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv"
    )
  })
})

test_that("sp_dir_info() falls back to the parsed URL if the shares API fails", {
  drive_args <- NULL

  local_mocked_bindings(
    sp_shares_get_drive_path = function(...) {
      cli::cli_abort("Forbidden (HTTP 403).")
    },
    get_sp_drive = function(drive_name = NULL, ...) {
      drive_args <<- drive_name
      structure(
        list(list_items = function(path, ...) {
          data.frame(name = path, size = 1, isdir = FALSE, id = "1")
        }),
        class = c("ms_drive", "ms_object")
      )
    }
  )

  url <- "https://contoso.sharepoint.com/:f:/r/sites/Team/Shared%20Documents/Folder?csf=1"
  items <- sp_dir_info(url)

  expect_identical(drive_args, url)
  expect_identical(items[["name"]], "Folder")

  expect_snapshot(error = TRUE, {
    sp_dir_info(
      "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder"
    )
  })
})
