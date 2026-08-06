test_that("get_sp_list, get_sp_list_items, and get_sp_list_item works", {
  list_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Employees/Staff%20Directory.aspx"

  skip_if_no_ms_site(list_url)

  sp_list <- get_sp_list(
    list_url
  )

  expect_s3_class(
    sp_list,
    "ms_list"
  )

  expect_s3_class(
    get_sp_list_metadata(sp_list = sp_list),
    "data.frame"
  )

  sp_list_items <- get_sp_list_items(
    sp_list = sp_list,
    n = 2
  )

  expect_s3_class(
    sp_list_items,
    "data.frame"
  )

  withr::with_tempdir(
    {
      download_sp_list(
        sp_list = sp_list,
        new_path = "Staff-Directory.csv"
      )

      expect_true(
        fs::file_exists("Staff-Directory.csv")
      )
    }
  )
})

test_that("get_sp_list_column works", {
  list_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Employees/Staff%20Directory.aspx"

  skip_if_no_ms_site(list_url)

  sp_list <- get_sp_list(
    list_url
  )

  sp_list_column <- get_sp_list_column(
    column_name = "Notes",
    sp_list = sp_list
  )

  expect_type(
    sp_list_column,
    "list"
  )

  expect_named(
    sp_list_column,
    c(
      "@odata.context",
      "columnGroup",
      "description",
      "displayName",
      "enforceUniqueValues",
      "hidden",
      "id",
      "indexed",
      "name",
      "readOnly",
      "required",
      "text"
    )
  )
})

test_that("create_sp_list, update_sp_list, and delete_sp_list work", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"

  skip_if_no_ms_site(test_site_url)

  list_name <- sp_test_marker("create-list")

  sp_list <- create_sp_list(
    list_name = list_name,
    description = "Temporary list created by sharepointr tests",
    site_url = test_site_url,
    columns = create_column_definition_list(
      data.frame(
        name = c("TextColumn", "NumberColumn"),
        type = c("text", "number")
      )
    )
  )

  expect_s3_class(sp_list, "ms_list")

  withr::defer(
    try(
      delete_sp_list(
        sp_list = sp_list,
        confirm = FALSE
      ),
      silent = TRUE
    )
  )

  expect_equal(sp_list[["properties"]][["displayName"]], list_name)

  update_sp_list(
    sp_list = sp_list,
    description = "Updated description"
  )

  updated_list <- get_sp_list(
    list_id = sp_list[["properties"]][["id"]],
    site_url = test_site_url
  )

  expect_equal(
    updated_list[["properties"]][["description"]],
    "Updated description"
  )

  list_id <- sp_list[["properties"]][["id"]]

  delete_sp_list(
    sp_list = sp_list,
    confirm = FALSE
  )

  expect_error(
    get_sp_list(list_id = list_id, site_url = test_site_url)
  )
})

test_that("create_sp_list_column, update_sp_list_column, and delete_sp_list_column work", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"

  skip_if_no_ms_site(test_site_url)

  list_name <- sp_test_marker("list-column")

  sp_list <- create_sp_list(
    list_name = list_name,
    description = "Temporary list created by sharepointr tests",
    site_url = test_site_url
  )

  withr::defer(
    try(
      delete_sp_list(
        sp_list = sp_list,
        confirm = FALSE
      ),
      silent = TRUE
    )
  )

  create_sp_list_column(
    sp_list = sp_list,
    column_name = "TextColumn",
    .col_type = "text"
  )

  created_column <- get_sp_list_column(
    sp_list = sp_list,
    column_name = "TextColumn"
  )

  expect_equal(created_column[["name"]], "TextColumn")
  expect_true(has_name(created_column, "text"))

  update_sp_list_column(
    sp_list = sp_list,
    column_name = "TextColumn",
    description = "Updated column description"
  )

  updated_column <- get_sp_list_column(
    sp_list = sp_list,
    column_name = "TextColumn"
  )

  expect_equal(updated_column[["description"]], "Updated column description")

  delete_sp_list_column(
    sp_list = sp_list,
    column_name = "TextColumn"
  )

  expect_error(
    get_sp_list_column(
      sp_list = sp_list,
      column_name = "TextColumn"
    )
  )
})
