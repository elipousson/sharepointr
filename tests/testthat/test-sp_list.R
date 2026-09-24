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

  expect_identical(sp_list[["properties"]][["displayName"]], list_name)

  update_sp_list(
    sp_list = sp_list,
    description = "Updated description"
  )

  updated_list <- get_sp_list(
    list_id = sp_list[["properties"]][["id"]],
    site_url = test_site_url
  )

  expect_identical(
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

  expect_identical(created_column[["name"]], "TextColumn")
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

  expect_identical(
    updated_column[["description"]],
    "Updated column description"
  )

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

# Mimics the shape of a get_sp_list_metadata() data frame, including the
# nested data frame columns created by simplifying the API response
sp_list_meta_df <- data.frame(
  name = c("Title", "Amount", "Owner", "ID"),
  displayName = c("Title", "Amount (USD)", "Project Owner", "ID"),
  hidden = c(FALSE, FALSE, NA, TRUE),
  indexed = c(TRUE, FALSE, FALSE, FALSE),
  readOnly = c(FALSE, FALSE, NA, TRUE),
  required = c(TRUE, TRUE, FALSE, NA)
)
sp_list_meta_df[["currency"]] <- data.frame(locale = c(NA, "en-us", NA, NA))
sp_list_meta_df[["lookup"]] <- data.frame(
  columnName = c(NA, NA, "Title", NA),
  listId = c(NA, NA, "abc", NA)
)

# Mimics the shape of get_sp_list_metadata(as_data_frame = FALSE) where
# properties are omitted for columns that lack them
sp_list_meta_list <- list(
  list(
    name = "Title",
    displayName = "Title",
    hidden = FALSE,
    indexed = TRUE,
    readOnly = FALSE,
    required = TRUE
  ),
  list(
    name = "Amount",
    displayName = "Amount (USD)",
    hidden = FALSE,
    indexed = FALSE,
    readOnly = FALSE,
    required = TRUE,
    currency = list(locale = "en-us")
  ),
  list(
    name = "Owner",
    displayName = "Project Owner",
    indexed = FALSE,
    required = FALSE,
    lookup = list(columnName = "Title", listId = "abc")
  ),
  list(
    name = "ID",
    displayName = "ID",
    hidden = TRUE,
    indexed = FALSE,
    readOnly = TRUE
  )
)

empty_index <- set_names(integer(0), character(0))

test_that("pull_sp_list_cols works with data frame and list inputs", {
  for (sp_list_meta in list(sp_list_meta_df, sp_list_meta_list)) {
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "currency"),
      c(Amount = 2L)
    )
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "lookup", names_from = "displayName"),
      c(`Project Owner` = 3L)
    )
    expect_identical(pull_sp_list_cols(sp_list_meta, "hidden"), c(ID = 4L))
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "required"),
      c(Title = 1L, Amount = 2L)
    )
    expect_identical(pull_sp_list_cols(sp_list_meta, "readOnly"), c(ID = 4L))
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "all"),
      c(Title = 1L, Amount = 2L, Owner = 3L, ID = 4L)
    )
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "editable"),
      c(Title = 1L, Amount = 2L, Owner = 3L)
    )
    expect_identical(
      pull_sp_list_cols(sp_list_meta, "external"),
      c(Title = 1L, Amount = 2L, Owner = 3L)
    )
  }
})

