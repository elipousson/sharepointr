# Mimics get_sp_list_metadata(as_data_frame = FALSE) for a list with internal
# columns, a single line text column, a choice column, a number column, and a
# hyperlink column (returned without a column type)
live_meta <- list(
  list(id = "id-title", name = "Title", displayName = "Title", text = list()),
  list(id = "id-modified", name = "Modified", displayName = "Modified", dateTime = list()),
  list(
    id = "id-notes",
    name = "Notes",
    displayName = "Notes",
    description = "",
    required = FALSE,
    hidden = FALSE,
    text = list(
      allowMultipleLines = FALSE,
      appendChangesToExistingText = FALSE,
      linesForEditing = 0L,
      maxLength = 255L
    )
  ),
  list(
    id = "id-status",
    name = "Status",
    displayName = "Status",
    required = FALSE,
    choice = list(
      allowTextEntry = FALSE,
      choices = list("a", "b"),
      displayAs = "dropDownMenu"
    )
  ),
  list(
    id = "id-amount",
    name = "Amount",
    displayName = "Amount",
    number = list(decimalPlaces = "automatic", displayAs = "number")
  ),
  list(id = "id-link", name = "Link", displayName = "Link"),
  list(id = "id-old", name = "OldColumn", displayName = "Old Column", boolean = list())
)

test_that("compare_sp_list_columns returns no changes for matching definitions", {
  definitions <- list(
    create_text_column("Notes"),
    create_choice_column("Status", c("a", "b")),
    create_number_column("Amount", decimal_places = "automatic"),
    create_boolean_column("OldColumn")
  )

  changes <- compare_sp_list_columns(definitions, sp_list = live_meta)

  # Only the hyperlink column (no type in the definitions) is a delete
  expect_identical(changes[["name"]], "Link")
  expect_identical(changes[["action"]], "delete")
})

test_that("compare_sp_list_columns finds added, updated, deleted, and blocked columns", {
  definitions <- list(
    create_text_column("Notes", multiple_lines = TRUE, display_name = "Project Notes"),
    create_choice_column("Status", c("a", "b", "c"), display_as = "checkBoxes"),
    create_text_column("Amount"),
    create_hyperlink_column("Link"),
    create_boolean_column("NewFlag"),
    create_text_column("Validated", validation = column_validation("=TRUE")),
    create_thumbnail_column("NewThumbnail")
  )

  changes <- compare_sp_list_columns(definitions, sp_list = live_meta)

  expect_snapshot(
    print(changes[c("name", "action", "property", "method", "data_loss", "note")])
  )

  notes <- changes[changes[["name"]] == "Notes", ]
  expect_identical(notes[["property"]], c("displayName", "text.allowMultipleLines"))
  expect_identical(notes[["method"]], c("graph", "rest"))
  expect_identical(notes[["column_id"]], c("id-notes", "id-notes"))

  expect_identical(
    changes[["action"]][changes[["name"]] == "Amount"],
    "blocked"
  )
  expect_identical(
    changes[["action"]][changes[["name"]] == "OldColumn"],
    "delete"
  )
})

test_that("compare_sp_list_columns flags changes that may cause data loss", {
  meta <- list(
    list(
      id = "id-notes",
      name = "Notes",
      text = list(allowMultipleLines = TRUE, linesForEditing = 6L)
    ),
    list(
      id = "id-status",
      name = "Status",
      choice = list(choices = list("a", "b"), displayAs = "checkBoxes")
    )
  )

  changes <- compare_sp_list_columns(
    list(
      create_text_column("Notes", multiple_lines = FALSE),
      create_choice_column("Status", c("a", "b"), display_as = "radioButtons")
    ),
    sp_list = meta
  )

  expect_identical(changes[["data_loss"]], c(TRUE, TRUE))
  expect_identical(changes[["method"]], c("rest", "rest"))

  expect_identical(
    plan_change_status(changes, delete = FALSE, allow_data_loss = FALSE),
    c("skipped", "skipped")
  )
  expect_identical(
    plan_change_status(changes, delete = FALSE, allow_data_loss = TRUE),
    c("planned", "planned")
  )
})

