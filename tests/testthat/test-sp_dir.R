test_that("sp_drive functions work", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  sp_drive_list_df <- list_sp_drives(
    site_url = test_site_url
  )

  expect_s3_class(
    sp_drive_list_df,
    "data.frame"
  )

  sp_drive_list <- list_sp_drives(
    site_url = test_site_url,
    as_data_frame = FALSE
  )

  expect_type(
    sp_drive_list,
    "list"
  )
})

test_that("sp_dir functions work", {
  test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-ALL/Shared%20Documents/General?csf=1&web=1&e=9woQ1d"

  skip_if_no_ms_site(test_dir_url)

  expect_type(
    sp_dir_ls(
      test_dir_url
    ),
    "character"
  )

  expect_s3_class(
    sp_dir_info(test_dir_url),
    "data.frame"
  )
})

test_that("sp_drive_item_path() gets an item path relative to the drive root", {
  expect_identical(sp_drive_item_path(list(name = "root", root = list())), "")
  expect_identical(
    sp_drive_item_path(list(
      name = "Folder",
      parentReference = list(path = "/drives/b!abc/root:")
    )),
    "Folder"
  )
  expect_identical(
    sp_drive_item_path(list(
      name = "Sub Folder",
      parentReference = list(path = "/drives/b!abc/root:/Folder A/B")
    )),
    "Folder A/B/Sub Folder"
  )
})

# Mock the Graph children response (the `folder` column is a data frame with
# a `childCount` value for folders)
raw_items <- function(name, isdir = FALSE, size = 1, ...) {
  items <- data.frame(name = name, size = size, id = as.character(seq_along(name)), ...)
  items[["folder"]] <- data.frame(
    childCount = ifelse(rep_len(isdir, length(name)), 1L, NA_integer_)
  )
  items
}

mock_drive <- function() {
  structure(list(), class = c("ms_drive", "ms_object"))
}

test_that("sp_dir_info() uses the drive and path from the shares API", {
  list_args <- NULL
  drive <- mock_drive()

  local_mocked_bindings(
    sp_dir_request_items = function(drive, path, ...) {
      list_args <<- path
      raw_items("A.csv")
    },
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = drive, path = "Folder", is_folder = TRUE)
    },
    get_sp_drive = function(...) stop("get_sp_drive() shouldn't be called")
  )

  items <- sp_dir_info(
    "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FTeam%2FShared%20Documents%2FFolder"
  )

  expect_identical(list_args, "Folder")
  expect_identical(items[["name"]], "Folder/A.csv")
})

test_that("sp_dir_info() errors for a file URL from the shares API", {
  local_mocked_bindings(
    sp_shares_get_drive_path = function(url, ...) {
      list(drive = NULL, path = "Folder/A.csv", is_folder = FALSE)
    }
  )

  expect_snapshot(error = TRUE, {
    sp_dir_info(
      "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder/A.csv"
    )
  })
})

test_that("sp_dir_info() falls back to the parsed URL if the shares API fails", {
  drive_args <- NULL

  local_mocked_bindings(
    sp_dir_request_items = function(drive, path, ...) raw_items("A.csv"),
    sp_shares_get_drive_path = function(...) {
      cli::cli_abort("Forbidden (HTTP 403).")
    },
    get_sp_drive = function(drive_name = NULL, ...) {
      drive_args <<- drive_name
      mock_drive()
    }
  )

  url <- "https://contoso.sharepoint.com/:f:/r/sites/Team/Shared%20Documents/Folder?csf=1"
  items <- sp_dir_info(url)

  expect_identical(drive_args, url)
  expect_identical(items[["name"]], "Folder/A.csv")

  expect_snapshot(error = TRUE, {
    sp_dir_info(
      "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Folder"
    )
  })
})

test_that("sp_dir_info(recurse = TRUE) lists all directories and sorts by name", {
  tree <- list(
    root = raw_items(c("B", "A", "z.csv"), isdir = c(TRUE, TRUE, FALSE)),
    "A" = raw_items("a.csv"),
    "B" = raw_items(c("C", "b.csv"), isdir = c(TRUE, FALSE)),
    "B/C" = raw_items("c.txt")
  )
  drive <- mock_drive()
  local_mocked_bindings(
    sp_dir_request_items = function(drive, path, ...) {
      tree[[if (path == "") "root" else path]]
    }
  )

  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE)
  expect_identical(
    items[["name"]],
    c("A", "A/a.csv", "B", "B/C", "B/C/c.txt", "B/b.csv", "z.csv")
  )

  # Unmatched directories are still searched
  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE, regexp = "\\.txt$")
  expect_identical(items[["name"]], "B/C/c.txt")

  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE, type = "directory")
  expect_identical(items[["name"]], c("A", "B", "B/C"))

  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE, type = "file")
  expect_identical(
    items[["name"]],
    c("A/a.csv", "B/C/c.txt", "B/b.csv", "z.csv")
  )

  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE, sort = "name-desc")
  expect_identical(items[["name"]][1], "z.csv")

  items <- sp_dir_info(drive = drive, recurse = TRUE, .batch = FALSE, sort = "none")
  expect_identical(items[["name"]][1:3], c("B", "A", "z.csv"))
})

