test_that("as_column_definition validates column definitions", {
  definition <- list(
    name = "Notes",
    displayName = "Project Notes",
    required = TRUE,
    text = list(allowMultipleLines = TRUE, linesForEditing = 6L),
    custom = list(form_order = 1L)
  )

  expect_identical(as_column_definition(definition), definition)

  # choices are converted to a character vector
  choice_definition <- as_column_definition(
    list(name = "Status", choice = list(choices = list("a", "b")))
  )
  expect_identical(choice_definition[["choice"]][["choices"]], c("a", "b"))

  # formulas get a leading "=" without glue processing
  calculated <- as_column_definition(
    list(
      name = "Calc",
      calculated = list(formula = "[A]&\"{x}\"", outputType = "text")
    )
  )
  expect_identical(calculated[["calculated"]][["formula"]], "=[A]&\"{x}\"")

  # empty column type properties
  expect_identical(
    as_column_definition(list(name = "Flag", boolean = list()))[["boolean"]],
    set_names(list(), character(0))
  )
})

test_that("as_column_definition errors for invalid definitions", {
  expect_snapshot(error = TRUE, {
    as_column_definition(list(displayName = "No name", text = list()))
    as_column_definition(list(name = "NoType"))
    as_column_definition(list(name = "TwoTypes", text = list(), number = list()))
    as_column_definition(list(name = "Label", label = "Label", text = list()))
    as_column_definition(list(name = "ReadOnly", type = "text", text = list()))
    as_column_definition(
      list(name = "Lines", text = list(multiple_lines = TRUE))
    )
    as_column_definition(
      list(name = "Display", choice = list(displayAs = "list"))
    )
    as_column_definition(
      list(name = "Bool", text = list(allowMultipleLines = "yes"))
    )
    as_column_definition(
      list(name = "Calc", calculated = list(formula = "=1"))
    )
    as_column_definition(
      list(
        name = "Calc",
        calculated = list(formula = "=1", outputType = "text", format = "dateOnly")
      )
    )
    as_column_definition(
      list(name = "Lookup", lookup = list(columnName = "Title"))
    )
    as_column_definition(
      list(name = "Default", defaultValue = list(), text = list())
    )
    as_column_definition(
      list(name = "Custom", custom = list("a"), text = list())
    )
    as_column_definition(list(name = "NoCustom", custom = list(), text = list()), allow_custom = FALSE)
  })
})

test_that("as_column_definition warns for cell reference names and unknown person display values", {
  expect_snapshot({
    def <- as_column_definition(list(name = "V4", text = list()))
    def <- as_column_definition(
      list(name = "Person", personOrGroup = list(displayAs = "nickname"))
    )
  })
})

test_that("default values are converted to strings", {
  definition <- as_column_definition(
    list(name = "Count", defaultValue = list(value = 0L), number = list())
  )

  expect_identical(definition[["defaultValue"]], list(value = "0"))
})

test_that("create_*_column helpers accept Graph property names", {
  expect_identical(
    create_text_column("Notes", allowMultipleLines = TRUE),
    create_text_column("Notes", multiple_lines = TRUE)
  )

  expect_identical(
    create_column_definition("Notes", displayName = "Project Notes"),
    create_column_definition("Notes", display_name = "Project Notes")
  )

  expect_identical(
    create_number_column("Amount", maximum = 10.5),
    create_number_column("Amount", max = 10.5)
  )

  expect_identical(
    create_person_column("Owner", chooseFromType = "peopleAndGroups"),
    create_person_column("Owner", from_type = "peopleAndGroups")
  )

  expect_identical(
    create_hyperlink_column("Link", isPicture = TRUE),
    create_picture_column("Link")
  )

  expect_mapequal(
    create_calculated_column("Calc", formula = "=1", outputType = "number")[[
      "calculated"
    ]],
    create_calculated_column("Calc", formula = "=1", output_type = "number")[[
      "calculated"
    ]]
  )
})

test_that("create_*_column helpers error for conflicting or unknown properties", {
  expect_snapshot(error = TRUE, {
    create_text_column("Notes", multiple_lines = TRUE, allowMultipleLines = FALSE)
    create_column_definition(
      "Notes",
      display_name = "A",
      displayName = "B"
    )
    create_text_column("Notes", label = "Notes")
    create_calculated_column("Calc", formula = "=1", format = "dateOnly")
  })
})

test_that("create_number_column allows decimal maximum and minimum values", {
  definition <- create_number_column("Amount", max = 100.5, min = 0.5)

  expect_identical(definition[["number"]][["maximum"]], 100.5)
  expect_identical(definition[["number"]][["minimum"]], 0.5)
})

test_that("deprecated arguments still work", {
  withr::local_options(lifecycle_verbosity = "warning")

  expect_snapshot({
    create_column_definition("A", displayname = "B")
    create_number_column("A", decimals = 2)
    create_lookup_column(
      "A",
      lookup_list_column = "Title",
      lookup_list_id = "abc",
      allow_multiple = TRUE
    )
    create_person_column("A", allow_multiple = TRUE)
    create_term_column("A", allow_multiple = TRUE)
  })
})

test_that("column_validation creates validation definitions", {
  expect_identical(
    column_validation("LEN([Code])=8", "Use 8 characters."),
    list(
      formula = "=LEN([Code])=8",
      descriptions = list(
        list(languageTag = "en-US", displayName = "Use 8 characters.")
      ),
      defaultLanguage = "en-US"
    )
  )

  validation <- column_validation(
    "=[Amount]>0",
    c("en-US" = "Must be positive", "es-ES" = "Debe ser positivo")
  )

  expect_length(validation[["descriptions"]], 2)

  expect_identical(
    create_text_column("Code", validation = column_validation("=TRUE"))[[
      "validation"
    ]],
    list(formula = "=TRUE", defaultLanguage = "en-US")
  )

  expect_identical(
    sp_validation_as_rest_fields(validation),
    list(ValidationFormula = "=[Amount]>0", ValidationMessage = "Must be positive")
  )
})

test_that("create_column_definition_list accepts Graph names and type keys", {
  definitions <- data.frame(
    name = c("Start", "Due", "Notes"),
    type = c("date", "dateTime", "text"),
    displayName = c("Start Date", NA, "Notes"),
    allowMultipleLines = c(NA, NA, TRUE)
  )

  columns <- create_column_definition_list(definitions)

  # A "date" column uses dateOnly format
  expect_identical(columns[[1]][["dateTime"]][["format"]], "dateOnly")
  expect_identical(columns[[1]][["displayName"]], "Start Date")
  expect_false(has_name(columns[[2]][["dateTime"]], "format"))
  expect_true(columns[[3]][["text"]][["allowMultipleLines"]])

  expect_snapshot(
    create_column_definition_list(data.frame(name = "A", type = "unknown")),
    error = TRUE
  )
})
