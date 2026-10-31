mock_workbook_item <- function() {
  structure(
    list(properties = list(id = "item1", name = "Book.xlsx")),
    class = c("ms_drive_item", "ms_object")
  )
}

mock_sheets <- list(
  value = list(
    list(id = "{2}", name = "Second", position = 1L, visibility = "Visible"),
    list(id = "{1}", name = "First Sheet", position = 0L, visibility = "Visible")
  )
)

test_that("sp_workbook_address() splits a sheet from the range", {
  expect_identical(
    sp_workbook_address("Sheet1!A1:C3", NULL),
    list(sheet = "Sheet1", range = "A1:C3")
  )
  expect_identical(
    sp_workbook_address("'My Sheet'!A1", NULL),
    list(sheet = "My Sheet", range = "A1")
  )
  expect_identical(
    sp_workbook_address("Other!A1", "Given"),
    list(sheet = "Given", range = "A1")
  )
  expect_identical(
    sp_workbook_address(NULL, NULL),
    list(sheet = NULL, range = NULL)
  )
  expect_error(sp_workbook_address(1, NULL), "range")
})

test_that("sp_workbook_range_resize() expands a cell to fit the values", {
  expect_identical(sp_workbook_range_resize("B2", 3, 2), "B2:C4")
  expect_identical(sp_workbook_range_resize("Z1", 1, 3), "Z1:AB1")
  expect_identical(sp_workbook_range_resize("A1:B2", 10, 10), "A1:B2")
  expect_error(sp_workbook_range_resize("not a cell", 1, 1), "cell")
})

test_that("column letter conversion round trips", {
  n <- c(1L, 26L, 27L, 52L, 53L, 702L, 703L, 16384L)
  expect_identical(sp_workbook_col_to_number(sp_workbook_number_to_col(n[[1]])), 1L)
  expect_identical(
    vapply(n, \(i) sp_workbook_col_to_number(sp_workbook_number_to_col(i)), integer(1)),
    n
  )
  expect_identical(sp_workbook_number_to_col(16384L), "XFD")
})

test_that("sp_workbook_values_as_df() converts values to a data frame", {
  values <- list(
    list("name", "n", "mixed"),
    list("a", 1L, 1),
    list("b", 2.5, "x"),
    list("", "", "")
  )

  df <- sp_workbook_values_as_df(values)

  expect_identical(names(df), c("name", "n", "mixed"))
  expect_identical(df[["name"]], c("a", "b", NA))
  expect_identical(df[["n"]], c(1, 2.5, NA))
  expect_identical(df[["mixed"]], c("1", "x", NA))

  expect_identical(
    names(sp_workbook_values_as_df(values, header = FALSE)),
    c("V1", "V2", "V3")
  )
  expect_identical(nrow(sp_workbook_values_as_df(values, header = FALSE)), 4L)
  expect_identical(nrow(sp_workbook_values_as_df(list())), 0L)
})

test_that("sp_workbook_values_as_list() converts R objects to rows", {
  df <- data.frame(a = c(1, NA), b = c("x", "y"))

  expect_identical(
    sp_workbook_values_as_list(df),
    list(list("a", "b"), list(1, "x"), list("", "y"))
  )
  expect_identical(
    sp_workbook_values_as_list(df, col_names = FALSE),
    list(list(1, "x"), list("", "y"))
  )
  expect_identical(
    sp_workbook_values_as_list(c(1, 2)),
    list(list(1), list(2))
  )
  expect_identical(
    sp_workbook_values_as_list(data.frame(d = as.Date("2026-01-02"))),
    list(list("d"), list("2026-01-02"))
  )
  expect_error(sp_workbook_values_as_list(df[0, ]), "at least 1 row")
  expect_error(sp_workbook_values_as_list(list(1)), "data frame")
})

test_that("sp_workbook_sheets() returns a data frame", {
  local_mocked_bindings(sp_workbook_request = function(...) mock_sheets)

  sheets <- sp_workbook_sheets(mock_workbook_item())

  expect_identical(sheets[["name"]], c("Second", "First Sheet"))
  expect_identical(sheets[["position"]], c(1L, 0L))
})

test_that("sp_workbook_range_read() requests the first sheet's used range", {
  paths <- character()

  local_mocked_bindings(
    sp_workbook_request = function(item, path, ...) {
      force(path)
      paths <<- c(paths, path)
      if (path == "worksheets") {
        return(mock_sheets)
      }
      list(values = list(list("a"), list(1L)))
    }
  )

  df <- sp_workbook_range_read(mock_workbook_item())

  expect_identical(paths, c("worksheets", "worksheets/%7B1%7D/usedRange(valuesOnly=true)"))
  expect_equal(df, data.frame(a = 1))
})

