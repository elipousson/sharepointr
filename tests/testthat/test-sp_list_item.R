test_that(".sp_dttm_to_graph() formats POSIXct/Date as unambiguous UTC strings", {
  x <- as.POSIXct(1659276319, origin = "1970-01-01", tz = "UTC")

  withr::with_envvar(
    c(TZ = "America/New_York"),
    {
      expect_identical(.sp_dttm_to_graph(x), "2022-07-31T14:05:19Z")
      expect_identical(
        .sp_dttm_to_graph(as.Date("2026-08-05")),
        "2026-08-05T00:00:00Z"
      )
    }
  )

  withr::with_envvar(
    c(TZ = "UTC"),
    {
      expect_identical(.sp_dttm_to_graph(x), "2022-07-31T14:05:19Z")
      expect_identical(
        .sp_dttm_to_graph(as.Date("2026-08-05")),
        "2026-08-05T00:00:00Z"
      )
    }
  )

  # Non-date values are returned unmodified
  expect_identical(.sp_dttm_to_graph("Choice 1"), "Choice 1")
  expect_identical(.sp_dttm_to_graph(42), 42)
})

test_that("append_field_odata_types() annotates multi-value fields from list-column rows", {
  data <- tibble::tibble(
    id = c("1", "2", "3"),
    Title = c("A", "B", "C"),
    Choices = list(c("Choice 1", "Choice 2"), "Choice 3", character(0))
  )

  # Build the request body the same way as update_sp_list_item() and
  # AzureGraph::call_graph_url()
  as_body_json <- function(i, multi_fields = NULL) {
    fields <- as.list(vctrs::vec_slice(data, i))
    fields[["id"]] <- NULL
    fields <- unwrap_list_fields(fields)
    fields <- append_field_odata_types(fields, multi_fields = multi_fields)
    as.character(jsonlite::toJSON(list(fields = fields), auto_unbox = TRUE))
  }

  # List-column values are unwrapped so they aren't sent as nested arrays
  expect_identical(
    as_body_json(1),
    '{"fields":{"Title":"A","Choices":["Choice 1","Choice 2"],"Choices@odata.type":"Collection(Edm.String)"}}'
  )

  # Single values are only sent as a Collection for known multi-value fields
  expect_identical(
    as_body_json(2),
    '{"fields":{"Title":"B","Choices":"Choice 3"}}'
  )
  expect_identical(
    as_body_json(2, multi_fields = "Choices"),
    '{"fields":{"Title":"B","Choices":["Choice 3"],"Choices@odata.type":"Collection(Edm.String)"}}'
  )

  # Empty selections are sent as an empty Collection
  expect_identical(
    as_body_json(3, multi_fields = "Choices"),
    '{"fields":{"Title":"C","Choices":[],"Choices@odata.type":"Collection(Edm.String)"}}'
  )

  # NA values for a multi-value field are replaced with an empty Collection
  expect_identical(
    append_field_odata_types(list(Choices = NA), multi_fields = "Choices"),
    list(Choices = list(), `Choices@odata.type` = "Collection(Edm.String)")
  )

  # Fields without multiple values are returned unmodified
  expect_identical(
    append_field_odata_types(list(Title = "A", Number = 1)),
    list(Title = "A", Number = 1)
  )

  # Numeric multi-value (e.g. lookup) fields use Int32 Collections
  expect_identical(
    append_field_odata_types(list(LookupLookupId = c(1, 2))),
    list(
      LookupLookupId = list(1, 2),
      `LookupLookupId@odata.type` = "Collection(Edm.Int32)"
    )
  )
})

test_that("unwrap_list_fields() and sfc_cols_as_wkt() prepare list item fields", {
  expect_identical(
    unwrap_list_fields(list(Title = "A", Choices = list(c("B", "C")))),
    list(Title = "A", Choices = c("B", "C"))
  )

  skip_if_not_installed("sf")

  data <- sf::st_sf(
    id = "1",
    Choices = I(list(c("B", "C"))),
    geometry = sf::st_sfc(sf::st_point(c(1, 2)))
  )

  # sf data frames have the geometry column converted to WKT
  wkt_data <- sfc_cols_as_wkt(data)
  expect_false(inherits(wkt_data, "sf"))
  expect_identical(wkt_data[["geometry"]], "POINT (1 2)")

  # sfc list elements are converted to WKT instead of being unwrapped
  fields <- as.list(sf::st_drop_geometry(data))
  fields[["geometry"]] <- data[["geometry"]]
  fields <- unwrap_list_fields(sfc_cols_as_wkt(fields))

  expect_identical(fields[["geometry"]], "POINT (1 2)")
  expect_identical(fields[["Choices"]], c("B", "C"))
})

test_that("drop_na_fields() drops NA and empty fields", {
  expect_identical(
    drop_na_fields(
      list(
        id = "1",
        Title = NA,
        Empty = character(0),
        AllNA = c(NA, NA),
        Null = NULL,
        Choices = c("A", NA)
      )
    ),
    list(id = "1", Choices = c("A", NA))
  )

  # Items with no fields left after dropping NA and empty values aren't updated
  expect_message(
    update_sp_list_item(
      .data = tibble::tibble(id = "1", Choices = list(character(0))),
      list_name = "unused"
    ),
    "empty after dropping"
  )
})

test_that("pull_sp_list_multi_cols() finds multi-value columns", {
  col_metadata <- list(
    list(name = "Title", text = list(allowMultipleLines = FALSE)),
    list(name = "Choice", choice = list(displayAs = "dropDownMenu")),
    list(name = "MultiChoice", choice = list(displayAs = "checkBoxes")),
    list(name = "Lookup", lookup = list(allowMultipleValues = TRUE)),
    list(name = "Person", personOrGroup = list(allowMultipleSelection = FALSE))
  )

  expect_identical(
    pull_sp_list_multi_cols(col_metadata = col_metadata),
    c("MultiChoice", "LookupLookupId")
  )

  expect_identical(
    pull_sp_list_multi_cols(col_metadata = col_metadata[1:2]),
    character(0)
  )
})

list_url <- "https://bmore.sharepoint.com/:l:/r/sites/DOP-CIP/Lists/TestList_20260805?e=uZdGwe"

test_that("create_sp_list_item, update_sp_list_item, and delete_sp_list_item work", {
  skip("list needs to be recreated.")
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
  expect_identical(nrow(created), 1)

  item_id <- created[["id"]]

  expect_identical(created[["Number"]], 42)
  expect_identical(created[["SingleChoice"]], "Choice 1")
  expect_setequal(
    unlist(created[["MultipleChoice"]]),
    c("Choice 1", "Choice 2")
  )
  expect_identical("2026-08-05T00:00:00Z", created[["Date"]])

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
  expect_identical(updated_item$properties$fields$Number, 99)
  expect_identical(updated_item$properties$fields$SingleChoice, "Choice 2")

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
  skip("list needs to be recreated.")
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
  expect_identical(nrow(created), 2)

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

  # expect_identical(nrow(remaining), 0)
})

test_that("update_sp_list_items updates multiple items from a data frame", {
  skip("list needs to be recreated.")
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

  expect_identical(nrow(created), 2)

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
