skip_if_not_installed("yaml12")

example_path <- function() {
  system.file("extdata", "example-list.yaml", package = "sharepointr")
}

local_yaml <- function(lines, env = parent.frame()) {
  path <- withr::local_tempfile(fileext = ".yaml", .local_envir = env)
  writeLines(lines, path)
  path
}

test_that("read_sp_list_yaml reads and validates a list definition", {
  definition <- read_sp_list_yaml(example_path())

  expect_s3_class(definition, "sp_list_definition")
  expect_identical(definition[["displayName"]], "Example Projects")
  expect_identical(definition[["list"]], list(template = "genericList"))
  expect_identical(definition[["custom"]], list(owner = "Planning"))
  expect_identical(definition[["format_version"]], 1L)
  expect_length(definition[["columns"]], 9)

  status <- definition[["columns"]][[4]]
  expect_identical(status[["choice"]][["choices"]], c("Planning", "Active", "Closed"))
  expect_identical(status[["custom"]], list(form_order = 3L))

  expect_snapshot(print(definition))
})

test_that("read_sp_list_yaml keeps choice values that look like booleans as strings", {
  path <- local_yaml(c(
    "displayName: Test",
    "columns:",
    "  - name: Answer",
    "    choice:",
    "      choices: [Yes, No]"
  ))

  definition <- read_sp_list_yaml(path)

  expect_identical(
    definition[["columns"]][[1]][["choice"]][["choices"]],
    c("Yes", "No")
  )
})

test_that("read_sp_list_yaml errors for invalid files", {
  expect_snapshot(error = TRUE, {
    read_sp_list_yaml("missing-file.yaml")
    read_sp_list_yaml(local_yaml(c("displayName: Test", "fields: []")))
    read_sp_list_yaml(local_yaml(c("columns: []")))
    read_sp_list_yaml(local_yaml(c("displayName: Test", "format_version: 2", "columns: []")))
    read_sp_list_yaml(local_yaml(c(
      "displayName: Test",
      "columns:",
      "  - name: A",
      "    label: A",
      "    sp_col_type: text"
    )))
    read_sp_list_yaml(local_yaml(c(
      "displayName: Test",
      "columns:",
      "  - name: A",
      "    text: {}",
      "  - name: A",
      "    number: {}"
    )))
  })
})

test_that("read_sp_list_yaml validates the list name and settings", {
  expect_snapshot(error = TRUE, {
    read_sp_list_yaml(local_yaml(c("name: Test", "columns: []")))
    read_sp_list_yaml(local_yaml(c(
      "displayName: Test",
      "list:",
      "  baseTemplate: 100",
      "columns: []"
    )))
    read_sp_list_yaml(local_yaml(c(
      "displayName: Test",
      "list:",
      "  hidden: maybe",
      "columns: []"
    )))
  })

  definition <- read_sp_list_yaml(local_yaml(c(
    "displayName: Test",
    "list:",
    "  template: documentLibrary",
    "  hidden: true",
    "custom:",
    "  list_url: https://example.com",
    "columns: []"
  )))

  expect_identical(
    definition[["list"]],
    list(template = "documentLibrary", hidden = TRUE)
  )
  expect_identical(definition[["custom"]], list(list_url = "https://example.com"))
})

test_that("read_sp_list_yaml allows read-only list properties and column ids", {
  path <- local_yaml(c(
    "displayName: Test",
    "id: list-1",
    "name: TestList",
    "webUrl: https://example.sharepoint.com/sites/Site/Lists/TestList",
    "createdDateTime: 2026-01-02T03:04:05Z",
    "parentReference:",
    "  siteId: site-1",
    "columns:",
    "  - name: Notes",
    "    id: column-1",
    "    text: {}"
  ))

  definition <- read_sp_list_yaml(path)

  expect_identical(definition[["id"]], "list-1")
  expect_identical(definition[["createdDateTime"]], "2026-01-02T03:04:05Z")
  expect_identical(definition[["parentReference"]], list(siteId = "site-1"))
  expect_identical(definition[["columns"]][[1]][["id"]], "column-1")
  expect_identical(
    sp_list_definition_read_only(definition)[["webUrl"]],
    "https://example.sharepoint.com/sites/Site/Lists/TestList"
  )

  # Column ids aren't sent to the Graph API
  expect_false(has_name(sp_list_definition_columns(definition)[[1]], "id"))

  # Round trip keeps read-only properties after the editable list settings
  out <- withr::local_tempfile(fileext = ".yaml")
  suppressMessages(write_sp_list_yaml(definition, out))
  expect_identical(read_sp_list_yaml(out), definition)
  expect_identical(
    readLines(out)[1:4],
    c("format_version: 1", "displayName: Test", "id: list-1", "name: TestList")
  )

  expect_snapshot(error = TRUE, {
    read_sp_list_yaml(local_yaml(c(
      "displayName: Test",
      "parentReference: site-1",
      "columns: []"
    )))
  })
})

