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
