test_that("create_text_column works", {
  expect_snapshot(
    create_text_column("TextColumn")
  )

  expect_snapshot(
    create_text_column(
      "TextColumn",
      multiple_lines = TRUE,
      append_changes = TRUE,
      lines = 6L,
      max_length = 500L,
      text_type = "richText"
    )
  )

  expect_snapshot(
    create_text_column(
      "TextColumn",
      required = TRUE,
      hidden = FALSE,
      description = "A text column"
    )
  )
})

test_that("create_number_column works", {
  expect_snapshot(
    create_number_column("NumberColumn")
  )

  expect_snapshot(
    create_number_column("NumberColumn", decimals = "two")
  )

  expect_snapshot(
    create_number_column("NumberColumn", decimals = 3)
  )

  expect_snapshot(
    create_number_column(
      "NumberColumn",
      display_as = "percentage",
      min = 0,
      max = 100
    )
  )
})

test_that("create_choice_column works", {
  fruit <- c("apple", "banana", "pear", "pineapple")

  expect_snapshot(
    create_choice_column("ChoiceColumn", fruit)
  )

  expect_snapshot(
    create_choice_column(
      "ChoiceColumn",
      fruit,
      allow_text = FALSE,
      display_as = "checkBoxes"
    )
  )

  expect_snapshot(
    create_choice_column(
      "ChoiceColumn",
      "apple|banana|pear",
      split = "|"
    )
  )
})

test_that("create_datetime_column works", {
  expect_snapshot(
    create_datetime_column("DatetimeColumn")
  )

  expect_snapshot(
    create_datetime_column(
      "DatetimeColumn",
      display_as = "friendly",
      format = "dateTime"
    )
  )
})

test_that("create_boolean_column works", {
  expect_snapshot(
    create_boolean_column("BooleanColumn")
  )
})

test_that("create_currency_column works", {
  expect_snapshot(
    create_currency_column("CurrencyColumn")
  )

  expect_snapshot(
    create_currency_column("CurrencyColumn", locale = "en-gb")
  )
})

test_that("create_calculated_column works", {
  expect_snapshot(
    create_calculated_column(
      name = "FormulaColumn",
      formula = "=[Text Column]"
    )
  )

  # Formula without leading `=` gets one prepended
  expect_snapshot(
    create_calculated_column(
      name = "FormulaColumn",
      formula = "[Text Column]"
    )
  )

  expect_snapshot(
    create_calculated_column(
      name = "DateFormulaColumn",
      formula = "=[StartDate]+7",
      output_type = "dateTime",
      format = "dateOnly"
    )
  )
})

test_that("create_lookup_column works", {
  expect_snapshot(
    create_lookup_column(
      name = "LookupColumn",
      lookup_list_column = "Title",
      lookup_list_id = "abc-123"
    )
  )

  expect_snapshot(
    create_lookup_column(
      name = "LookupColumn",
      lookup_list_column = "Title",
      lookup_list_id = "abc-123",
      allow_multiple = TRUE,
      allow_unlimited_length = TRUE
    )
  )
})

test_that("create_person_column works", {
  expect_snapshot(
    create_person_column("PersonColumn")
  )
})

test_that("create_group_column works", {
  expect_snapshot(
    create_group_column("GroupColumn")
  )
})

test_that("create_hyperlink_column works", {
  expect_snapshot(
    create_hyperlink_column("HyperlinkColumn")
  )
})

test_that("create_picture_column works", {
  expect_snapshot(
    create_picture_column("PictureColumn")
  )
})

test_that("create_thumbnail_column works", {
  expect_snapshot(
    create_thumbnail_column("ThumbnailColumn")
  )
})

test_that("create_geolocation_column works", {
  expect_snapshot(
    create_geolocation_column("GeolocationColumn")
  )
})

test_that("create_term_column works", {
  expect_snapshot(
    create_term_column("TermColumn")
  )
})

test_that("create_column_definition works with shared options", {
  expect_snapshot(
    create_column_definition(
      "MyColumn",
      .col_type = "text",
      required = TRUE,
      hidden = TRUE,
      enforce_unique = TRUE,
      indexed = TRUE,
      description = "A column",
      displayname = "My Column"
    )
  )

  expect_snapshot(
    create_column_definition(
      "MyColumn",
      .col_type = "text",
      default = get_column_default("Default text")
    )
  )
})