test_that("resolve_read_only_props resolves read_only values", {
  expect_identical(resolve_read_only_props("stable"), sp_list_stable_props)
  expect_identical(resolve_read_only_props("none"), character(0))
  expect_true("createdBy" %in% resolve_read_only_props("all"))
  expect_identical(
    resolve_read_only_props(c("id", "createdBy")),
    c("id", "createdBy")
  )
  expect_snapshot(resolve_read_only_props("owner"), error = TRUE)
})

test_that("read_sp_list_yaml reads and validates views", {
  lines <- c(
    "displayName: Test",
    "columns:",
    "  - name: Status",
    "    text: {}",
    "views:",
    "  - Title: Active",
    "    DefaultView: true",
    "    ViewFields: [LinkTitle, Status]",
    "    ViewQuery: <Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Text\">Active</Value></Eq></Where>",
    "    RowLimit: 50",
    "    CustomFormatter:",
    "      additionalRowClass: sp-field-severity--good",
    "  - Title: All Items",
    "    ViewFields: [LinkTitle]"
  )

  definition <- read_sp_list_yaml(local_yaml(lines))
  views <- definition[["views"]]

  expect_length(views, 2)
  expect_identical(views[[1]][["ViewFields"]], c("LinkTitle", "Status"))
  expect_identical(views[[1]][["RowLimit"]], 50L)
  # View formatting is kept as a mapping
  expect_identical(
    views[[1]][["CustomFormatter"]],
    list(additionalRowClass = "sp-field-severity--good")
  )
  expect_snapshot(print(definition))

  # Views are written after columns, with fields as a sequence
  out <- withr::local_tempfile(fileext = ".yaml")
  suppressMessages(write_sp_list_yaml(definition, out))
  expect_identical(read_sp_list_yaml(out), definition)
  written <- readLines(out)
  expect_true(match("views:", written) > match("columns:", written))
  expect_true(any(grepl("^      - LinkTitle$", written)))
})

test_that("write_sp_list_yaml keeps single-element sequences in view formatting", {
  # Formatter operands and children must be JSON arrays, even with one element
  formatter <- paste0(
    '{"additionalRowClass":{"operator":"?","operands":["@me"]},',
    '"rowFormatter":{"elmType":"div","children":[{"elmType":"span"}]}}'
  )
  view <- as_definition_view(list(Title = "Formatted", CustomFormatter = formatter))
  definition <- as_sp_list_definition(
    list(
      displayName = "Test",
      columns = list(list(name = "Status", choice = list(choices = "Active"))),
      views = list(view)
    )
  )

  out <- withr::local_tempfile(fileext = ".yaml")
  suppressMessages(write_sp_list_yaml(definition, out))
  read <- read_sp_list_yaml(out)
  read_formatter <- read[["views"]][[1]][["CustomFormatter"]]

  expect_identical(read_formatter[["additionalRowClass"]][["operands"]], list("@me"))
  expect_true(same_view_value(as_view_json(read_formatter), formatter, "CustomFormatter"))

  # Other single-element sequences are still read as vectors
  expect_identical(read[["columns"]][[1]][["choice"]][["choices"]], "Active")
})

test_that("read_sp_list_yaml errors and warns for invalid views", {
  base <- c("displayName: Test", "columns:", "  - name: Status", "    text: {}", "views:")

  expect_snapshot(error = TRUE, {
    read_sp_list_yaml(local_yaml(c(base, "  - Title: A", "  - Title: A")))
    read_sp_list_yaml(local_yaml(c(
      base,
      "  - Title: A",
      "    DefaultView: true",
      "  - Title: B",
      "    DefaultView: true"
    )))
    read_sp_list_yaml(local_yaml(c(base, "  - Title: A", "    row_limit: 10")))
    read_sp_list_yaml(local_yaml(c(base, "  - RowLimit: 10")))
  })

  expect_snapshot(
    definition <- read_sp_list_yaml(local_yaml(c(
      base,
      "  - Title: A",
      "    ViewFields: [LinkTitle, Status, Missing, Modified]"
    )))
  )
})

