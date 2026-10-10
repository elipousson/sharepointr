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

  # Multi-value lookup ID fields use Int32 Collections even if the ID values
  # are strings
  expect_identical(
    append_field_odata_types(list(LookupLookupId = c(1, 2))),
    list(
      LookupLookupId = list(1L, 2L),
      `LookupLookupId@odata.type` = "Collection(Edm.Int32)"
    )
  )
  expect_identical(
    append_field_odata_types(
      list(PersonLookupId = "7"),
      multi_fields = "PersonLookupId"
    ),
    list(
      PersonLookupId = list(7L),
      `PersonLookupId@odata.type` = "Collection(Edm.Int32)"
    )
  )
  expect_identical(
    append_field_odata_types(
      list(PersonLookupId = NA),
      multi_fields = "PersonLookupId"
    ),
    list(
      PersonLookupId = list(),
      `PersonLookupId@odata.type` = "Collection(Edm.Int32)"
    )
  )
  expect_error(
    append_field_odata_types(list(PersonLookupId = c("7", "a@example.com"))),
    "must be whole numbers"
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

test_that("is_list_of_records() and as_sp_item_ids() handle list of records inputs", {
  records <- list(
    list(id = "1", Title = "A"),
    list(id = "2", Choices = c("B", "C"))
  )

  expect_true(is_list_of_records(records))
  expect_false(is_list_of_records(list(id = "1", Title = "A")))
  expect_false(is_list_of_records(set_names(records, c("1", "2"))))
  expect_false(is_list_of_records(data.frame(id = "1")))
  expect_false(is_list_of_records(list(list("1", "A"))))

  expect_identical(as_sp_item_ids(records), c("1", "2"))
  expect_error(
    as_sp_item_ids(list(list(id = "1"), list(Title = "B"), list(id = NA))),
    "Items with a missing or invalid .*id.* value: 2 and 3"
  )
})

test_that("as_list_of_records() wraps a single record or unnames a list of records", {
  record <- list(id = "1", Title = "A", Choices = c("B", "C"))
  records <- list(list(id = "1"), list(id = "2", Title = "B"))

  expect_identical(as_list_of_records(record), list(record))
  expect_identical(as_list_of_records(set_names(records, c("a", "b"))), records)
  expect_identical(as_list_of_records(records), records)
  expect_identical(
    as_list_of_records(list(item_id = "1"), .id = "item_id"),
    list(list(item_id = "1"))
  )

  # Other named lists are returned unmodified
  columns <- list(id = c("1", "2"), Title = c("A", "B"))
  expect_identical(as_list_of_records(columns), columns)
  expect_identical(as_list_of_records(list(Title = "A")), list(Title = "A"))
  expect_identical(as_list_of_records(c("1", "2")), c("1", "2"))
})

test_that(".sp_extract_list_values() keeps items after an empty first page", {
  # Simplified pages of list items: an id column and a fields data frame column
  item_page <- function(ids) {
    page <- data.frame(id = ids)
    page$fields <- data.frame(ProgramVersion = rep("v2", length(ids)))
    page
  }

  pages <- list(
    page2 = list(value = list(), `@odata.nextLink` = "page3"),
    page3 = list(value = item_page(c("1", "2")), `@odata.nextLink` = "page4"),
    page4 = list(value = item_page("3"))
  )

  local_mocked_bindings(
    call_graph_url = function(token, url, ..., simplify = FALSE) {
      pages[[url]]
    },
    .package = "AzureGraph"
  )

  # Filtered queries on a large list can return empty pages first, which
  # AzureGraph parses as list() instead of a data frame
  new_pager <- function() {
    AzureGraph::ms_graph_pager$new(
      token = NULL,
      first_page = list(value = list(), `@odata.nextLink` = "page2")
    )
  }

  values <- .sp_extract_list_values(new_pager(), n = Inf)
  expect_s3_class(values, "data.frame")
  expect_identical(values$id, c("1", "2", "3"))
  expect_identical(values$fields$ProgramVersion, rep("v2", 3))

  expect_identical(.sp_extract_list_values(new_pager(), n = 2)$id, c("1", "2"))

  pages$page3 <- list(value = list())
  expect_null(.sp_extract_list_values(new_pager(), n = Inf))
})

test_that("update_sp_list_items() updates items from a data frame or a list of records", {
  col_metadata <- list(
    list(name = "Title", text = list(allowMultipleLines = FALSE)),
    list(name = "Choices", choice = list(displayAs = "checkBoxes")),
    list(name = "Modified", readOnly = TRUE, dateTime = list())
  )

  n_metadata_calls <- 0

  local_mocked_bindings(
    get_sp_list_metadata = function(..., as_data_frame = TRUE) {
      n_metadata_calls <<- n_metadata_calls + 1
      col_metadata
    }
  )

  # Minimal stand-in for a Microsoft365R::ms_list that records update calls
  updates <- new.env()
  updates$calls <- list()
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$do_operation <- function(op, body, encode, http_verb) {
    expect_identical(http_verb, "PATCH")
    updates$calls[[sub("^items/", "", op)]] <- body[["fields"]]
  }

  records <- list(
    list(id = "1", Title = "A", Other = "dropped", Modified = "dropped"),
    list(id = "2", Choices = c("B", "C")),
    list(id = "3", Choices = "D")
  )

  expect_message(
    update_sp_list_items(records, sp_list = sp_list, .progress = FALSE),
    "Other"
  )

  # List metadata is only requested once (for both validation and multi-value
  # fields), not for each item
  expect_identical(n_metadata_calls, 1)

  # Fields missing from a record are not sent
  expect_identical(updates$calls[["1"]], list(Title = "A"))
  expect_identical(
    updates$calls[["2"]],
    list(
      Choices = list("B", "C"),
      `Choices@odata.type` = "Collection(Edm.String)"
    )
  )
  expect_identical(
    updates$calls[["3"]],
    list(
      Choices = list("D"),
      `Choices@odata.type` = "Collection(Edm.String)"
    )
  )

  updates$calls <- list()

  data <- tibble::tibble(
    id = c("1", "2"),
    Title = c("A", NA),
    Choices = list(character(0), c("B", "C"))
  )

  update_sp_list_items(data, sp_list = sp_list, .progress = FALSE)

  # NA and empty values are dropped with the default `na_fields = "drop"`
  expect_identical(updates$calls[["1"]], list(Title = "A"))
  expect_identical(
    updates$calls[["2"]],
    list(
      Choices = list("B", "C"),
      `Choices@odata.type` = "Collection(Edm.String)"
    )
  )

  updates$calls <- list()

  # A single named list record updates one item with all of its fields
  record <- list(id = "1", Title = "A", Choices = "B")
  expect_identical(
    update_sp_list_items(record, sp_list = sp_list, .progress = FALSE),
    record
  )
  expect_identical(
    updates$calls[["1"]],
    list(
      Title = "A",
      Choices = list("B"),
      `Choices@odata.type` = "Collection(Edm.String)"
    )
  )

  updates$calls <- list()

  update_sp_list_items(
    list(a = list(id = "1", Title = "A"), b = list(id = "2", Title = "B")),
    sp_list = sp_list,
    .progress = FALSE
  )
  expect_identical(names(updates$calls), c("1", "2"))

  expect_error(
    update_sp_list_items(list(Title = "A"), sp_list = sp_list),
    "must be a data frame, a named list for a single item"
  )
  expect_error(
    update_sp_list_items(
      list(id = c("1", "2"), Title = c("A", "B")),
      sp_list = sp_list
    ),
    "must be a data frame, a named list for a single item"
  )
  expect_error(
    update_sp_list_items(data.frame(Title = "A"), sp_list = sp_list),
    "must have a column named"
  )
})

test_that("create_sp_list_items() creates items with multi-value fields", {
  col_metadata <- list(
    list(name = "Title", text = list(allowMultipleLines = FALSE)),
    list(name = "Choices", choice = list(displayAs = "checkBoxes")),
    list(name = "Modified", readOnly = TRUE, dateTime = list())
  )

  n_metadata_calls <- 0

  local_mocked_bindings(
    get_sp_list_metadata = function(..., as_data_frame = TRUE) {
      n_metadata_calls <<- n_metadata_calls + 1
      col_metadata
    }
  )

  # Minimal stand-in for a Microsoft365R::ms_list that records create calls
  creates <- new.env()
  creates$bodies <- list()
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$do_operation <- function(op, body, http_verb) {
    creates$bodies <- c(creates$bodies, list(body))
  }

  data <- tibble::tibble(
    Title = c("A", "B"),
    Choices = list(c("C", "D"), "E"),
    Modified = c("dropped", "dropped")
  )

  expect_message(
    create_sp_list_items(data, sp_list = sp_list, .progress = FALSE),
    "Modified"
  )

  # List metadata is only requested once (for both validation and multi-value
  # fields)
  expect_identical(n_metadata_calls, 1)

  expect_identical(
    creates$bodies,
    list(
      list(
        fields = list(
          Title = "A",
          Choices = list("C", "D"),
          `Choices@odata.type` = "Collection(Edm.String)"
        )
      ),
      list(
        fields = list(
          Title = "B",
          Choices = list("E"),
          `Choices@odata.type` = "Collection(Edm.String)"
        )
      )
    )
  )
})

test_that("delete_sp_list_items() accepts ids, a data frame, or a list of records", {
  # Minimal stand-in for a Microsoft365R::ms_list that records delete calls
  deletes <- new.env()
  deletes$ops <- character(0)
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$do_operation <- function(op, http_verb) {
    deletes$ops <- c(deletes$ops, paste(http_verb, op))
  }

  expected_ops <- c("DELETE items/1", "DELETE items/2")

  delete_ids <- function(item_id) {
    deletes$ops <- character(0)
    delete_sp_list_items(
      item_id,
      sp_list = sp_list,
      confirm = FALSE,
      .progress = FALSE
    )
    deletes$ops
  }

  expect_identical(delete_ids(c("1", "2")), expected_ops)
  expect_identical(
    delete_ids(data.frame(id = c("1", "2"), Title = c("A", "B"))),
    expected_ops
  )
  expect_identical(
    delete_ids(list(list(id = "1", Title = "A"), list(id = "2"))),
    expected_ops
  )

  expect_identical(
    delete_ids(list(a = list(id = "1"), b = list(id = "2"))),
    expected_ops
  )
  expect_identical(delete_ids(list("1", "2")), expected_ops)

  # A single record deletes one item (not one item per element)
  expect_identical(
    delete_ids(list(id = "1", Title = "A")),
    "DELETE items/1"
  )

  expect_error(
    delete_ids(list(list(id = "1"), list(Title = "B"))),
    "Item with a missing or invalid .*id.* value: 2"
  )
  expect_error(
    delete_ids(list(Title = "A", Status = "B")),
    "a named list for a single item"
  )
  expect_error(
    delete_ids(list(id = c("1", "2"))),
    "a named list for a single item"
  )

  # Alternate id column or element names are supported with `.id`
  delete_item_ids <- function(item_id) {
    deletes$ops <- character(0)
    delete_sp_list_items(
      item_id,
      .id = "item_id",
      sp_list = sp_list,
      confirm = FALSE,
      .progress = FALSE
    )
    deletes$ops
  }

  expect_identical(
    delete_item_ids(data.frame(item_id = c("1", "2"))),
    expected_ops
  )
  expect_identical(
    delete_item_ids(list(list(item_id = "1"), list(item_id = "2"))),
    expected_ops
  )
  expect_error(
    delete_item_ids(data.frame(id = c("1", "2"))),
    "must have a column named"
  )
})

test_that("delete_sp_list_item() gets the item id from a data frame first", {
  local_mocked_bindings(
    get_sp_list_item = function(id, ...) {
      # Minimal stand-in for a Microsoft365R::ms_list_item
      sp_list_item <- structure(
        new.env(),
        class = c("ms_list_item", "ms_object")
      )
      sp_list_item$id <- id
      sp_list_item$do_operation <- function(http_verb) {
        paste(http_verb, sp_list_item$id)
      }
      sp_list_item
    }
  )

  expect_identical(
    delete_sp_list_item(
      data.frame(id = "1", Title = "A"),
      sp_list = "unused",
      confirm = FALSE
    ),
    "DELETE 1"
  )

  # Alternate id column names are supported with `.id`
  expect_identical(
    delete_sp_list_item(
      data.frame(item_id = "2", Title = "B"),
      .id = "item_id",
      sp_list = "unused",
      confirm = FALSE
    ),
    "DELETE 2"
  )
  expect_error(
    delete_sp_list_item(
      data.frame(Title = "B"),
      sp_list = "unused",
      confirm = FALSE
    ),
    "must have a column named"
  )
})

# Minimal stand-in for a Microsoft365R::ms_list that records item requests
local_fake_item_list <- function(env = parent.frame()) {
  requests <- new.env()
  requests$updates <- list()
  requests$creates <- list()
  requests$deletes <- character(0)
  requests$n_get_list <- 0
  requests$n_metadata <- 0

  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$do_operation <- function(op, body = NULL, encode = NULL, http_verb = "GET") {
    if (http_verb == "DELETE") {
      requests$deletes <- c(requests$deletes, op)
    } else if (http_verb == "PATCH") {
      requests$updates <- c(
        requests$updates,
        list(list(id = sub("^items/", "", op), fields = body[["fields"]]))
      )
    } else {
      requests$creates <- c(requests$creates, list(body[["fields"]]))
    }
  }

  local_mocked_bindings(
    get_sp_list = function(...) {
      requests$n_get_list <- requests$n_get_list + 1
      sp_list
    },
    get_sp_list_metadata = function(...) {
      requests$n_metadata <- requests$n_metadata + 1
      list(
        list(name = "Title", text = list()),
        list(name = "Choices", choice = list(displayAs = "checkBoxes"))
      )
    },
    .env = env
  )

  requests$sp_list <- sp_list
  requests
}

test_that("as_sp_item_ids() validates and returns character item ids", {
  expect_identical(as_sp_item_ids(c(1, 2)), c("1", "2"))
  expect_identical(as_sp_item_ids(1e6), "1000000")
  expect_identical(as_sp_item_ids(data.frame(id = 3:4)), c("3", "4"))
  expect_identical(as_sp_item_ids(list(id = "5", Title = "A")), "5")
  expect_identical(as_sp_item_ids(list("6", 7L)), c("6", "7"))

  expect_error(as_sp_item_ids(c("1", NA)), "Item with a missing or invalid")
  expect_error(as_sp_item_ids(data.frame(id = c(1, NA))), "value: 2")
  expect_error(as_sp_item_ids(c(1.5, 2)), "value: 1")
  expect_error(as_sp_item_ids(""), "value: 1")
  expect_error(
    as_sp_item_ids(list(list(id = TRUE), list(id = c("1", "2")))),
    "value: 1 and 2"
  )
})

test_that("update_sp_list_items() checks item ids before updating any items", {
  requests <- local_fake_item_list()

  expect_error(
    update_sp_list_items(
      data.frame(id = c("1", NA), Title = c("A", "B")),
      sp_list = requests$sp_list,
      .progress = FALSE
    ),
    "value: 2"
  )
  expect_error(
    update_sp_list_items(
      list(list(id = 1.5, Title = "A")),
      sp_list = requests$sp_list,
      .progress = FALSE
    ),
    "value: 1"
  )

  expect_length(requests$updates, 0)
  expect_identical(requests$n_metadata, 0)

  # Numeric ids are sent as strings
  update_sp_list_items(
    data.frame(id = c(1, 2), Title = c("A", "B")),
    sp_list = requests$sp_list,
    .progress = FALSE
  )
  expect_identical(purrr::map_chr(requests$updates, "id"), c("1", "2"))
})

test_that("update_sp_list_items() and create_sp_list_items() return the input invisibly", {
  requests <- local_fake_item_list()
  data <- data.frame(id = "1", Title = "A", Other = "dropped")

  expect_invisible(
    out <- suppressMessages(
      update_sp_list_items(data, sp_list = requests$sp_list, .progress = FALSE)
    )
  )
  expect_identical(out, data)

  expect_invisible(
    out <- suppressMessages(
      create_sp_list_items(data[-1], sp_list = requests$sp_list, .progress = FALSE)
    )
  )
  expect_identical(out, data[-1])

  # Empty input is also returned invisibly
  empty <- data[0, ]
  expect_invisible(
    out <- suppressMessages(update_sp_list_items(empty, sp_list = requests$sp_list))
  )
  expect_identical(out, empty)
  expect_invisible(
    out <- suppressMessages(create_sp_list_items(empty, sp_list = requests$sp_list))
  )
  expect_identical(out, empty)
})

test_that("create_sp_list_items() creates items from a list of records", {
  requests <- local_fake_item_list()

  records <- list(
    list(Title = "A", Choices = c("C", "D"), Other = "dropped"),
    list(Title = "B")
  )

  expect_message(
    out <- create_sp_list_items(records, sp_list = requests$sp_list, .progress = FALSE),
    "Other"
  )
  expect_identical(out, records)
  expect_identical(
    requests$creates,
    list(
      list(
        Title = "A",
        Choices = list("C", "D"),
        `Choices@odata.type` = "Collection(Edm.String)"
      ),
      list(Title = "B")
    )
  )

  # Invalid input errors before any API calls
  expect_error(
    create_sp_list_items(list(Title = "A"), list_name = "Test"),
    "Use `list\\(record\\)` for a single item"
  )
  expect_error(
    create_sp_list_items(records, list_name = "Test", create_list = TRUE),
    "must be a data frame when `create_list = TRUE`"
  )
  expect_identical(requests$n_get_list, 0)
})

test_that("update_sp_list_item() uses `.id` to check for empty data", {
  requests <- local_fake_item_list()

  expect_message(
    update_sp_list_item(
      .data = list(ID = "5", Title = NA),
      .id = "ID",
      sp_list = requests$sp_list,
      check_fields = FALSE
    ),
    "empty after dropping"
  )

  # No fields at all
  expect_message(
    update_sp_list_item(item_id = "5", sp_list = requests$sp_list),
    "empty after dropping"
  )

  expect_length(requests$updates, 0)
})

test_that("delete_sp_list_item() and delete_sp_list_items() check arguments", {
  requests <- local_fake_item_list()

  expect_error(
    delete_sp_list_item(item_id = "1", sp_list = requests$sp_list, cofirm = FALSE),
    "must be empty"
  )
  expect_error(
    delete_sp_list_item(
      data.frame(id = c("1", "2")),
      sp_list = requests$sp_list,
      confirm = FALSE
    ),
    "must be a single item id, not 2"
  )
  expect_error(
    delete_sp_list_items(
      "1",
      sp_list = requests$sp_list,
      filter = "fields/Title eq 'A'",
      confirm = FALSE
    ),
    "not both"
  )
  expect_error(
    delete_sp_list_items(
      c("1", NA),
      sp_list = requests$sp_list,
      confirm = FALSE,
      .progress = FALSE
    ),
    "value: 2"
  )

  expect_length(requests$deletes, 0)
})

test_that("match_sp_list_field_names() matches names to list fields", {
  values <- c("Title", "Status", "ContentType")

  expect_identical(
    match_sp_list_field_names(c("Title", "ProjectLookupId"), values),
    c(TRUE, TRUE)
  )
  expect_identical(match_sp_list_field_names(character(0), values), logical(0))

  expect_snapshot({
    match_sp_list_field_names(c("Title", "Other", "ContentType"), values)
    match_sp_list_field_names(c("Title", "Other"), values, what = "field")
  })
  expect_snapshot(
    match_sp_list_field_names("Other", values, what = "field"),
    error = TRUE
  )
  expect_snapshot(
    match_sp_list_field_names(c("Title", "Other"), values, strict = TRUE),
    error = TRUE
  )
})

test_that("update_sp_list_items() supports strict field matching", {
  requests <- local_fake_item_list()

  expect_error(
    update_sp_list_items(
      list(list(id = "1", Title = "A", Other = "B")),
      sp_list = requests$sp_list,
      strict = TRUE,
      .progress = FALSE
    ),
    "All field names in `data` must match"
  )
  expect_error(
    update_sp_list_items(
      data.frame(id = "1", Title = "A", Other = "B"),
      sp_list = requests$sp_list,
      strict = TRUE,
      .progress = FALSE
    ),
    "All column names in `data` must match"
  )

  expect_length(requests$updates, 0)
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

test_that("sp_list_as_ptype_data_frame() builds a ptype for every list column", {
  col_metadata <- list(
    list(name = "ID", number = list()),
    list(name = "Title", text = list()),
    list(name = "Amount", currency = list()),
    list(name = "Done", boolean = list()),
    list(name = "Status", choice = list(choices = list("A", "B"))),
    list(
      name = "Tags",
      choice = list(choices = list("A", "B"), displayAs = "checkBoxes")
    ),
    list(name = "Due", dateTime = list(format = "dateOnly")),
    list(name = "Person", personOrGroup = list(allowMultipleSelection = FALSE)),
    list(name = "Related", lookup = list(allowMultipleValues = TRUE)),
    list(name = "Link", hyperlinkOrPicture = list()),
    list(name = "ItemChildCount", lookup = list())
  )

  ptype <- sp_list_as_ptype_data_frame(col_metadata = col_metadata)

  expect_identical(nrow(ptype), 0L)
  expect_named(
    ptype,
    c(
      "@odata.etag",
      "id",
      "Title",
      "Amount",
      "Done",
      "Status",
      "Tags",
      "Due",
      "PersonLookupId",
      "RelatedLookupId",
      "Link",
      "ItemChildCount"
    )
  )
  expect_identical(ptype[["Title"]], character())
  expect_identical(ptype[["Amount"]], double())
  expect_identical(ptype[["Done"]], logical())
  expect_identical(ptype[["Due"]], character())
  expect_identical(ptype[["PersonLookupId"]], character())
  expect_identical(ptype[["Tags"]], list())
  expect_identical(ptype[["RelatedLookupId"]], list())
  expect_s3_class(ptype[["id"]], "vctrs_unspecified")
  expect_s3_class(ptype[["Link"]], "vctrs_unspecified")
  expect_s3_class(ptype[["ItemChildCount"]], "vctrs_unspecified")

  # Blank columns are filled in list order and multi-value columns keep the
  # same type whether or not they have values
  fields <- data.frame(id = "1", Amount = 2L)
  fields[["Tags"]] <- list(c("A", "B"))
  fields[["Extra"]] <- "x"

  items <- vctrs::vec_rbind(ptype, fields)

  expect_named(items, c(names(ptype), "Extra"))
  expect_identical(items[["Amount"]], 2)
  expect_identical(items[["Title"]], NA_character_)
  expect_identical(items[["Tags"]], list(c("A", "B")))
  expect_identical(vctrs::vec_rbind(ptype, NULL)[["Tags"]], list())
})

test_that("sp_list_as_ptype_data_frame() matches select by raw or LookupId name", {
  col_metadata <- list(
    list(name = "ID", number = list()),
    list(name = "Title", text = list()),
    list(name = "Person", personOrGroup = list()),
    list(name = "Related", lookup = list())
  )

  # Raw names (as used by select_type = "editable") and LookupId names both
  # match; unknown names are left for the Graph API to handle
  ptype <- sp_list_as_ptype_data_frame(
    col_metadata = col_metadata,
    select = c("id", "Person", "RelatedLookupId", "Unknown")
  )

  expect_named(ptype, c("@odata.etag", "id", "PersonLookupId", "RelatedLookupId"))
})

test_that("list_sp_list_items() fetches column metadata once for select, formatting, and display names", {
  col_metadata <- list(
    list(name = "ID", displayName = "ID", readOnly = TRUE, number = list()),
    list(name = "Title", displayName = "Item Title", text = list()),
    list(
      name = "Due",
      displayName = "Due Date",
      dateTime = list(format = "dateOnly")
    ),
    list(
      name = "Modified",
      displayName = "Modified",
      readOnly = TRUE,
      dateTime = list(format = "dateTime")
    )
  )

  n_metadata_calls <- 0
  graph_expand <- NULL

  local_mocked_bindings(
    get_sp_list_metadata = function(..., as_data_frame = TRUE) {
      n_metadata_calls <<- n_metadata_calls + 1
      col_metadata
    },
    .sp_extract_list_values = function(pager, ...) {
      fields <- data.frame(
        `@odata.etag` = "1",
        id = "1",
        Due = "2026-08-05T04:00:00Z",
        check.names = FALSE
      )
      values <- data.frame(id = "1")
      values[["fields"]] <- fields
      values
    }
  )

  sp_list <- structure(
    list(
      properties = list(id = "list", parentReference = list(siteId = "site")),
      do_operation = function(op, options, ...) {
        graph_expand <<- options[["expand"]]
        NULL
      },
      get_list_pager = function(...) NULL
    ),
    class = c("ms_list", "ms_object")
  )

  items <- list_sp_list_items(
    sp_list = sp_list,
    select_type = "editable",
    col_formatting = "date",
    display_nm = "label",
    tz = "America/New_York"
  )

  expect_identical(n_metadata_calls, 1)
  expect_identical(graph_expand, "fields(select=ID,Title,Due)")
  expect_named(items, c("@odata.etag", "id", "Title", "Due"))
  expect_equal(items[["Due"]], as.Date("2026-08-05"), ignore_attr = "label")
  expect_identical(attr(items[["Due"]], "label"), "Due Date")
  expect_identical(attr(items[["Title"]], "label"), "Item Title")
})

test_that("format_sp_list_date_cols() formats date and dateTime columns", {
  col_metadata <- list(
    list(name = "Title", text = list()),
    list(name = "Due", dateTime = list(format = "dateOnly")),
    list(name = "Start", dateTime = list(format = "dateTime")),
    list(name = "Missing", dateTime = list(format = "dateOnly"))
  )
  items <- data.frame(
    Title = "A",
    Due = "2026-08-05T04:00:00Z",
    Start = "2026-08-05T14:30:00Z"
  )

  formatted <- format_sp_list_date_cols(items, col_metadata, tz = "UTC")

  expect_identical(formatted[["Title"]], "A")
  expect_identical(formatted[["Due"]], as.Date("2026-08-05"))
  expect_identical(
    formatted[["Start"]],
    as.POSIXct("2026-08-05 14:30:00", tz = "UTC")
  )
  expect_named(formatted, names(items))
})

test_that("update_sp_list_item() sends one PATCH and gets column metadata once", {
  requests <- local_fake_item_list()

  update_sp_list_item(
    .data = list(id = "1", Title = "A", Other = "dropped", Choices = "B"),
    sp_list = requests$sp_list
  )

  # Used for both validating fields and finding multi-value fields
  expect_identical(requests$n_metadata, 1)
  expect_identical(
    requests$updates,
    list(list(
      id = "1",
      fields = list(
        Title = "A",
        Choices = list("B"),
        `Choices@odata.type` = "Collection(Edm.String)"
      )
    ))
  )

  # No metadata is needed if fields aren't checked and multi-value fields are
  # supplied
  update_sp_list_item(
    .data = list(id = "2", Title = "C"),
    sp_list = requests$sp_list,
    check_fields = FALSE,
    .multi_fields = character(0)
  )
  expect_identical(requests$n_metadata, 1)

  # A list item object is updated with a single PATCH (without getting the
  # item again)
  sp_list_item <- structure(new.env(), class = c("ms_list_item", "ms_object"))
  sp_list_item$properties <- list(id = "3")
  sp_list_item$do_operation <- function(op = "", body = NULL, encode = NULL, http_verb = "GET") {
    requests$item_ops <- c(requests$item_ops, list(list(op, http_verb, body)))
  }

  update_sp_list_item(.data = list(Title = "D"), sp_list_item = sp_list_item)
  expect_identical(
    requests$item_ops,
    list(list("", "PATCH", list(fields = list(Title = "D"))))
  )
})

test_that("delete_sp_list_items() finds items with a filter without getting list metadata", {
  requests <- local_fake_item_list()
  sp_list <- requests$sp_list
  sp_list$properties <- list(id = "list", parentReference = list(siteId = "site"))
  sp_list$get_list_pager <- function(...) NULL

  # Accept the arguments used to list items (in addition to deletes)
  do_item_operation <- sp_list$do_operation
  sp_list$do_operation <- function(op, ..., http_verb = "GET") {
    if (http_verb == "DELETE") do_item_operation(op, http_verb = http_verb)
  }

  local_mocked_bindings(
    .sp_extract_list_values = function(pager, ...) {
      values <- data.frame(id = c("4", "5"))
      values[["fields"]] <- data.frame(`@odata.etag` = "1", id = c("4", "5"), check.names = FALSE)
      values
    }
  )

  delete_sp_list_items(
    sp_list = sp_list,
    filter = "fields/Title eq 'A'",
    confirm = FALSE,
    .progress = FALSE
  )

  expect_identical(requests$n_metadata, 0)
  expect_identical(requests$deletes, c("items/4", "items/5"))
})
