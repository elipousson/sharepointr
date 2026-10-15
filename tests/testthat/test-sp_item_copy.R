test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

# ---- Local validation (no SharePoint access required) ----

test_that("sp_item_copy and sp_item_move check new_path", {
  expect_error(sp_item_copy("a.txt", NA_character_), "new_path")
  expect_error(sp_item_move("a.txt", ""), "new_path")
  expect_error(sp_dir_copy("a", 1), "new_path")
})

test_that("sp_item_copy checks path", {
  expect_error(sp_item_copy(NA_character_, "b.txt"), "path")
  expect_error(sp_item_copy(list("a.txt"), "b.txt"), "path")
})

test_that("check_sp_transfer_type checks for a file or folder", {
  folder <- list(is_folder = function() TRUE, properties = list(name = "a"))
  file <- list(is_folder = function() FALSE, properties = list(name = "a.txt"))

  expect_error(check_sp_transfer_type(folder, "file", "copy"), "sp_dir_copy")
  expect_error(
    check_sp_transfer_type(file, "directory", "move"),
    "sp_item_move"
  )
  expect_null(check_sp_transfer_type(file, "file"))
  expect_null(check_sp_transfer_type(folder, "directory"))
  expect_null(check_sp_transfer_type(folder, "any"))
})

test_that("str_c_path drops an empty folder path", {
  expect_identical(str_c_path("", "a.txt"), "a.txt")
  expect_identical(str_c_path("General/a", "b.txt"), "General/a/b.txt")
})

# ---- Live SharePoint integration tests ----
#
# These tests create a uniquely-named folder (using `sp_test_marker()`) in
# `test_dir_url` and always delete it (via `withr::defer()`).

test_that("sp_item_copy, sp_item_move, sp_dir_copy, and sp_dir_move work", {
  skip_if_no_ms_site(test_dir_url)

  drive <- get_sp_drive(drive_name = test_dir_url)

  marker <- sp_test_marker("copy-move")
  root <- paste0("General/", marker)

  withr::defer(
    try(
      delete_sp_item(path = root, drive = drive, confirm = FALSE),
      silent = TRUE
    )
  )

  sp_dir_create(c(root, paste0(root, "/a"), paste0(root, "/b")), drive = drive)

  local_file <- fs::path(withr::local_tempdir(), "file.txt")
  writeLines("sharepointr sp_item_copy() test file", local_file)

  upload_sp_item(file = local_file, dest = paste0(root, "/a"), drive = drive)

  # Copy a file into an existing folder
  new_path <- sp_item_copy(
    paste0(root, "/a/file.txt"),
    paste0(root, "/b"),
    drive = drive
  )

  expect_identical(new_path, paste0(root, "/b/file.txt"))
  expect_s3_class(get_sp_item(new_path, drive = drive), "ms_drive_item")

  # A copy to an existing file needs overwrite = TRUE
  expect_error(
    sp_item_copy(paste0(root, "/a/file.txt"), new_path, drive = drive),
    "overwrite"
  )

  expect_no_error(
    sp_item_copy(
      paste0(root, "/a/file.txt"),
      new_path,
      overwrite = TRUE,
      drive = drive
    )
  )

  # Folders need the sp_dir_* functions
  expect_error(
    sp_item_copy(paste0(root, "/a"), paste0(root, "/b"), drive = drive),
    "sp_dir_copy"
  )

  expect_error(
    sp_dir_copy(new_path, paste0(root, "/a"), drive = drive),
    "sp_item_copy"
  )

  # The parent folder of a new path must exist
  expect_error(
    sp_item_copy(
      paste0(root, "/a/file.txt"),
      paste0(root, "/missing/file.txt"),
      drive = drive
    ),
    "parent folder"
  )

  # Rename a file
  renamed <- sp_item_move(
    new_path,
    paste0(root, "/b/renamed.txt"),
    drive = drive
  )

  expect_identical(renamed, paste0(root, "/b/renamed.txt"))
  expect_setequal(
    sp_dir_ls(paste0(root, "/b"), drive = drive),
    "renamed.txt"
  )

  # Copy a folder to a new folder name
  dir_copy <- sp_dir_copy(paste0(root, "/a"), paste0(root, "/c"), drive = drive)

  expect_identical(dir_copy, paste0(root, "/c"))
  expect_setequal(sp_dir_ls(dir_copy, drive = drive), "file.txt")

  # Move a folder into an existing folder
  dir_moved <- sp_dir_move(dir_copy, paste0(root, "/b"), drive = drive)

  expect_identical(dir_moved, paste0(root, "/b/c"))
  expect_setequal(
    sp_dir_ls(paste0(root, "/b"), drive = drive),
    c("c", "renamed.txt")
  )
  expect_setequal(sp_dir_ls(root, drive = drive), c("a", "b"))

  # A folder can't be moved or copied to an existing folder without overwrite
  sp_dir_create(paste0(root, "/a/c"), drive = drive)

  expect_error(
    sp_dir_move(paste0(root, "/b/c"), paste0(root, "/a"), drive = drive),
    "replace a folder"
  )
  expect_error(
    sp_dir_copy(paste0(root, "/b/c"), paste0(root, "/a"), drive = drive),
    "overwrite"
  )

  # With overwrite = TRUE, a folder copy is merged into an existing folder
  expect_identical(
    sp_dir_copy(
      paste0(root, "/b"),
      paste0(root, "/a"),
      overwrite = TRUE,
      drive = drive
    ),
    paste0(root, "/a")
  )
  expect_setequal(
    sp_dir_ls(paste0(root, "/a"), drive = drive),
    c("c", "file.txt", "renamed.txt")
  )
  expect_setequal(sp_dir_ls(paste0(root, "/a/c"), drive = drive), "file.txt")

  # Moving a file can replace an existing file
  expect_error(
    sp_item_move(
      paste0(root, "/a/renamed.txt"),
      paste0(root, "/a/file.txt"),
      drive = drive
    ),
    "overwrite"
  )
  expect_identical(
    sp_item_move(
      paste0(root, "/a/renamed.txt"),
      paste0(root, "/a/file.txt"),
      overwrite = TRUE,
      drive = drive
    ),
    paste0(root, "/a/file.txt")
  )
  expect_setequal(
    sp_dir_ls(paste0(root, "/a"), drive = drive),
    c("c", "file.txt")
  )

  # Copy a file into a folder URL
  dir_url <- paste0(
    "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/",
    root,
    "/b/c"
  )

  expect_identical(
    sp_item_copy(paste0(root, "/b/renamed.txt"), dir_url, drive = drive),
    paste0(root, "/b/c/renamed.txt")
  )
  expect_setequal(
    sp_dir_ls(paste0(root, "/b/c"), drive = drive),
    c("file.txt", "renamed.txt")
  )
})
