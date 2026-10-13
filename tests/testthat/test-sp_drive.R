test_that("check_sp_drive_folders normalizes folder paths", {
  expect_identical(
    check_sp_drive_folders(c("/A/", "A/B", "C D/E")),
    c("A", "A/B", "C D/E")
  )
  expect_identical(check_sp_drive_folders(list("A", "B")), c("A", "B"))
  expect_snapshot(error = TRUE, {
    check_sp_drive_folders(1)
    check_sp_drive_folders(c("A", "/A"))
    check_sp_drive_folders(c("", "A|B"))
  })
})

test_that("create_sp_drive errors for a template or a list definition", {
  expect_snapshot(error = TRUE, {
    create_sp_drive("Test", template = "genericList")
    create_sp_drive(
      definition = list(
        displayName = "Test",
        list = list(template = "genericList"),
        columns = list()
      )
    )
    create_sp_drive("Test", folders = "A:B")
  })
})

test_that("create_sp_list errors for folders in a list definition", {
  definition <- as_sp_list_definition(list(
    displayName = "Test",
    list = list(template = "documentLibrary"),
    columns = list(),
    folders = "A"
  ))

  expect_snapshot(
    error = TRUE,
    create_sp_list(definition = definition, template = "genericList")
  )
})

test_that("create_sp_drive creates a library with columns, views, and folders", {
  skip_if_not_installed("yaml12")
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"
  skip_if_no_ms_site(test_site_url)

  definition <- as_sp_list_definition(list(
    displayName = sp_test_marker("drive"),
    description = "Temporary library created by sharepointr tests",
    list = list(template = "documentLibrary"),
    columns = list(
      list(name = "Title", displayName = "Document Title", text = list()),
      list(name = "Status", choice = list(choices = c("Draft", "Final")))
    ),
    views = list(
      list(Title = "All Documents", ViewFields = c("DocIcon", "LinkFilename", "Status")),
      list(Title = "Drafts", ViewFields = c("LinkFilename", "Status"))
    ),
    folders = c("Contracts", "Reports/2026")
  ))

  drive <- suppressMessages(
    create_sp_drive(definition = definition, site_url = test_site_url)
  )

  # The list name is set from the display name, so get the list by id
  sp_list <- suppressMessages(
    get_sp_list(
      list_id = drive$do_operation("list")[["id"]],
      site_url = test_site_url,
      as_data_frame = FALSE
    )
  )

  withr::defer(
    try(
      suppressMessages(delete_sp_list(sp_list = sp_list, confirm = FALSE)),
      silent = TRUE
    )
  )

  expect_s3_class(drive, "ms_drive")
  expect_identical(drive[["properties"]][["name"]], definition[["displayName"]])
  expect_identical(drive[["properties"]][["driveType"]], "documentLibrary")
  expect_setequal(drive$list_files()[["name"]], c("Contracts", "Reports"))

  title <- get_sp_list_column(sp_list = sp_list, column_name = "Title")
  expect_identical(title[["displayName"]], "Document Title")

  views <- list_sp_list_views(sp_list)
  expect_setequal(views[["Title"]], c("All Documents", "Drafts"))

  # The definition from the new library matches without library columns
  live <- suppressMessages(
    get_sp_list_definition(sp_list, include_folders = TRUE)
  )
  expect_identical(
    purrr::map_chr(live[["columns"]], "name"),
    c("Title", "Status")
  )
  expect_identical(live[["folders"]], c("Contracts", "Reports/2026"))

  expect_identical(nrow(compare_sp_list(definition, sp_list = sp_list)), 0L)

  # A new folder is added by sync_sp_list
  updated <- definition
  updated[["folders"]] <- c(updated[["folders"]], "Data")

  changes <- compare_sp_list(updated, sp_list = sp_list)
  expect_identical(changes[["object"]], "folder")
  expect_identical(changes[["name"]], "Data")

  applied <- suppressMessages(
    sync_sp_list(updated, sp_list = sp_list, dry_run = FALSE)
  )
  expect_identical(applied[["status"]], "applied")
  expect_identical(nrow(compare_sp_list(updated, sp_list = sp_list)), 0L)
})
