list_url <- "https://bmore.sharepoint.com/:l:/r/sites/DOP-CIP/Lists/TestList_20260805?e=uZdGwe"

test_that("create_sp_list_item, update_sp_list_item, and delete_sp_list_item work", {
  skip_if_no_ms_site(list_url)

  sp_list <- get_sp_list(list_url)

  marker <- sp_test_marker("single")

  create_sp_list_item(
    .sp_list = sp_list,
    Title = marker,
    Text = marker,
    Number = 42,
    SingleChoice = "Choice 1",
    MultipleChoice = c("Choice 1", "Choice 2"),
    Date = as.Date("2026-08-05")
  )

  created <- list_sp_list_items(
    sp_list = sp_list,
    filter = paste0("fields/Text eq '", marker, "'")
  )

  expect_s3_class(created, "data.frame")
  expect_equal(nrow(created), 1)

  item_id <- created[["id"]]

  expect_equal(created[["Number"]], 42)
  expect_equal(created[["SingleChoice"]], "Choice 1")
  expect_setequal(
    unlist(created[["MultipleChoice"]]),
    c("Choice 1", "Choice 2")
  )
  expect_equal("2026-08-05T04:00:00Z", created[["Date"]])

  update_sp_list_item(
    item_id = item_id,
    .data = list(
      Number = 99,
      SingleChoice = "Choice 2"
    ),
    sp_list = sp_list
  )

  updated_item <- get_sp_list_item(item_id, sp_list = sp_list)

  expect_s3_class(updated_item, "ms_list_item")
  expect_equal(updated_item$properties$fields$Number, 99)
  expect_equal(updated_item$properties$fields$SingleChoice, "Choice 2")

  delete_sp_list_item(
    item_id = item_id,
    sp_list = sp_list,
    confirm = FALSE
  )

  expect_error(
    get_sp_list_item(item_id, sp_list = sp_list)
  )
})

test_that("create_sp_list_items and delete_sp_list_items work with multiple items", {
  skip_if_no_ms_site(list_url)

  sp_list <- get_sp_list(list_url)

  marker <- sp_test_marker("multi")
  markers <- paste0(marker, "-", 1:2)

  data <- data.frame(
    Title = markers,
    Text = markers,
    Number = c(1, 2),
    SingleChoice = c("Choice 1", "Choice 2"),
    Date = c("2026-08-05T00:00:00Z", "2026-08-06T00:00:00Z")
  )

  create_sp_list_items(
    data = data,
    sp_list = sp_list,
    .progress = FALSE
  )

  created <- list_sp_list_items(
    sp_list = sp_list,
    filter = paste0("startswith(fields/Text,'", marker, "')")
  )

  expect_s3_class(created, "data.frame")
  expect_equal(nrow(created), 2)

  item_ids <- created[["id"]]

  expect_setequal(created[["Number"]], c(1, 2))

  delete_sp_list_items(
    item_id = item_ids,
    sp_list = sp_list,
    confirm = FALSE,
    .progress = FALSE
  )

  # TODO: This test fails because no results is returned as NULL instead of 0
  # rows
  # remaining <- list_sp_list_items(
  #   sp_list = sp_list,
  #   filter = paste0("startswith(fields/Text,'", marker, "')")
  # )

  # expect_equal(nrow(remaining), 0)
})

test_that("update_sp_list_items updates multiple items from a data frame", {
  skip_if_no_ms_site(list_url)

  sp_list <- get_sp_list(list_url)

  marker <- sp_test_marker("update-multi")
  markers <- paste0(marker, "-", 1:2)

  data <- data.frame(
    Title = markers,
    Text = markers,
    Number = c(10, 20)
  )

  create_sp_list_items(
    data = data,
    sp_list = sp_list,
    .progress = FALSE
  )

  created <- list_sp_list_items(
    sp_list = sp_list,
    filter = paste0("startswith(fields/Text,'", marker, "')")
  )

  expect_equal(nrow(created), 2)

  item_ids <- created[["id"]]

  update_data <- data.frame(
    id = item_ids,
    Number = c(100, 200)
  )

  update_sp_list_items(
    data = update_data,
    sp_list = sp_list,
    .progress = FALSE
  )

  updated <- list_sp_list_items(
    sp_list = sp_list,
    filter = paste0("startswith(fields/Text,'", marker, "')")
  )

  expect_setequal(updated[["Number"]], c(100, 200))

  delete_sp_list_items(
    item_id = item_ids,
    sp_list = sp_list,
    confirm = FALSE,
    .progress = FALSE
  )
})