test_that("sp_dir_info() requests the properties needed to sort", {
  select_args <- list()
  local_mocked_bindings(
    sp_dir_request_items = function(drive, path, select, ...) {
      select_args <<- c(select_args, list(select))
      raw_items(
        c("a.csv", "b.csv", "c.csv"),
        size = c(3, 1, 2),
        lastModifiedDateTime = c(
          "2026-01-02T00:00:00Z",
          "2026-01-03T00:00:00Z",
          "2026-01-01T00:00:00Z"
        )
      )
    }
  )
  drive <- mock_drive()

  items <- sp_dir_info(drive = drive, sort = "modified-desc")
  expect_identical(select_args[[1]], c("name", "size", "folder", "id", "lastModifiedDateTime"))
  expect_identical(items[["name"]], c("b.csv", "a.csv", "c.csv"))
  expect_named(items, c("name", "size", "isdir", "id", "lastModifiedDateTime", "type"))

  items <- sp_dir_info(drive = drive, sort = "size-asc", select = "webUrl")
  expect_identical(select_args[[2]], c("name", "size", "folder", "id", "webUrl"))
  expect_identical(items[["name"]], c("b.csv", "c.csv", "a.csv"))

  sp_dir_info(drive = drive, info = "all")
  expect_null(select_args[[3]])

  # Order is unchanged for a single directory unless `sort` is supplied
  items <- sp_dir_info(drive = drive)
  expect_identical(items[["name"]], c("a.csv", "b.csv", "c.csv"))

  expect_error(sp_dir_ls(drive = drive, select = "webUrl"), "select")
})

test_that("sp_dir_children_op() encodes path segments", {
  expect_identical(sp_dir_children_op(""), "root/children")
  expect_identical(sp_dir_children_op("/"), "root/children")
  expect_identical(
    sp_dir_children_op("a b/c#d/é/"),
    "root:/a%20b/c%23d/%C3%A9:/children"
  )
})

test_that("sp_dir_info(recurse = TRUE) lists directories with $batch requests", {
  # Folders have a `folder` value and files don't (as in a Graph response)
  graph_item <- function(name, isdir = FALSE) {
    item <- list(name = name, size = 1L, id = name)
    if (isdir) {
      item[["folder"]] <- list(childCount = 1L)
    }
    item
  }

  tree <- list(
    A = list(graph_item("a.csv")),
    B = list(graph_item("b.csv"))
  )

  requests <- list()
  local_mocked_bindings(
    # A single directory is requested without $batch
    sp_dir_request_items = function(...) {
      raw_items(c("B", "A", "z.csv"), isdir = c(TRUE, TRUE, FALSE))
    },
    sp_graph_batch_requests = function(token, requests_i, ...) {
      requests <<- c(requests, list(requests_i))
      purrr::map(requests_i, \(x) {
        path <- sub("^.*root:?/?(.*?):?/?children.*$", "\\1", x$url)
        list(status = 200L, body = list(value = tree[[path]]))
      })
    }
  )

  items <- sp_dir_info(drive = mock_drive(), recurse = TRUE)

  expect_identical(items[["name"]], c("A", "A/a.csv", "B", "B/b.csv", "z.csv"))
  expect_identical(items[["isdir"]], c(TRUE, FALSE, TRUE, FALSE, FALSE))
  # The two subfolders are requested in one $batch request
  expect_length(requests, 1)
  expect_length(requests[[1]], 2)
  expect_match(requests[[1]][[1]]$url, "^/drives/.*root:/B:/children\\?\\$top=1000&\\$select=name,size,folder,id")
})

test_that("sp_dir_batch_items() errors for a failed request", {
  response <- list(
    status = 404L,
    body = list(error = list(message = "The resource could not be found."))
  )

  expect_error(sp_dir_batch_items(response, NULL, "Missing"), "404")
})