test_that("write_sp_list_yaml keeps existing views if the definition has none", {
  path <- local_yaml(c(
    "displayName: Test",
    "columns:",
    "  - name: Status",
    "    text: {}",
    "views:",
    "  - Title: Active",
    "    ViewFields: [LinkTitle, Status]"
  ))

  live <- new_sp_list_definition(
    display_name = "Test",
    columns = list(list(name = "Status", text = list(maxLength = 100L)))
  )

  written <- suppressMessages(write_sp_list_yaml(live, path))

  expect_identical(written[["views"]][[1]][["Title"]], "Active")
  expect_identical(written[["columns"]][[1]][["text"]][["maxLength"]], 100L)
})

test_that("as_definition_view converts views from the REST API", {
  view <- list(
    Id = "v1",
    Title = "Active",
    DefaultView = FALSE,
    Hidden = FALSE,
    PersonalView = FALSE,
    ViewType = "HTML",
    RowLimit = 30L,
    Paged = TRUE,
    Scope = 0L,
    ViewQuery = "<OrderBy><FieldRef Name=\"ID\" /></OrderBy>",
    CustomFormatter = "{\"additionalRowClass\":\"x\"}",
    MobileView = FALSE,
    MobileDefaultView = FALSE,
    ServerRelativeUrl = "/sites/Site/Lists/Test/Active.aspx",
    ViewFields = c("LinkTitle", "Status")
  )

  expect_identical(
    as_definition_view(view),
    list(
      Title = "Active",
      ViewFields = c("LinkTitle", "Status"),
      ViewQuery = "<OrderBy><FieldRef Name=\"ID\" /></OrderBy>",
      CustomFormatter = list(additionalRowClass = "x")
    )
  )

  with_id <- as_definition_view(view, keep_id = TRUE, keep_defaults = TRUE)
  expect_identical(names(with_id)[1:3], c("Title", "Id", "ServerRelativeUrl"))
  expect_identical(with_id[["RowLimit"]], 30L)
  expect_false(has_name(with_id, "PersonalView"))
})

test_that("read_sp_list_yaml warns for duplicate display names", {
  path <- local_yaml(c(
    "displayName: Test",
    "columns:",
    "  - name: A",
    "    displayName: Same",
    "    text: {}",
    "  - name: B",
    "    displayName: Same",
    "    text: {}"
  ))

  expect_snapshot(definition <- read_sp_list_yaml(path))
})

test_that("as_sp_list_definition accepts a list of column definitions", {
  columns <- list(
    create_text_column("Notes", multiple_lines = TRUE),
    create_boolean_column("Flag")
  )

  definition <- as_sp_list_definition(columns, display_name = "Test")

  expect_s3_class(definition, "sp_list_definition")
  expect_identical(definition[["columns"]], columns)
})

test_that("write_sp_list_yaml round trips a definition", {
  definition <- read_sp_list_yaml(example_path())
  path <- withr::local_tempfile(fileext = ".yaml")

  expect_snapshot(
    written <- write_sp_list_yaml(definition, path),
    transform = \(x) sub("to .*$", "to <path>.", x)
  )

  expect_identical(read_sp_list_yaml(path), written)
  # Writing only changes the order of column properties
  expect_identical(
    purrr::map(written[["columns"]], \(col) col[sort(names(col))]),
    purrr::map(definition[["columns"]], \(col) col[sort(names(col))])
  )
  expect_snapshot(cat(readLines(path), sep = "\n"))
})

test_that("write_sp_list_yaml round trips a definition with no columns", {
  # e.g. a list with only the default Title column, which
  # get_sp_list_definition() leaves out
  definition <- as_sp_list_definition(
    list(displayName = "Empty List", columns = list())
  )
  path <- withr::local_tempfile(fileext = ".yaml")

  suppressMessages(write_sp_list_yaml(definition, path))
  expect_true("columns: []" %in% readLines(path))
  expect_identical(read_sp_list_yaml(path)[["columns"]], list())

  # Merging with the existing file also works
  suppressMessages(write_sp_list_yaml(definition, path))
  expect_identical(read_sp_list_yaml(path)[["columns"]], list())
})