test_that("compare_sp_list_columns treats missing properties as default values", {
  # Graph doesn't return textType for single line text columns
  changes <- compare_sp_list_columns(
    list(create_text_column("Notes", text_type = "plain", required = FALSE)),
    sp_list = live_meta[3]
  )

  expect_identical(nrow(changes), 0L)
})

test_that("compare_sp_list_columns includes Title only if it is in the definitions", {
  changes <- compare_sp_list_columns(
    list(create_text_column("Title", display_name = "Name")),
    sp_list = live_meta[1:2]
  )

  expect_identical(changes[["property"]], "displayName")
})

test_that("compare_sp_list_columns accepts a YAML file path", {
  skip_if_not_installed("yaml12")

  path <- system.file("extdata", "example-list.yaml", package = "sharepointr")
  changes <- compare_sp_list_columns(path, sp_list = list())

  expect_identical(unique(changes[["action"]]), "add")
  expect_length(changes[["name"]], 9)
})

test_that("compare_sp_list_columns errors for data frame metadata", {
  expect_snapshot(
    compare_sp_list_columns(
      list(create_text_column("A")),
      sp_list = data.frame(name = "A")
    ),
    error = TRUE
  )
})

test_that("print_column_changes summarizes planned changes", {
  changes <- compare_sp_list_columns(
    list(
      create_text_column("Notes", multiple_lines = TRUE),
      create_text_column("Amount"),
      create_boolean_column("NewFlag")
    ),
    sp_list = live_meta
  )

  changes[["status"]] <- plan_change_status(
    changes,
    delete = FALSE,
    allow_data_loss = FALSE
  )

  expect_snapshot(print_column_changes(changes, list_name = "Test"))
})

test_that("get_definition_sp_list uses and checks the definition id", {
  new_ms_list <- function(id, display_name = "Projects") {
    sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
    sp_list$properties <- list(id = id, displayName = display_name)
    sp_list
  }

  definition <- new_sp_list_definition(
    display_name = "Projects",
    read_only = list(id = "list-1", parentReference = list(siteId = "site-1"))
  )

  get_args <- NULL

  local_mocked_bindings(
    get_sp_site = function(site_id, ...) paste0("site:", site_id),
    get_sp_list = function(list_name = NULL, list_id = NULL, ..., site = NULL) {
      get_args <<- list(list_name = list_name, list_id = list_id, site = site, ...)
      new_ms_list(list_id %||% "list-from-name")
    }
  )

  # The id and parentReference.siteId are used to get the list
  sp_list <- get_definition_sp_list(definition)
  expect_identical(sp_list$properties$id, "list-1")
  expect_identical(get_args[["site"]], "site:site-1")

  # Additional arguments are used in place of parentReference.siteId
  get_definition_sp_list(definition, site_url = "https://example.com")
  expect_identical(get_args[["list_id"]], "list-1")
  expect_identical(get_args[["site_url"]], "https://example.com")

  # Without an id, the displayName is used
  get_definition_sp_list(new_sp_list_definition(display_name = "Projects"))
  expect_identical(get_args[["list_name"]], "Projects")

  # A list with a different id is an error
  expect_snapshot(
    get_definition_sp_list(definition, sp_list = new_ms_list("list-2", "Other")),
    error = TRUE
  )
})

test_that("normalize_sp_formula matches formulas saved by SharePoint", {
  pairs <- list(
    c('=TEXT([Amount],"0.00")', '=TEXT(Amount,"0.00")'),
    c('=IF(ISBLANK([Total Cost]),"",[Amount] + 1)', '=IF(ISBLANK([Total Cost]),"",Amount+1)'),
    c('=if( [Amount]>0 , "[Amount]", "no" )', '=IF(Amount>0,"[Amount]","no")')
  )

  for (pair in pairs) {
    expect_identical(normalize_sp_formula(pair[[1]]), normalize_sp_formula(pair[[2]]))
  }

  # String literals aren't normalized
  expect_false(identical(
    normalize_sp_formula('=IF(A,"a b","")'),
    normalize_sp_formula('=IF(A,"ab","")')
  ))

  expect_true(same_column_value(
    '=TEXT([Amount],"0.00")',
    '=TEXT(Amount,"0.00")',
    "formula",
    "calculated"
  ))
})