test_that("get_column_default works", {
  expect_snapshot(get_column_default())

  expect_snapshot(get_column_default("Missing"))

  expect_snapshot(get_column_default(formula = "=[Title]"))
})

test_that("create_column_definition_list works", {
  definition_df <- data.frame(
    name = c("FirstColumn", "SecondColumn"),
    type = c("text", "number"),
    decimals = c(NA, 0),
    multiple_lines = c(TRUE, NA)
  )

  expect_snapshot(
    create_column_definition_list(definition_df)
  )
})

test_that("data_as_column_definition_list works", {
  simple_df <- data.frame(
    text_col = c("a", "b"),
    num_col = c(1.5, 2.5),
    int_col = 1L:2L,
    lgl_col = c(TRUE, FALSE),
    fct_col = factor(c("x", "y")),
    date_col = as.Date(c("2024-01-01", "2024-06-01"))
  )

  expect_snapshot(
    data_as_column_definition_list(simple_df)
  )

  expect_snapshot(
    data_as_column_definition_list(simple_df, definitions_as = "table")
  )
})

test_that("data_as_column_definition_list infers dateTime vs dateOnly format", {
  dttm_df <- data.frame(
    date_col = as.Date("2024-01-01"),
    dttm_col = as.POSIXct("2024-01-01 12:00:00", tz = "UTC")
  )

  tbl <- data_as_column_definition_list(dttm_df, definitions_as = "table")

  expect_equal(tbl[["format"]], c("dateOnly", "dateTime"))

  defs <- data_as_column_definition_list(dttm_df)

  expect_equal(defs[[1]][["dateTime"]][["format"]], "dateOnly")
  expect_equal(defs[[2]][["dateTime"]][["format"]], "dateTime")
})

test_that("data_as_column_definition_list errors if split is in factor levels", {
  split_df <- data.frame(
    fct_col = factor(c("a|b", "c"))
  )

  expect_snapshot(
    data_as_column_definition_list(split_df),
    error = TRUE
  )
})

test_that("copy_column_definition_list works", {
  # Mimics the shape of a get_sp_list_metadata() data frame closely enough
  # to exercise copy_column_definition_list()'s data frame input branch
  sp_list_meta <- data.frame(
    name = c("Title", "TextColumn", "ChoiceColumn", "ID"),
    id = c("t1", "t2", "t3", "t4"),
    columnGroup = c("g", "g", "g", "g"),
    definition = c(NA, NA, NA, NA),
    description = c(NA_character_, "", "A choice column", NA_character_),
    readOnly = c(FALSE, FALSE, TRUE, TRUE)
  )
  sp_list_meta[["choice"]] <- I(list(
    NULL,
    NULL,
    list(choices = c("A", "B"), displayAs = "dropDownMenu"),
    NULL
  ))

  col_definition <- copy_column_definition_list(sp_list_meta)

  # "Title" and internal columns (e.g. "ID") are excluded
  expect_equal(
    purrr::map_chr(col_definition, "name"),
    c("TextColumn", "ChoiceColumn")
  )

  # readOnly = FALSE and a blank description are dropped
  expect_false(has_name(col_definition[[1]], "readOnly"))
  expect_false(has_name(col_definition[[1]], "description"))

  # readOnly = TRUE and a populated description are retained
  expect_true(col_definition[[2]][["readOnly"]])
  expect_equal(col_definition[[2]][["description"]], "A choice column")
})

test_that("copy_column_definition_list does not error on populated column-type fields", {
  # Regression test: a real "choice"/"number"/etc. field has multiple named
  # elements (e.g. choices + displayAs). fmt_sp_list_metadata_df() used to
  # call is.na() directly on that multi-element list, which errored with
  # "Result must be length 1, not 2."
  sp_list_meta <- data.frame(
    name = "ChoiceColumn",
    id = "c1",
    columnGroup = "g",
    definition = NA,
    description = "",
    readOnly = FALSE
  )
  sp_list_meta[["choice"]] <- I(list(
    list(choices = c("A", "B", "C"), displayAs = "dropDownMenu")
  ))

  expect_no_error(copy_column_definition_list(sp_list_meta))
})
