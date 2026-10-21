# Shared SharePoint folder used by other tests (e.g. test-sp_dir.R,
# test-sp_item.R) for read-only checks. Any items created here by these
# tests use `sp_test_marker()` names and are deleted before the test ends.
test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

# ---- Local validation (no SharePoint access required) ----

test_that("upload_sp_item errors for missing file/src or nonexistent path", {
  expect_error(
    upload_sp_item(dest = test_dir_url)
  )

  expect_error(
    upload_sp_item(
      file = "sharepointr-does-not-exist-8f92c1.txt",
      dest = test_dir_url
    )
  )
})

test_that("upload_sp_items errors for missing file/src", {
  expect_error(
    upload_sp_items(dest = test_dir_url)
  )
})

# ---- Live SharePoint integration tests ----
#
# These tests upload uniquely-named files (using `sp_test_marker()`) to
# `test_dir_url` and always delete them (via `withr::defer()`) so they never
# collide with, or leave behind, real content on the test site.

test_that("upload_sp_item uploads a file, blocks overwrite, then allows it", {
  skip_if_no_ms_site(test_dir_url)

  drive <- get_sp_drive(drive_name = test_dir_url)

  marker <- sp_test_marker("upload-sp-item")
  file_name <- paste0(marker, ".txt")

  local_dir <- withr::local_tempdir()
  local_file <- fs::path(local_dir, file_name)
  writeLines("sharepointr upload_sp_item() test file", local_file)

  dest_path <- NULL
  withr::defer({
    if (!is.null(dest_path)) {
      try(
        delete_sp_item(path = dest_path, drive = drive, confirm = FALSE),
        silent = TRUE
      )
    }
  })

  dest_path <- upload_sp_item(
    file = local_file,
    dest = test_dir_url,
    drive = drive
  )

  expect_type(dest_path, "character")
  expect_length(dest_path, 1)

  uploaded_item <- get_sp_item(path = dest_path, drive = drive)
  expect_s3_class(uploaded_item, "ms_drive_item")

  expect_error(
    upload_sp_item(
      file = local_file,
      dest = test_dir_url,
      drive = drive,
      overwrite = FALSE
    )
  )

  expect_no_error(
    upload_sp_item(
      file = local_file,
      dest = test_dir_url,
      drive = drive,
      overwrite = TRUE
    )
  )
})

test_that("upload_sp_items uploads multiple files", {
  skip_if_no_ms_site(test_dir_url)

  drive <- get_sp_drive(drive_name = test_dir_url)

  marker <- sp_test_marker("upload-sp-items")
  file_names <- paste0(marker, "-", 1:2, ".txt")

  local_dir <- withr::local_tempdir()
  local_files <- fs::path(local_dir, file_names)

  purrr::walk2(
    local_files,
    file_names,
    \(path, name) {
      writeLines(paste("sharepointr upload_sp_items() test", name), path)
    }
  )

  dest_paths <- NULL
  withr::defer({
    if (!is.null(dest_paths)) {
      for (path in dest_paths) {
        try(
          delete_sp_item(path = path, drive = drive, confirm = FALSE),
          silent = TRUE
        )
      }
    }
  })

  dest_paths <- upload_sp_items(
    file = local_files,
    dest = test_dir_url,
    drive = drive
  )

  expect_type(dest_paths, "character")
  expect_length(dest_paths, 2)

  uploaded_names <- sp_dir_info(
    drive = drive,
    path = dirname(dest_paths[[1]]),
    info = "name",
    full_names = FALSE
  )

  expect_true(all(file_names %in% uploaded_names))
})

test_that("write_sharepoint writes an object to file, uploads it, and blocks overwrite", {
  skip_if_no_ms_site(test_dir_url)

  drive <- get_sp_drive(drive_name = test_dir_url)

  marker <- sp_test_marker("write-sharepoint")
  file_name <- paste0(marker, ".csv")

  data <- data.frame(
    id = 1:3,
    label = c("a", "b", "c")
  )

  # `sp_url_as_src_dest()` mirrors the destination path write_sharepoint()
  # builds internally via upload_sp_item(), so it can be used to look up (and
  # clean up) the uploaded item without write_sharepoint() returning it.
  dest_path <- sp_url_as_src_dest(url = test_dir_url, src = file_name)

  withr::defer({
    try(
      delete_sp_item(path = dest_path, drive = drive, confirm = FALSE),
      silent = TRUE
    )
  })

  local_dir <- withr::local_tempdir()

  out <- write_sharepoint(
    data,
    file = file_name,
    dest = test_dir_url,
    new_path = local_dir,
    drive = drive
  )

  expect_identical(out, data)

  uploaded_item <- get_sp_item(path = dest_path, drive = drive)
  expect_s3_class(uploaded_item, "ms_drive_item")

  expect_error(
    write_sharepoint(
      data,
      file = file_name,
      dest = test_dir_url,
      new_path = local_dir,
      drive = drive,
      overwrite = FALSE
    )
  )

  expect_no_error(
    write_sharepoint(
      data,
      file = file_name,
      dest = test_dir_url,
      new_path = local_dir,
      drive = drive,
      overwrite = TRUE
    )
  )
})