test_that("pull_sp_list_cols matches column type properties", {
  col_types <- c(
    "boolean",
    "calculated",
    "choice",
    "currency",
    "dateTime",
    "lookup",
    "number",
    "personOrGroup",
    "text",
    "term",
    "hyperlinkOrPicture",
    "thumbnail",
    "contentApprovalStatus",
    "geolocation"
  )

  expect_setequal(col_types, sp_list_col_types)

  # Mimics get_sp_list_metadata(as_data_frame = FALSE) with one column per type
  sp_list_meta_list <- list(
    list(name = "Done", boolean = set_names(list())),
    list(
      name = "Calc",
      calculated = list(formula = "=1", outputType = "number")
    ),
    list(name = "Status", choice = list(choices = list("A", "B"))),
    list(name = "Amount", currency = list(locale = "en-US")),
    list(name = "Due", dateTime = list(format = "dateOnly")),
    list(name = "Owner", lookup = list(columnName = "Title")),
    list(name = "Count", number = list(decimalPlaces = "automatic")),
    list(name = "Staff", personOrGroup = list(chooseFromType = "peopleOnly")),
    list(name = "Notes", text = list(allowMultipleLines = TRUE)),
    list(name = "Tags", term = list(allowMultipleValues = FALSE)),
    list(name = "Link", hyperlinkOrPicture = list(isPicture = FALSE)),
    list(name = "Thumb", thumbnail = set_names(list())),
    list(name = "Approval", contentApprovalStatus = set_names(list())),
    list(name = "Location", geolocation = set_names(list())),
    list(name = "ID")
  )

  for (i in seq_along(col_types)) {
    expect_identical(
      pull_sp_list_cols(sp_list_meta_list, col_types[[i]]),
      set_names(i, sp_list_meta_list[[i]][["name"]])
    )
  }

  # Mimics the simplified data frame with nested data frame facet columns
  sp_list_meta_df <- data.frame(
    name = purrr::map_chr(sp_list_meta_list, "name")
  )
  n <- nrow(sp_list_meta_df)
  na_chr <- rep(NA_character_, n)
  sp_list_meta_df[["calculated"]] <- data.frame(
    formula = replace(na_chr, 2, "=1")
  )
  # choice is only identifiable by the `choices` list column
  sp_list_meta_df[["choice"]] <- data.frame(allowTextEntry = rep(NA, n))
  sp_list_meta_df[["choice"]][["choices"]] <- replace(
    vector("list", n),
    3,
    list(c("A", "B"))
  )
  sp_list_meta_df[["currency"]] <- data.frame(
    locale = replace(na_chr, 4, "en-US")
  )
  sp_list_meta_df[["dateTime"]] <- data.frame(
    format = replace(na_chr, 5, "dateOnly")
  )
  sp_list_meta_df[["lookup"]] <- data.frame(
    columnName = replace(na_chr, 6, "Title")
  )
  sp_list_meta_df[["number"]] <- data.frame(
    maximum = replace(rep(NA_real_, n), 7, 100)
  )
  sp_list_meta_df[["personOrGroup"]] <- data.frame(
    chooseFromType = replace(na_chr, 8, "peopleOnly")
  )
  sp_list_meta_df[["text"]] <- data.frame(
    allowMultipleLines = replace(rep(NA, n), 9, TRUE)
  )

  for (i in 2:9) {
    expect_identical(
      pull_sp_list_cols(sp_list_meta_df, col_types[[i]]),
      set_names(i, sp_list_meta_df[["name"]][[i]])
    )
  }

  # The empty boolean facet simplifies to a data frame with no columns
  sp_list_meta_df[["boolean"]] <- data.frame(row.names = seq_len(n))
  expect_snapshot(pull_sp_list_cols(sp_list_meta_df, "boolean"), error = TRUE)
})

test_that("pull_sp_list_cols returns empty index for missing metadata", {
  sp_list_meta_df <- data.frame(name = c("Title", "Notes"))
  sp_list_meta_list <- list(list(name = "Title"), list(name = "Notes"))

  for (sp_list_meta in list(sp_list_meta_df, sp_list_meta_list)) {
    expect_identical(pull_sp_list_cols(sp_list_meta, "currency"), empty_index)
    expect_identical(pull_sp_list_cols(sp_list_meta, "indexed"), empty_index)
    expect_identical(pull_sp_list_cols(sp_list_meta, "boolean"), empty_index)
  }

  expect_identical(pull_sp_list_cols(list(), "all"), empty_index)
})

test_that("pull_sp_list_cols index works with vctrs::vec_slice", {
  expect_identical(
    vctrs::vec_slice(
      sp_list_meta_list,
      pull_sp_list_cols(sp_list_meta_list, "editable")
    ),
    sp_list_meta_list[1:3]
  )
  expect_identical(
    vctrs::vec_slice(
      sp_list_meta_df,
      pull_sp_list_cols(sp_list_meta_df, "external")
    )[["name"]],
    c("Title", "Amount", "Owner")
  )
})

test_that("pull_sp_list_cols validates inputs", {
  expect_snapshot(error = TRUE, {
    pull_sp_list_cols("Title", "hidden")
    pull_sp_list_cols(sp_list_meta_df, "notAType")
    pull_sp_list_cols(sp_list_meta_df, "hidden", names_from = "id")
  })
})
