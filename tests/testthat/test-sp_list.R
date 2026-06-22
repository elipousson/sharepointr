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

  sp_list_items <- get_sp_list_items(
    sp_list = sp_list,
    n = 2
  )

  expect_s3_class(
    sp_list_items,
    "data.frame"
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