test_that("write_sharepoint() picks a writer from the object class and file extension", {
  uploads <- list()
  local_mocked_bindings(
    upload_sp_item = function(file, dest, ...) {
      uploads[[basename(file)]] <<- list(file = file, dest = dest)
    }
  )

  local_dir <- withr::local_tempdir()
  data <- data.frame(id = 1:2, label = c("a", "b"))
  zip_magic <- charToRaw("PK")
  file_magic <- function(name) readBin(uploads[[name]][["file"]], "raw", 2)

  write_sharepoint(data, "data.csv", new_path = local_dir)
  expect_identical(read.csv(uploads[["data.csv"]][["file"]]), data)
  expect_null(uploads[["data.csv"]][["dest"]])

  write_sharepoint(data, "data.XLSX", new_path = local_dir)
  expect_identical(file_magic("data.XLSX"), zip_magic)

  write_sharepoint(data, "dataxlsx.csv", new_path = local_dir)
  expect_identical(read.csv(uploads[["dataxlsx.csv"]][["file"]]), data)

  skip_if_not_installed("officer")
  write_sharepoint(officer::read_xlsx(), "workbook.xlsx", new_path = local_dir)
  expect_identical(file_magic("workbook.xlsx"), zip_magic)
})

test_that("write_sharepoint() errors for a shapefile", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)

  expect_snapshot(error = TRUE, {
    write_sharepoint(nc, "nc.shp", new_path = withr::local_tempdir())
  })
})

test_that("upload_sp_item() uses the drive and folder from the shares API", {
  upload_args <- NULL
  drive <- structure(
    list(
      upload_file = function(src, dest, ...) upload_args <<- dest
    ),
    class = c("ms_drive", "ms_object")
  )

  local_mocked_bindings(
    sp_dir_request_items = function(...) NULL,
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = drive, path = "Folder A/B", is_folder = TRUE)
    },
    get_sp_drive = function(...) stop("get_sp_drive() shouldn't be called")
  )

  local_file <- withr::local_tempfile(fileext = ".txt", lines = "test")

  dest <- upload_sp_item(
    local_file,
    dest = "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FTeam%2FShared%20Documents%2FFolder%20A%2FB"
  )

  expect_identical(upload_args, paste0("Folder A/B/", basename(local_file)))
  expect_identical(dest, upload_args)
})

test_that("upload_sp_item() errors if `dest` is a file URL", {
  local_mocked_bindings(
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = NULL, path = "Folder/A.csv", is_folder = FALSE)
    }
  )

  local_file <- withr::local_tempfile(fileext = ".txt", lines = "test")

  expect_snapshot(error = TRUE, {
    upload_sp_item(
      local_file,
      dest = "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv"
    )
  })
})

test_that("upload_sp_items() uploads to destinations in different drives", {
  list_calls <- 0
  local_upload_drive <- function() {
    uploads <- character()
    structure(
      list(
        upload_file = function(src, dest, ...) uploads <<- c(uploads, dest),
        uploads = function() uploads
      ),
      class = c("ms_drive", "ms_object")
    )
  }

  drives <- list(a = local_upload_drive(), b = local_upload_drive())
  shares_calls <- 0

  local_mocked_bindings(
    sp_dir_request_items = function(...) {
      list_calls <<- list_calls + 1
      NULL
    },
    sp_shares_get_drive_path = function(url, ...) {
      shares_calls <<- shares_calls + 1
      drive <- if (grepl("TeamA", url)) "a" else "b"
      list(drive = drives[[drive]], path = "Folder", is_folder = TRUE)
    },
    get_sp_drive = function(...) stop("get_sp_drive() shouldn't be called")
  )

  local_files <- c(
    withr::local_tempfile(fileext = ".txt", lines = "a"),
    withr::local_tempfile(fileext = ".txt", lines = "b"),
    withr::local_tempfile(fileext = ".txt", lines = "c")
  )
  url_a <- "https://contoso.sharepoint.com/sites/TeamA/Shared%20Documents/Folder"
  url_b <- "https://contoso.sharepoint.com/sites/TeamB/Shared%20Documents/Folder"

  dest <- upload_sp_items(local_files, dest = c(url_a, url_b, url_a))

  expect_identical(dest, paste0("Folder/", basename(local_files)))
  expect_identical(shares_calls, 2)
  expect_identical(list_calls, 2)
  expect_identical(drives$a$uploads(), dest[c(1, 3)])
  expect_identical(drives$b$uploads(), dest[2])
})

test_that("upload_sp_items() checks src and uploads each file", {
  uploads <- list()

  # The mocks can't record calls from parallel workers
  local_mocked_bindings(
    sp_use_parallel = function() FALSE,
    sp_upload_dest = function(dest, ..., drive = NULL) {
      list(drive = drive, file_path = dest, dest = dest, existing = NULL)
    },
    upload_sp_src = function(src, dest, ...) {
      uploads <<- c(uploads, list(list2(src = src, dest = dest, ...)))
      dest
    }
  )

  local_dir <- withr::local_tempdir()
  local_files <- fs::path(local_dir, c("a.txt", "b.txt"))
  fs::file_create(local_files)

  expect_error(
    upload_sp_items(file = c(local_files, fs::path(local_dir, "c.txt")), dest = "folder"),
    "c.txt"
  )
  expect_length(uploads, 0)

  dest <- upload_sp_items(
    file = local_files,
    dest = c("folder/a.txt", "folder/b.txt"),
    drive = "drive"
  )

  expect_identical(dest, c("folder/a.txt", "folder/b.txt"))
  expect_identical(purrr::map_chr(uploads, "src"), as.character(local_files))
  expect_identical(uploads[[2]][["drive"]], "drive")
})