test_that("sp_workbook_range_read() requests an encoded sheet and range", {
  path <- NULL

  local_mocked_bindings(
    sp_workbook_request = function(item, path_arg, ...) {
      path <<- path_arg
      list(values = list(list("a")))
    }
  )

  sp_workbook_range_read(mock_workbook_item(), "My Sheet!A1:A1")

  expect_identical(path, "worksheets/My%20Sheet/range(address='A1:A1')")
})

test_that("sp_workbook_range_write() sends values with a PATCH request", {
  args <- NULL

  local_mocked_bindings(
    sp_workbook_request = function(item, path, ...) {
      args <<- list(path = path, ...)
      list(address = "Sheet1!B2:C3")
    }
  )

  out <- sp_workbook_range_write(
    mock_workbook_item(),
    data.frame(a = 1, b = 2),
    "Sheet1!B2",
    session_id = "abc"
  )

  expect_identical(out, "Sheet1!B2:C3")
  expect_identical(args[["path"]], "worksheets/Sheet1/range(address='B2:C3')")
  expect_identical(args[["http_verb"]], "PATCH")
  expect_identical(args[["session_id"]], "abc")
  expect_identical(
    args[["body"]],
    list(values = list(list("a", "b"), list(1, 2)))
  )
})

test_that("sp_workbook_range_write() requires a range", {
  expect_error(
    sp_workbook_range_write(mock_workbook_item(), 1, range = NULL),
    "range"
  )
})

test_that("sp_workbook_session_create() and close send POST requests", {
  calls <- list()

  local_mocked_bindings(
    sp_workbook_request = function(item, path, ...) {
      calls[[length(calls) + 1]] <<- list(path = path, ...)
      list(id = "session1")
    }
  )

  item <- mock_workbook_item()

  expect_identical(
    sp_workbook_session_create(item, persist_changes = FALSE),
    "session1"
  )
  expect_identical(sp_workbook_session_close(item, "session1"), item)

  expect_identical(calls[[1]][["path"]], "createSession")
  expect_identical(calls[[1]][["body"]], list(persistChanges = FALSE))
  expect_identical(calls[[2]][["path"]], "closeSession")
  expect_identical(calls[[2]][["session_id"]], "session1")
})

test_that("sp_workbook_request() adds the session header", {
  args <- NULL

  local_mocked_bindings(
    call_graph_endpoint = function(...) {
      args <<- list(...)
      list()
    },
    .package = "AzureGraph"
  )

  item <- mock_workbook_item()
  item[["properties"]][["parentReference"]] <- list(driveId = "drive1")

  sp_workbook_request(item, "worksheets", session_id = "abc")

  expect_identical(args[[2]], "drives/drive1/items/item1/workbook/worksheets")
  request <- purrr::detect(args, \(x) inherits(x, "request"))
  expect_identical(request[["headers"]][["workbook-session-id"]], "abc")
})

test_that("sp_workbook_session_option() looks up the session for an item", {
  withr::local_options(sharepointr.workbook_session = NULL)
  expect_null(sp_workbook_session_option("item1"))

  options(sharepointr.workbook_session = c(item1 = "s1", item2 = "s2"))
  expect_identical(sp_workbook_session_option("item2"), "s2")
  expect_null(sp_workbook_session_option("item3"))

  options(sharepointr.workbook_session = "any")
  expect_identical(sp_workbook_session_option("item3"), "any")
})

test_that("sp_workbook_request() uses the option unless session_id is set", {
  withr::local_options(sharepointr.workbook_session = c(item1 = "from-option"))

  headers <- list()

  local_mocked_bindings(
    call_graph_endpoint = function(...) {
      request <- purrr::detect(list(...), \(x) inherits(x, "request"))
      headers[[length(headers) + 1]] <<- request[["headers"]][["workbook-session-id"]]
      list()
    },
    .package = "AzureGraph"
  )

  item <- mock_workbook_item()
  item[["properties"]][["parentReference"]] <- list(driveId = "drive1")

  sp_workbook_request(item, "worksheets")
  sp_workbook_request(item, "worksheets", session_id = "explicit")
  sp_workbook_request(item, "worksheets", session_id = FALSE)

  expect_identical(headers[1:2], list("from-option", "explicit"))
  expect_length(headers, 2)
})

test_that("local_sp_workbook_session() sets the option and closes the session", {
  withr::local_options(sharepointr.workbook_session = NULL)

  calls <- character()

  local_mocked_bindings(
    sp_workbook_request = function(item, path, ...) {
      calls <<- c(calls, path)
      list(id = "session1")
    }
  )

  item <- mock_workbook_item()
  during <- NULL

  f <- function() {
    local_sp_workbook_session(item)
    during <<- getOption("sharepointr.workbook_session")
  }

  f()

  expect_identical(during, c(item1 = "session1"))
  expect_null(getOption("sharepointr.workbook_session"))
  expect_identical(calls, c("createSession", "closeSession"))
})
