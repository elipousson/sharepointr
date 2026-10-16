test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

# ---- Local validation (no SharePoint access required) ----

test_that("update_sp_item_properties checks its inputs", {
  expect_error(update_sp_item_properties("a.txt"), "must be supplied")
  expect_error(
    update_sp_item_properties("a.txt", name = "b/c.txt"),
    "sp_item_move"
  )
  expect_error(update_sp_item_properties("a.txt", name = ""), "folder path")
  expect_error(update_sp_item_properties("a.txt", name = 1), "name")
  expect_error(get_sp_item_properties("a.txt", fields = NA), "fields")
})

# ---- Live SharePoint integration tests ----

test_that("update_sp_item_properties updates fields and renames an item", {
  skip_if_no_ms_site(test_dir_url)

  drive <- get_sp_drive(drive_name = test_dir_url)

  marker <- sp_test_marker("item-properties")
  root <- paste0("General/", marker)

  withr::defer(
    try(
      delete_sp_item(path = root, drive = drive, confirm = FALSE),
      silent = TRUE
    )
  )

  sp_dir_create(root, drive = drive)

  local_dir <- withr::local_tempdir()
  local_files <- fs::path(local_dir, c("a.txt", "b.txt"))
  for (file in local_files) {
    writeLines("sharepointr update_sp_item_properties() test file", file)
    upload_sp_item(file = file, dest = root, drive = drive)
  }

  # Update a library column value
  props <- update_sp_item_properties(
    paste0(root, "/a.txt"),
    Title = marker,
    drive = drive
  )

  expect_identical(props[["name"]], "a.txt")

  item <- get_sp_item(paste0(root, "/a.txt"), drive = drive)

  # Get the fields as a list element
  props <- get_sp_item_properties(
    item_id = item$properties$id,
    drive = drive,
    fields = TRUE
  )

  expect_identical(props[["name"]], "a.txt")
  expect_identical(props[["fields"]][["Title"]], marker)
  expect_identical(props[["fields"]][["FileLeafRef"]], "a.txt")
  expect_false(any(startsWith(names(props[["fields"]]), "@odata.")))

  # Get the fields as a list column with a 1 row data frame
  props_df <- get_sp_item_properties(
    paste0(root, "/a.txt"),
    drive = drive,
    fields = TRUE,
    as_data_frame = TRUE
  )

  expect_identical(nrow(props_df), 1L)
  expect_type(props_df[["fields"]], "list")
  expect_s3_class(props_df[["fields"]][[1]], "data.frame")
  expect_identical(nrow(props_df[["fields"]][[1]]), 1L)
  expect_identical(props_df[["fields"]][[1]][["Title"]], marker)

  # The fields id is the list item id, not the drive item id
  expect_false(identical(props_df[["fields"]][[1]][["id"]], props_df[["id"]]))

  # Rename the item
  props <- update_sp_item_properties(item = item, name = "c.txt")

  expect_identical(props[["name"]], "c.txt")
  expect_setequal(sp_dir_ls(root, drive = drive), c("b.txt", "c.txt"))

  # Renaming to an existing name is an error
  expect_error(
    update_sp_item_properties(item = item, name = "b.txt"),
    "Can't rename"
  )

  # Return a data frame with the updated fields
  props_df <- update_sp_item_properties(
    item = item,
    Title = "updated",
    fields = TRUE,
    as_data_frame = TRUE
  )

  expect_s3_class(props_df, "data.frame")
  expect_identical(nrow(props_df), 1L)
  expect_identical(props_df[["fields"]][[1]][["Title"]], "updated")
  expect_identical(props_df[["fields"]][[1]][["FileLeafRef"]], "c.txt")

  # A drive item without fields (the drive root) is an error
  expect_error(
    get_sp_item_properties("/", drive = drive, fields = TRUE),
    "document library"
  )
})