test_that("write_sp_list_yaml keeps the header and custom metadata from an existing file", {
  path <- local_yaml(c(
    "# A header comment",
    "# Second line",
    "",
    "displayName: Test",
    "columns:",
    "  - name: First",
    "    text: {}",
    "    custom:",
    "      form_order: 1 # an inline comment",
    "  - name: Removed",
    "    text: {}",
    "  - name: Link",
    "    hyperlinkOrPicture: {}"
  ))

  # A definition from a live list: First changed, Removed dropped, New added,
  # and the Graph API doesn't return the type for Link
  live <- new_sp_list_definition(
    display_name = "Test",
    columns = list(
      list(name = "New", boolean = set_names(list(), character(0))),
      list(name = "First", text = list(allowMultipleLines = TRUE))
    )
  )

  expect_snapshot(
    written <- write_sp_list_yaml(live, path),
    transform = \(x) sub("'.*'", "<path>", sub("to .*$", "to <path>.", x))
  )

  lines <- readLines(path)
  expect_identical(lines[1:3], c("# A header comment", "# Second line", ""))

  expect_identical(
    purrr::map_chr(written[["columns"]], "name"),
    c("First", "Link", "New")
  )
  expect_identical(written[["columns"]][[1]][["custom"]], list(form_order = 1L))
  expect_true(written[["columns"]][[1]][["text"]][["allowMultipleLines"]])

  # merge = FALSE replaces the file
  write_sp_list_yaml(live, path, merge = FALSE) |>
    suppressMessages()
  expect_identical(readLines(path)[1], "format_version: 1")
})

test_that("write_sp_list_yaml keeps a document start marker after the header", {
  path <- local_yaml(c(
    "# A header comment",
    "",
    "---",
    "displayName: Test",
    "columns:",
    "  - name: First",
    "    text: {}"
  ))
  definition <- read_sp_list_yaml(path)

  # doc_start = NULL keeps the marker
  suppressMessages(write_sp_list_yaml(definition, path))
  expect_identical(
    readLines(path)[1:3],
    c("# A header comment", "---", "format_version: 1")
  )
  expect_identical(read_sp_list_yaml(path), definition)

  # doc_start = FALSE removes it
  suppressMessages(write_sp_list_yaml(definition, path, doc_start = FALSE))
  expect_identical(
    readLines(path)[1:3],
    c("# A header comment", "", "format_version: 1")
  )

  # doc_start = TRUE adds it
  suppressMessages(write_sp_list_yaml(definition, path, doc_start = TRUE))
  expect_identical(readLines(path)[2], "---")

  # Without a header (merge = FALSE)
  suppressMessages(
    write_sp_list_yaml(definition, path, merge = FALSE, doc_start = TRUE)
  )
  expect_identical(readLines(path)[1:2], c("---", "format_version: 1"))
})

test_that("write_sp_list_yaml warns about comments after the document start marker", {
  path <- local_yaml(c(
    "# A header comment",
    "---",
    "# Not part of the header",
    "displayName: Test",
    "columns: []"
  ))

  expect_warning(
    write_sp_list_yaml(read_sp_list_yaml(path), path) |>
      suppressMessages(),
    "comments after the header"
  )
  expect_identical(readLines(path)[1:2], c("# A header comment", "---"))
})

test_that("read_sp_list_yaml errors on a file with more than one document", {
  path <- local_yaml(c(
    "---",
    "displayName: Test",
    "columns: []",
    "---",
    "displayName: Other",
    "columns: []"
  ))

  expect_error(read_sp_list_yaml(path), "must have one YAML document, not 2")
})

test_that("write_sp_list_yaml uses custom metadata from a definition", {
  path <- local_yaml(c(
    "# Header",
    "",
    "displayName: Test",
    "custom:",
    "  owner: Planning",
    "columns:",
    "  - name: First",
    "    text: {}",
    "    custom:",
    "      form_order: 1",
    "  - name: Second",
    "    text: {}",
    "    custom:",
    "      form_order: 2"
  ))

  # An edited definition: new custom metadata for the list and First, and no
  # custom metadata for Second (kept from the existing file)
  definition <- read_sp_list_yaml(path)
  definition[["custom"]] <- list(owner = "DOP")
  definition[["columns"]][[1]][["custom"]] <- list(
    form_order = 1L,
    todo = "Check this"
  )
  definition[["columns"]][[2]][["custom"]] <- NULL

  written <- write_sp_list_yaml(definition, path) |>
    suppressMessages()

  expect_identical(readLines(path)[1], "# Header")
  expect_identical(written[["custom"]], list(owner = "DOP"))
  expect_identical(
    written[["columns"]][[1]][["custom"]],
    list(form_order = 1L, todo = "Check this")
  )
  expect_identical(
    written[["columns"]][[2]][["custom"]],
    list(form_order = 2L)
  )
  expect_identical(read_sp_list_yaml(path), written)
})