test_that("list_change_rows compares list settings", {
  properties <- list(
    displayName = "Projects",
    description = "",
    list = list(contentTypesEnabled = FALSE, hidden = FALSE, template = "genericList")
  )

  definition <- new_sp_list_definition(
    display_name = "Projects",
    description = "All projects",
    list_info = list(template = "documentLibrary", hidden = TRUE)
  )

  rows <- list_change_rows(definition, properties)

  expect_identical(rows[["property"]], c("description", "list.template", "list.hidden"))
  expect_identical(rows[["action"]], c("update", "blocked", "update"))
  expect_true(all(is.na(rows[["name"]])))

  expect_null(
    list_change_rows(
      new_sp_list_definition(
        display_name = "Projects",
        list_info = list(template = "genericList", hidden = FALSE)
      ),
      properties
    )
  )
})

test_that("diff_column_definition returns only changed properties", {
  current <- live_meta[[4]]

  expect_identical(
    diff_column_definition(
      list(
        name = "Status",
        displayName = "Status",
        required = TRUE,
        choice = list(choices = c("a", "b", "c"), displayAs = "dropDownMenu")
      ),
      current
    ),
    list(required = TRUE, choice = list(choices = c("a", "b", "c")))
  )

  expect_identical(
    diff_column_definition(list(name = "Status", displayName = "Status"), current),
    list()
  )
})

