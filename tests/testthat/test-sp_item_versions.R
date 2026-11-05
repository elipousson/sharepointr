version_record <- function(id, modified, size, name, email, user_id = NULL) {
  list(
    `@microsoft.graph.downloadUrl` = paste0("https://example.com/", id),
    id = id,
    lastModifiedDateTime = modified,
    size = size,
    lastModifiedBy = list(
      user = list(
        email = email,
        id = user_id %||% paste0("id-", name),
        displayName = name
      )
    )
  )
}

test_versions <- list(
  version_record(
    "3.0",
    "2026-10-20T10:00:00Z",
    3000L,
    "Ann",
    "ann@example.com"
  ),
  version_record("2.0", "2026-10-16T20:22:44Z", 2000L, "Bo", "bo@example.com"),
  version_record("1.0", "2026-10-15T08:00:00Z", 1000L, "Ann", "ann@example.com")
)

# A stand-in for a `ms_drive_item` with a `do_operation()` method that records
# requests and returns canned responses
fake_sp_item <- function(versions = test_versions, next_link = NULL) {
  requests <- new.env()
  requests$ops <- list()

  item <- structure(
    list(
      properties = list(
        id = "ITEM1",
        name = "book.xlsx",
        webUrl = "https://example.com/book.xlsx",
        parentReference = list(driveId = "DRIVE1")
      ),
      token = "fake-token",
      requests = requests,
      do_operation = function(op, ..., options = list()) {
        requests$ops[[length(requests$ops) + 1]] <- list(
          op = op,
          options = options
        )

        if (op == "versions") {
          top <- options[["$top"]]
          value <- if (is.null(top)) versions else utils::head(versions, top)
          response <- list(value = value)
          response[["@odata.nextLink"]] <- next_link
          return(response)
        }

        id <- sub("^versions/", "", op)
        purrr::detect(versions, \(x) identical(x[["id"]], id))
      }
    ),
    class = c("ms_drive_item", "ms_object", "R6")
  )

  item
}

# flatten_df_col() -------------------------------------------------------------

test_that("flatten_df_col() flattens nested list columns", {
  data <- data.frame(id = 1:2)
  data$by <- list(
    list(user = list(email = "a@example.com", name = "A")),
    list(user = list(email = "b@example.com", name = "B"))
  )

  out <- flatten_df_col(data, "by")

  expect_equal(names(out), c("id", "by_user_email", "by_user_name"))
  expect_equal(out$by_user_email, c("a@example.com", "b@example.com"))
})

test_that("flatten_df_col() keeps the position of the column", {
  data <- data.frame(id = 1:2)
  data$by <- list(list(name = "A"), list(name = "B"))
  data$size <- c(10, 20)

  out <- flatten_df_col(data, "by")

  expect_equal(names(out), c("id", "by_name", "size"))
})

test_that("flatten_df_col() fills missing values and keeps the row count", {
  data <- data.frame(id = 1:3)
  data$by <- list(list(name = "A"), NULL, list(name = "C", email = "c@x.com"))

  out <- flatten_df_col(data, "by")

  expect_equal(nrow(out), 3L)
  expect_equal(out$by_name, c("A", NA, "C"))
  expect_equal(out$by_email, c(NA, NA, "c@x.com"))
})

test_that("flatten_df_col() flattens data frame columns", {
  data <- data.frame(id = 1:2)
  data$by <- data.frame(name = c("A", "B"), email = c("a@x.com", "b@x.com"))

  out <- flatten_df_col(data, "by", names_sep = ".")

  expect_equal(names(out), c("id", "by.name", "by.email"))
  expect_equal(out$by.name, c("A", "B"))
})

test_that("flatten_df_col() flattens more than one column", {
  data <- data.frame(id = 1:2)
  data$created <- list(list(name = "A"), list(name = "B"))
  data$modified <- list(list(name = "C"), list(name = "D"))

  out <- flatten_df_col(data, c("created", "modified"))

  expect_equal(names(out), c("id", "created_name", "modified_name"))
  expect_equal(out$modified_name, c("C", "D"))
})

