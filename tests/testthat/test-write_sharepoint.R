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
    \(path, name) writeLines(paste("sharepointr upload_sp_items() test", name), path)
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
