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

test_that("sp_dir_info(recurse = TRUE) lists all directories and sorts by name", {
  tree <- list(
    root = data.frame(
      name = c("B", "A", "z.csv"),
      size = 1,
      isdir = c(TRUE, TRUE, FALSE)
    ),
    "A" = data.frame(name = "A/a.csv", size = 1, isdir = FALSE),
    "B" = data.frame(
      name = c("B/C", "B/b.csv"),
      size = 1,
      isdir = c(TRUE, FALSE)
    ),
    "B/C" = data.frame(name = "B/C/c.txt", size = 1, isdir = FALSE)
  )
  drive <- structure(
    list(list_items = function(path, ...) {
      tree[[if (path == "") "root" else path]]
    }),
    class = c("ms_drive", "ms_object")
  )

  items <- sp_dir_info(drive = drive, recurse = TRUE)
  expect_identical(
    items[["name"]],
    c("A", "A/a.csv", "B", "B/C", "B/C/c.txt", "B/b.csv", "z.csv")
  )

  # Unmatched directories are still searched
  items <- sp_dir_info(drive = drive, recurse = TRUE, regexp = "\\.txt$")
  expect_identical(items[["name"]], "B/C/c.txt")

  items <- sp_dir_info(drive = drive, recurse = TRUE, type = "directory")
  expect_identical(items[["name"]], c("A", "B", "B/C"))

  items <- sp_dir_info(drive = drive, recurse = TRUE, type = "file")
  expect_identical(
    items[["name"]],
    c("A/a.csv", "B/C/c.txt", "B/b.csv", "z.csv")
  )

  items <- sp_dir_info(drive = drive, recurse = TRUE, sort = "name-desc")
  expect_identical(items[["name"]][1], "z.csv")

  expect_error(
    sp_dir_info(drive = drive, recurse = TRUE, sort = "modified-desc"),
    "info"
  )

  items <- sp_dir_info(drive = drive, recurse = TRUE, sort = "none")
  expect_identical(items[["name"]][1:3], c("B", "A", "z.csv"))
})

test_that("sp_dir_info() sorts by modified time with info = 'all'", {
  drive <- structure(
    list(list_items = function(path, ...) {
      data.frame(
        name = c("a.csv", "b.csv", "c.csv"),
        size = c(3, 1, 2),
        isdir = FALSE,
        lastModifiedDateTime = c(
          "2026-01-02T00:00:00Z",
          "2026-01-03T00:00:00Z",
          "2026-01-01T00:00:00Z"
        )
      )
    }),
    class = c("ms_drive", "ms_object")
  )

  items <- sp_dir_info(drive = drive, info = "all", sort = "modified-desc")
  expect_identical(items[["name"]], c("b.csv", "a.csv", "c.csv"))

  items <- sp_dir_info(drive = drive, sort = "size-asc")
  expect_identical(items[["name"]], c("b.csv", "c.csv", "a.csv"))

  # Order is unchanged for a single directory unless `sort` is supplied
  items <- sp_dir_info(drive = drive)
  expect_identical(items[["name"]], c("a.csv", "b.csv", "c.csv"))
})