test_that("flatten_df_col() `names_sep = NULL` doesn't prefix names", {
  data <- data.frame(id = 1:2)
  data$by <- list(
    list(name = "A", user = list(email = "a@x.com")),
    list(name = "B", user = list(email = "b@x.com"))
  )

  out <- flatten_df_col(data, "by", names_sep = NULL)

  expect_equal(names(out), c("id", "name", "user_email"))
})

test_that("flatten_df_col() checks for name collisions", {
  data <- data.frame(id = 1:2, by_name = c("X", "Y"))
  data$by <- list(list(name = "A"), list(name = "B"))

  expect_error(flatten_df_col(data, "by"), "by_name")

  out <- flatten_df_col(data, "by", names_repair = "unique_quiet")
  expect_equal(nrow(out), 2L)
  expect_equal(ncol(out), 3L)
  expect_false(anyDuplicated(names(out)) > 0)
})

test_that("flatten_df_col() skips columns that are not in data", {
  data <- data.frame(id = 1:2)
  expect_identical(flatten_df_col(data, "missing"), data)

  data$by <- list(list(name = "A"), list(name = "B"))
  out <- flatten_df_col(data, c("missing", "by"))
  expect_equal(names(out), c("id", "by_name"))
})

# list_sp_item_versions() ------------------------------------------------------

test_that("list_sp_item_versions() returns a tidy data frame", {
  out <- list_sp_item_versions(sp_item = fake_sp_item())

  expect_s3_class(out, "data.frame")
  expect_equal(
    names(out),
    c(
      "item_id",
      "drive_id",
      "version_id",
      "version",
      "last_modified",
      "last_modified_by",
      "last_modified_by_email",
      "last_modified_by_id",
      "size"
    )
  )
  expect_equal(out$version_id, c("3.0", "2.0", "1.0"))
  expect_equal(out$version, c(3, 2, 1))
  expect_s3_class(out$last_modified, "POSIXct")
  expect_equal(attr(out$last_modified, "tzone"), "UTC")
  expect_equal(
    out$last_modified[[2]],
    as.POSIXct("2026-10-16 20:22:44", tz = "UTC")
  )
  expect_equal(out$last_modified_by, c("Ann", "Bo", "Ann"))
  expect_equal(out$item_id, rep("ITEM1", 3))
  expect_equal(out$drive_id, rep("DRIVE1", 3))
  expect_false(any(grepl("url", names(out), ignore.case = TRUE)))
})

test_that("list_sp_item_versions() `item_cols` controls item columns", {
  none <- list_sp_item_versions(sp_item = fake_sp_item(), item_cols = "none")
  expect_false(any(c("item_id", "drive_id") %in% names(none)))
  expect_equal(names(none)[[1]], "version_id")

  summary <- list_sp_item_versions(
    sp_item = fake_sp_item(),
    item_cols = "summary"
  )
  expect_equal(
    names(summary)[1:4],
    c("item_id", "drive_id", "item_name", "item_web_url")
  )
  expect_equal(summary$item_name, rep("book.xlsx", 3))

  expect_error(
    list_sp_item_versions(sp_item = fake_sp_item(), item_cols = "everything"),
    class = "rlang_error"
  )
})

test_that("list_sp_item_versions() `version_cols = 'all'` keeps the URL", {
  out <- list_sp_item_versions(sp_item = fake_sp_item(), version_cols = "all")

  expect_true("download_url" %in% names(out))
  expect_equal(out$download_url[[1]], "https://example.com/3.0")
})

test_that("list_sp_item_versions() sorts versions", {
  # The order returned by the API isn't relied on to order the result
  out <- list_sp_item_versions(
    sp_item = fake_sp_item(test_versions[c(2, 3, 1)])
  )
  expect_equal(out$version_id, c("3.0", "2.0", "1.0"))
})

test_that("list_sp_item_versions() sends `n` as $top", {
  item <- fake_sp_item()
  out <- list_sp_item_versions(sp_item = item, n = 2)

  expect_equal(out$version_id, c("3.0", "2.0"))
  expect_equal(item$requests$ops[[1]]$options[["$top"]], 2)

  out <- list_sp_item_versions(sp_item = fake_sp_item(), n = 1)
  expect_equal(out$version_id, "3.0")
})