test_that("sp_list_definition_table converts a definition to a data frame", {
  definition <- read_sp_list_yaml(example_path())
  table <- sp_list_definition_table(definition)

  expect_s3_class(table, "data.frame")
  expect_identical(nrow(table), 9L)
  expect_identical(
    names(table)[1:5],
    c("list_name", "name", "displayName", "description", "type")
  )
  expect_type(table[["choices"]], "list")
  expect_type(table[["form_order"]], "integer")
  expect_type(table[["required"]], "logical")
  expect_identical(table[["type"]][[4]], "choice")

  expect_identical(as.data.frame(definition), table)

  expect_false("form_order" %in% names(sp_list_definition_table(definition, custom = FALSE)))
  expect_true(
    "custom_form_order" %in%
      names(sp_list_definition_table(definition, custom_prefix = "custom_"))
  )

  # Also accepts a path
  expect_identical(sp_list_definition_table(example_path()), table)
})

test_that("sp_list_definition_table errors for custom keys that match properties", {
  definition <- as_sp_list_definition(
    list(
      displayName = "Test",
      columns = list(
        list(name = "A", text = list(), custom = list(displayName = "x"))
      )
    )
  )

  expect_snapshot(sp_list_definition_table(definition), error = TRUE)
})

test_that("clean_live_column drops read-only properties and default values", {
  live <- list(
    columnGroup = "Custom Columns",
    description = "",
    displayName = "Notes",
    enforceUniqueValues = FALSE,
    hidden = FALSE,
    id = "abc",
    indexed = FALSE,
    name = "Notes",
    readOnly = FALSE,
    required = FALSE,
    text = list(
      allowMultipleLines = TRUE,
      appendChangesToExistingText = FALSE,
      linesForEditing = 6L,
      textType = "plain"
    )
  )

  expect_identical(
    clean_live_column(live, keep_defaults = FALSE),
    list(
      displayName = "Notes",
      name = "Notes",
      text = list(allowMultipleLines = TRUE)
    )
  )

  kept <- clean_live_column(live, keep_defaults = TRUE)
  expect_false(has_name(kept, "id"))
  expect_false(has_name(kept, "columnGroup"))
  expect_false(has_name(kept, "description"))
  expect_identical(kept[["text"]][["linesForEditing"]], 6L)

  choice <- clean_live_column(
    list(
      name = "Status",
      choice = list(choices = list("a", "b"), displayAs = "dropDownMenu")
    ),
    keep_defaults = FALSE
  )
  expect_identical(choice[["choice"]], list(choices = c("a", "b")))
})

test_that("write_sp_list_yaml warns for list arguments with a definition", {
  out <- withr::local_tempfile(fileext = ".yaml")

  expect_snapshot(
    write_sp_list_yaml(read_sp_list_yaml(example_path()), out, include_views = TRUE),
    transform = \(x) sub("(Wrote .* to ).*$", "\\1<path>.", x)
  )
})

test_that("as_sp_list_definition stores empty views as NULL", {
  definition <- as_sp_list_definition(
    list(displayName = "Test", columns = list(), views = list())
  )

  expect_null(definition[["views"]])
  expect_false("views" %in% names(as_yaml_list(definition)))
})

test_that("write_sp_list_yaml returns a definition in the same order as the file", {
  definition <- as_sp_list_definition(list(
    displayName = "Test",
    columns = list(list(text = list(), displayName = "Status", name = "Status")),
    views = list(list(RowLimit = 10L, ViewFields = "Status", Title = "A"))
  ))

  out <- withr::local_tempfile(fileext = ".yaml")
  written <- suppressMessages(write_sp_list_yaml(definition, out))

  expect_identical(names(written[["columns"]][[1]]), c("name", "displayName", "text"))
  expect_identical(names(written[["views"]][[1]]), c("Title", "ViewFields", "RowLimit"))
  expect_identical(read_sp_list_yaml(out), written)
})