test_that("sync_sp_list_columns updates a live list", {
  skip_if_not_installed("yaml12")
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"
  skip_if_no_ms_site(test_site_url)

  definition <- as_sp_list_definition(
    list(
      displayName = sp_test_marker("sync"),
      description = "Temporary list created by sharepointr tests",
      columns = list(
        list(name = "Title", displayName = "Item Name", text = list()),
        list(name = "Notes", displayName = "Notes", text = list()),
        list(
          name = "Status",
          choice = list(choices = c("a", "b"), displayAs = "dropDownMenu")
        ),
        list(name = "Amount", number = list(decimalPlaces = "two")),
        list(
          name = "Code",
          text = list(maxLength = 20L),
          validation = column_validation("=LEN([Code])<10", "Too long")
        ),
        list(name = "Flag", boolean = list(), custom = list(form_order = 1L)),
        list(
          name = "AmountText",
          calculated = list(formula = "=TEXT([Amount],\"0.00\")", outputType = "text")
        )
      )
    )
  )

  sp_list <- suppressMessages(
    create_sp_list(definition = definition, site_url = test_site_url)
  )

  withr::defer(
    try(
      suppressMessages(delete_sp_list(sp_list = sp_list, confirm = FALSE)),
      silent = TRUE
    )
  )

  # A new list matches its definition (including the Title display name and
  # the calculated column) except for validation, which can't be read with
  # the Graph API
  changes <- compare_sp_list_columns(definition, sp_list = sp_list)
  expect_identical(changes[["action"]], "unverified")
  expect_identical(changes[["property"]], "validation")

  title <- get_sp_list_column(sp_list = sp_list, column_name = "Title")
  expect_identical(title[["displayName"]], "Item Name")
  expect_false(title[["required"]])

  # Validation is enforced by SharePoint
  expect_error(
    sp_list$create_item(Code = "far too long for the validation formula")
  )

  item <- sp_list$create_item(
    Notes = "short value",
    Status = "a"
  )

  updated <- definition
  updated[["description"]] <- "Updated by sharepointr tests"
  updated[["list"]] <- list(contentTypesEnabled = TRUE)
  updated[["columns"]][[2]][["displayName"]] <- "Project Notes"
  updated[["columns"]][[2]][["text"]] <- list(allowMultipleLines = TRUE)
  updated[["columns"]][[3]][["choice"]][["displayAs"]] <- "checkBoxes"
  updated[["columns"]][[4]][["number"]][["decimalPlaces"]] <- "none"

  planned <- suppressMessages(sync_sp_list_columns(updated, sp_list = sp_list))
  expect_true(all(planned[["status"]] == "planned"))

  applied <- suppressMessages(
    sync_sp_list_columns(updated, sp_list = sp_list, dry_run = FALSE)
  )
  expect_true(all(applied[["status"]] == "applied"))

  list_properties <- sp_list$do_operation()
  expect_identical(list_properties[["description"]], "Updated by sharepointr tests")
  expect_true(list_properties[["list"]][["contentTypesEnabled"]])

  notes <- get_sp_list_column(sp_list = sp_list, column_name = "Notes")
  expect_identical(notes[["displayName"]], "Project Notes")
  expect_true(notes[["text"]][["allowMultipleLines"]])

  status <- get_sp_list_column(sp_list = sp_list, column_name = "Status")
  expect_identical(status[["choice"]][["displayAs"]], "checkBoxes")

  # Existing values are kept and multiple lines are allowed
  item <- sp_list$get_item(item$properties$id)
  expect_identical(item$properties$fields$Notes, "short value")
  item$do_operation(
    "fields",
    body = list(Notes = strrep("x", 300)),
    encode = "json",
    http_verb = "PATCH"
  )
  expect_identical(
    nchar(sp_list$get_item(item$properties$id)$properties$fields$Notes),
    300L
  )

  # Refresh list properties before comparing list settings again
  sp_list <- get_sp_list(list_id = sp_list$properties$id, site_url = test_site_url) |>
    suppressMessages()
  remaining <- compare_sp_list_columns(updated, sp_list = sp_list)
  expect_identical(remaining[["property"]], "validation")

  # Switching back to a single line is skipped without allow_data_loss
  skipped <- suppressMessages(
    sync_sp_list_columns(
      list(create_text_column("Notes", multiple_lines = FALSE)),
      sp_list = sp_list,
      dry_run = FALSE
    )
  )
  expect_true(all(skipped[["status"]] == "skipped"))
  expect_identical(
    skipped[["status"]][skipped[["property"]] %in% "text.allowMultipleLines"],
    "skipped"
  )

  # Write a YAML file from the live list
  path <- withr::local_tempfile(fileext = ".yaml")
  written <- suppressMessages(write_sp_list_yaml(sp_list, path))
  expect_identical(
    purrr::map_chr(written[["columns"]], "name"),
    c("Title", "Notes", "Status", "Amount", "Code", "Flag", "AmountText")
  )
  expect_identical(written[["list"]], list(contentTypesEnabled = TRUE, template = "genericList"))
  expect_identical(written[["id"]], sp_list$properties$id)
  expect_false(is.null(written[["parentReference"]][["siteId"]]))
  expect_false(has_name(written, "createdBy"))
  expect_true(all(purrr::map_lgl(written[["columns"]], \(col) is_string(col[["id"]]))))

  # The written file can find the list without sp_list or site_url and
  # matches the list (validation isn't written since Graph doesn't return it)
  expect_identical(nrow(compare_sp_list_columns(path)), 0L)

  # Creating a list from a definition with an id warns that the id is ignored
  expect_warning(
    expect_error(create_sp_list(definition = written, site = "not a site")),
    "existing list"
  )
  expect_identical(read_sp_list_yaml(path), written)

  # update_sp_list_column sends only changed properties
  expect_message(
    update_sp_list_column(
      sp_list = sp_list,
      column_name = "Amount",
      column_definition = list(name = "Amount", number = list(decimalPlaces = "none"))
    ),
    "unchanged"
  )
})