test_that("list_sp_item_versions() doesn't send `n` with `modified_between`", {
  item <- fake_sp_item()
  out <- list_sp_item_versions(
    sp_item = item,
    n = 1,
    modified_between = c(NA, "2026-10-16")
  )

  expect_null(item$requests$ops[[1]]$options[["$top"]])
  expect_equal(out$version_id, "2.0")
})

test_that("list_sp_item_versions() stops following links once it has `n`", {
  item <- fake_sp_item(versions = test_versions[1:2], next_link = "next-url")

  local_mocked_bindings(
    call_graph_url = function(...) abort("Shouldn't request another page"),
    .package = "AzureGraph"
  )

  out <- list_sp_item_versions(sp_item = item, n = 2)
  expect_equal(out$version_id, c("3.0", "2.0"))
})

test_that("list_sp_item_versions() `modified_between` filters versions", {
  item <- fake_sp_item()

  # Open start, Date end includes all of that day
  out <- list_sp_item_versions(
    sp_item = item,
    modified_between = c(NA, "2026-10-16")
  )
  expect_equal(out$version_id, c("2.0", "1.0"))

  out <- list_sp_item_versions(
    sp_item = item,
    modified_between = as.Date(c("2026-10-16", "2026-10-16"))
  )
  expect_equal(out$version_id, "2.0")

  out <- list_sp_item_versions(
    sp_item = item,
    modified_between = c("2026-10-17", NA)
  )
  expect_equal(out$version_id, "3.0")

  # `n` applies after filtering
  out <- list_sp_item_versions(
    sp_item = item,
    modified_between = c(NA, "2026-10-16"),
    n = 1
  )
  expect_equal(out$version_id, "2.0")
})

test_that("list_sp_item_versions() accepts lubridate intervals", {
  skip_if_not_installed("lubridate")

  out <- list_sp_item_versions(
    sp_item = fake_sp_item(),
    modified_between = lubridate::interval(
      lubridate::ymd("2026-10-16"),
      lubridate::ymd("2026-10-17")
    )
  )
  expect_equal(out$version_id, "2.0")
})

test_that("list_sp_item_versions() checks `modified_between`", {
  expect_error(
    list_sp_item_versions(
      sp_item = fake_sp_item(),
      modified_between = "2026-10-16"
    ),
    "modified_between"
  )
  expect_error(
    list_sp_item_versions(
      sp_item = fake_sp_item(),
      modified_between = c("2026-10-20", "2026-10-16")
    ),
    "modified_between"
  )
})

test_that("list_sp_item_versions() follows next links", {
  item <- fake_sp_item(versions = test_versions[1:2], next_link = "next-url")

  local_mocked_bindings(
    call_graph_url = function(token, url, ...) {
      expect_equal(url, "next-url")
      list(value = test_versions[3])
    },
    .package = "AzureGraph"
  )

  out <- list_sp_item_versions(sp_item = item)
  expect_equal(out$version_id, c("3.0", "2.0", "1.0"))
})

test_that("list_sp_item_versions() handles an empty response", {
  out <- list_sp_item_versions(sp_item = fake_sp_item(versions = list()))

  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0L)
  expect_true("version_id" %in% names(out))
})

test_that("list_sp_item_versions() handles versions without a user", {
  app_version <- test_versions[[1]]
  app_version[["lastModifiedBy"]] <- list(
    application = list(id = "app-1", displayName = "An app")
  )

  out <- list_sp_item_versions(
    sp_item = fake_sp_item(versions = list(app_version, test_versions[[2]]))
  )

  expect_equal(nrow(out), 2L)
  expect_equal(out$last_modified_by, c(NA, "Bo"))
})

test_that("list_sp_item_versions(as_data_frame = FALSE) returns a list", {
  out <- list_sp_item_versions(sp_item = fake_sp_item(), as_data_frame = FALSE)

  expect_type(out, "list")
  expect_length(out[["value"]], 3L)
})

test_that("list_sp_item_versions() requires a drive item", {
  expect_error(list_sp_item_versions(sp_item = list()), "ms_drive_item")
})

# get_sp_item_version() --------------------------------------------------------

test_that("get_sp_item_version() returns one version", {
  item <- fake_sp_item()
  out <- get_sp_item_version("2.0", sp_item = item)

  expect_equal(nrow(out), 1L)
  expect_equal(out$version_id, "2.0")
  expect_equal(out$last_modified_by, "Bo")
  expect_equal(item$requests$ops[[1]]$op, "versions/2.0")

  out <- get_sp_item_version(
    "2.0",
    sp_item = item,
    as_data_frame = FALSE
  )
  expect_equal(out[["id"]], "2.0")
})

test_that("get_sp_item_version() requires a single version_id", {
  expect_error(get_sp_item_version(c("1.0", "2.0"), sp_item = fake_sp_item()))
})

# download_sp_item_version() ---------------------------------------------------

# A `do_operation()` for downloads: `statuses` maps an operation to a status
fake_download_op <- function(statuses, newest = "3.0") {
  ops <- character()

  list(
    ops = function() ops,
    do_operation = function(
      op,
      ...,
      config = NULL,
      options = list(),
      http_status_handler = "pass"
    ) {
      ops <<- c(ops, op)

      if (op == "versions") {
        return(list(value = list(list(id = newest))))
      }

      status <- statuses[[op]] %||% 200L

      if (status < 400) {
        writeLines(paste("content of", op), config$output$path)
      } else {
        writeLines("error body", config$output$path)
      }

      structure(list(status_code = status), class = "response")
    }
  )
}

test_that("download_sp_item_version() requests the version content", {
  item <- fake_sp_item()
  download <- fake_download_op(list())
  item$do_operation <- download$do_operation

  dest <- withr::local_tempfile(fileext = ".xlsx")
  out <- download_sp_item_version("2.0", sp_item = item, dest = dest)

  expect_equal(out, dest)
  expect_equal(readLines(dest), "content of versions/2.0/content")
  expect_equal(download$ops(), "versions/2.0/content")
})

test_that("download_sp_item_version() gets the current version from the item", {
  item <- fake_sp_item()
  download <- fake_download_op(
    list("versions/3.0/content" = 400L),
    newest = "3.0"
  )
  item$do_operation <- download$do_operation

  dest <- withr::local_tempfile(fileext = ".xlsx")
  download_sp_item_version("3.0", sp_item = item, dest = dest)

  expect_equal(readLines(dest), "content of content")
})

test_that("download_sp_item_version() errors without writing dest", {
  item <- fake_sp_item()
  download <- fake_download_op(
    list("versions/2.0/content" = 400L),
    newest = "3.0"
  )
  item$do_operation <- download$do_operation

  dest <- withr::local_tempfile(fileext = ".xlsx")

  expect_error(
    download_sp_item_version("2.0", sp_item = item, dest = dest),
    "download version 2.0"
  )
  expect_false(file.exists(dest))
})

test_that("download_sp_item_version() uses a default file name", {
  expect_equal(
    sp_item_version_filename(fake_sp_item(), "2.0"),
    "book_v2.0.xlsx"
  )
})

test_that("download_sp_item_version() won't overwrite by default", {
  dest <- withr::local_tempfile(fileext = ".xlsx")
  writeLines("existing", dest)

  expect_error(
    download_sp_item_version("2.0", sp_item = fake_sp_item(), dest = dest),
    "overwrite"
  )
})

# live -------------------------------------------------------------------------

test_that("list_sp_item_versions() works with a live item", {
  skip_on_cran()
  url <- Sys.getenv("SHAREPOINTR_TEST_VERSIONS_URL")
  skip_if(url == "", "SHAREPOINTR_TEST_VERSIONS_URL is not set")
  skip_if_no_ms_site(url)

  out <- list_sp_item_versions(item_url = url)

  expect_s3_class(out, "data.frame")
  expect_gt(nrow(out), 0L)
  expect_s3_class(out$last_modified, "POSIXct")
})
