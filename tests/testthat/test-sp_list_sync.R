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

test_that("compare_sp_list returns no changes for matching definitions", {
  definitions <- list(
    create_text_column("Notes"),
    create_choice_column("Status", c("a", "b")),
    create_number_column("Amount", decimal_places = "automatic"),
    create_boolean_column("OldColumn")
  )

  changes <- compare_sp_list(definitions, sp_list = live_meta)

  # Only the hyperlink column (no type in the definitions) is a delete
  expect_identical(changes[["name"]], "Link")
  expect_identical(changes[["action"]], "delete")
})

test_that("compare_sp_list finds added, updated, deleted, and blocked columns", {
  definitions <- list(
    create_text_column("Notes", multiple_lines = TRUE, display_name = "Project Notes"),
    create_choice_column("Status", c("a", "b", "c"), display_as = "checkBoxes"),
    create_text_column("Amount"),
    create_hyperlink_column("Link"),
    create_boolean_column("NewFlag"),
    create_text_column("Validated", validation = column_validation("=TRUE")),
    create_thumbnail_column("NewThumbnail")
  )

  changes <- compare_sp_list(definitions, sp_list = live_meta)

  expect_snapshot(
    print(changes[c("name", "action", "property", "method", "data_loss", "note")])
  )

  notes <- changes[changes[["name"]] == "Notes", ]
  expect_identical(notes[["property"]], c("displayName", "text.allowMultipleLines"))
  expect_identical(notes[["method"]], c("graph", "rest"))
  expect_identical(notes[["id"]], c("id-notes", "id-notes"))
  expect_true(all(changes[["object"]] == "column"))

  expect_identical(
    changes[["action"]][changes[["name"]] == "Amount"],
    "blocked"
  )
  expect_identical(
    changes[["action"]][changes[["name"]] == "OldColumn"],
    "delete"
  )
})

test_that("compare_sp_list flags changes that may cause data loss", {
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

  changes <- compare_sp_list(
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

test_that("compare_sp_list treats missing properties as default values", {
  # Graph doesn't return textType for single line text columns
  changes <- compare_sp_list(
    list(create_text_column("Notes", text_type = "plain", required = FALSE)),
    sp_list = live_meta[3]
  )

  expect_identical(nrow(changes), 0L)
})

test_that("compare_sp_list includes Title only if it is in the definitions", {
  changes <- compare_sp_list(
    list(create_text_column("Title", display_name = "Name")),
    sp_list = live_meta[1:2]
  )

  expect_identical(changes[["property"]], "displayName")
})

test_that("compare_sp_list accepts a YAML file path", {
  skip_if_not_installed("yaml12")

  path <- system.file("extdata", "example-list.yaml", package = "sharepointr")
  changes <- compare_sp_list(path, sp_list = list())

  expect_identical(unique(changes[["action"]]), "add")
  expect_length(changes[["name"]], 9)
})

test_that("compare_sp_list errors for data frame metadata", {
  expect_snapshot(
    compare_sp_list(
      list(create_text_column("A")),
      sp_list = data.frame(name = "A")
    ),
    error = TRUE
  )
})

test_that("print_changes summarizes planned changes", {
  changes <- compare_sp_list(
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

  expect_snapshot(print_changes(changes, list_name = "Test"))
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

# Views as returned by list_sp_list_views(as_data_frame = FALSE)
live_views <- list(
  list(
    Id = "v1",
    Title = "All Items",
    DefaultView = TRUE,
    ViewFields = c("LinkTitle", "Notes"),
    RowLimit = 30L,
    ViewQuery = "<OrderBy><FieldRef Name=\"ID\" /></OrderBy>"
  ),
  list(
    Id = "v2",
    Title = "Working",
    DefaultView = FALSE,
    ViewFields = c("LinkTitle", "Amount"),
    RowLimit = 30L
  ),
  list(Id = "v3", Title = "Old", DefaultView = FALSE, ViewFields = "LinkTitle")
)

test_that("view_change_rows finds added, updated, and deleted views", {
  views <- list(
    # Matched by Id and renamed
    list(Title = "Working Renamed", Id = "v2", ViewFields = c("Amount", "LinkTitle")),
    # Matched by Title; the saved query has a space before "/>"
    list(Title = "All Items", ViewQuery = "<OrderBy><FieldRef Name=\"ID\"/></OrderBy>"),
    list(Title = "Active", DefaultView = TRUE, CustomFormatter = list(a = 1L))
  )

  rows <- view_change_rows(views, live_views)

  expect_true(all(rows[["object"]] == "view"))
  expect_snapshot(print(rows[c("name", "id", "action", "property", "note")]))

  # Views that aren't in the definition are deleted
  expect_identical(
    rows[["action"]][rows[["name"]] == "Old"],
    "delete"
  )
})

test_that("view_change_rows protects the default view", {
  rows <- view_change_rows(
    list(
      list(Title = "All Items", DefaultView = FALSE),
      list(Title = "Working")
    ),
    live_views
  )

  expect_identical(
    rows[["action"]][rows[["name"]] == "All Items"],
    "blocked"
  )

  # Deleting the current default view is blocked without a new default
  rows <- view_change_rows(list(list(Title = "Working")), live_views)
  expect_identical(
    rows[["action"]][rows[["name"]] == "All Items"],
    "blocked"
  )
  expect_identical(rows[["action"]][rows[["name"]] == "Old"], "delete")

  # A view that is already the default isn't changed
  expect_null(view_change_rows(
    list(
      list(Title = "All Items", DefaultView = TRUE),
      list(Title = "Working"),
      list(Title = "Old")
    ),
    live_views
  ))
})

test_that("view_change_rows matches the new default view by Id or Title", {
  # A new view set as the default replaces the current default view
  rows <- view_change_rows(
    list(
      list(Title = "All Items", DefaultView = FALSE),
      list(Title = "Brand New", DefaultView = TRUE)
    ),
    live_views
  )
  expect_false(any(rows[["name"]] == "All Items" & rows[["action"]] == "blocked"))
  expect_identical(rows[["action"]][rows[["name"]] == "Brand New"], "add")

  # A renamed default view (matched by Id) is still the default view
  rows <- view_change_rows(
    list(
      list(Title = "Main", Id = "v1", DefaultView = TRUE),
      list(Title = "Working"),
      list(Title = "Old")
    ),
    live_views
  )
  expect_identical(rows[["property"]], "Title")
  expect_identical(rows[["action"]], "update")
})

test_that("apply_view_changes applies views in order", {
  calls <- list()
  record <- function(fn, ...) {
    calls[[length(calls) + 1]] <<- c(list(fn = fn), list(...))
    invisible(NULL)
  }

  local_mocked_bindings(
    create_sp_list_view = function(sp_list, ..., view_definition = NULL, call = NULL) {
      record("create", view_definition = view_definition)
    },
    update_sp_list_view = function(sp_list, view_title = NULL, view_id = NULL, ..., default_view = NULL, view_definition = NULL, call = NULL) {
      record("update", view_title = view_title, view_id = view_id, default_view = default_view, view_definition = view_definition)
    },
    delete_sp_list_view = function(sp_list, view_title = NULL, view_id = NULL, ..., confirm = TRUE, call = NULL) {
      record("delete", view_id = view_id, confirm = confirm)
    }
  )

  views <- list(
    list(Title = "Working Renamed", Id = "v2", RowLimit = 50L),
    list(Title = "Active", DefaultView = TRUE, ViewFields = "LinkTitle")
  )

  changes <- view_change_rows(views, live_views)
  changes[["status"]] <- plan_change_status(changes, delete = TRUE, allow_data_loss = FALSE)

  changes <- apply_view_changes(changes, views, sp_list = NULL)

  expect_identical(
    purrr::map_chr(calls, "fn"),
    c("create", "update", "update", "delete", "delete")
  )
  # New views are created without DefaultView, then set as the default
  expect_identical(calls[[1]][["view_definition"]], list(Title = "Active", ViewFields = "LinkTitle"))
  expect_identical(
    calls[[2]][["view_definition"]],
    list(Title = "Working Renamed", RowLimit = 50L)
  )
  expect_identical(calls[[3]][["view_title"]], "Active")
  expect_true(calls[[3]][["default_view"]])
  expect_identical(purrr::map_chr(calls[4:5], "view_id"), c("v1", "v3"))
  expect_true(all(changes[["status"]] == "applied"))
})

test_that("compare_sp_list only compares views if the definition has views", {
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$properties <- list(id = "list-1", displayName = "Projects")
  read_views <- 0

  local_mocked_bindings(
    get_sp_list_metadata = function(...) live_meta[3],
    list_sp_list_views = function(...) {
      read_views <<- read_views + 1
      live_views
    }
  )

  columns_only <- new_sp_list_definition(
    display_name = "Projects",
    columns = list(create_text_column("Notes"))
  )
  expect_identical(nrow(compare_sp_list(columns_only, sp_list = sp_list)), 0L)
  expect_identical(read_views, 0)

  with_views <- columns_only
  with_views[["views"]] <- list(list(Title = "All Items"), list(Title = "Working"))
  changes <- compare_sp_list(with_views, sp_list = sp_list)
  expect_identical(changes[["name"]], "Old")
  expect_identical(read_views, 1)

  # views = FALSE skips views
  expect_identical(nrow(compare_sp_list(with_views, sp_list = sp_list, views = FALSE)), 0L)
  expect_identical(read_views, 1)
})

test_that("compare_sp_list explains how to skip views if they can't be read", {
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$properties <- list(id = "list-1", displayName = "Projects")

  local_mocked_bindings(
    get_sp_list_metadata = function(...) list(),
    list_sp_list_views = function(...) cli_abort("No REST token.")
  )

  definition <- new_sp_list_definition(
    display_name = "Projects",
    views = list(list(Title = "All Items"))
  )

  expect_snapshot(compare_sp_list(definition, sp_list = sp_list), error = TRUE)
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
  expect_true(all(rows[["object"]] == "list"))
  expect_true(all(rows[["name"]] == "Projects"))

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

test_that("sync_sp_list updates a live list", {
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
  changes <- compare_sp_list(definition, sp_list = sp_list)
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

  planned <- suppressMessages(sync_sp_list(updated, sp_list = sp_list))
  expect_true(all(planned[["status"]] == "planned"))

  applied <- suppressMessages(
    sync_sp_list(updated, sp_list = sp_list, dry_run = FALSE)
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
  remaining <- compare_sp_list(updated, sp_list = sp_list)
  expect_identical(remaining[["property"]], "validation")

  # Switching back to a single line is skipped without allow_data_loss
  skipped <- suppressMessages(
    sync_sp_list(
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
  expect_identical(nrow(compare_sp_list(path)), 0L)

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

test_that("sync_sp_list updates views on a live list", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"
  skip_if_no_ms_site(test_site_url)

  definition <- as_sp_list_definition(list(
    displayName = sp_test_marker("sync-views"),
    description = "Temporary list created by sharepointr tests",
    columns = list(
      list(name = "Status", choice = list(choices = c("Active", "Closed"))),
      list(name = "Amount", number = list())
    ),
    views = list(
      list(Title = "All Items", ViewFields = c("LinkTitle", "Status")),
      list(Title = "Working", ViewFields = c("LinkTitle", "Amount"))
    )
  ))

  sp_list <- suppressMessages(
    create_sp_list(definition = definition, site_url = test_site_url)
  )

  withr::defer(
    try(
      suppressMessages(delete_sp_list(sp_list = sp_list, confirm = FALSE)),
      silent = TRUE
    )
  )

  expect_identical(nrow(compare_sp_list(definition, sp_list = sp_list)), 0L)

  working_id <- get_sp_list_view(sp_list, view_title = "Working")[["Id"]]

  updated <- definition
  updated[["views"]] <- list(
    # Renamed using the view Id, with a new field order and row limit
    list(
      Title = "Working Renamed",
      Id = working_id,
      ViewFields = c("Amount", "LinkTitle"),
      RowLimit = 50L
    ),
    # A new default view; All Items is deleted
    list(
      Title = "Active",
      DefaultView = TRUE,
      ViewFields = c("LinkTitle", "Status", "Amount"),
      ViewQuery = "<Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Choice\">Active</Value></Eq></Where>"
    )
  )

  applied <- suppressMessages(
    sync_sp_list(updated, sp_list = sp_list, dry_run = FALSE, delete = TRUE)
  )
  expect_true(all(applied[["status"]] == "applied"))

  views <- list_sp_list_views(sp_list)
  expect_setequal(views[["Title"]], c("Working Renamed", "Active"))
  expect_identical(views[["Title"]][views[["DefaultView"]]], "Active")

  renamed <- get_sp_list_view(sp_list, view_id = working_id)
  expect_identical(renamed[["Title"]], "Working Renamed")
  expect_identical(renamed[["ViewFields"]], c("Amount", "LinkTitle"))
  expect_identical(renamed[["RowLimit"]], 50L)

  expect_identical(nrow(compare_sp_list(updated, sp_list = sp_list)), 0L)
})

test_that("compare_sp_list blocks adding a list column with a long name", {
  long_name <- "IncompleteSubmissionJustification"
  definitions <- list(
    create_text_column("Notes"),
    create_choice_column("Status", c("a", "b")),
    create_number_column("Amount", decimal_places = "automatic"),
    create_boolean_column("OldColumn"),
    create_text_column(long_name)
  )

  changes <- compare_sp_list(definitions, sp_list = live_meta)
  added <- changes[changes[["name"]] == long_name, ]
  expect_identical(added[["action"]], "blocked")
  expect_match(added[["note"]], "longer than 32 characters")

  # Document libraries allow longer names
  library_definition <- as_sp_list_definition(
    list(
      displayName = "Test",
      list = list(template = "documentLibrary"),
      columns = definitions
    )
  )
  changes <- compare_sp_list(library_definition, sp_list = live_meta)
  expect_identical(
    changes[changes[["name"]] == long_name, ][["action"]],
    "add"
  )
})

test_that("compare_sp_list blocks adding a column without a column type", {
  definitions <- list(
    create_text_column("Notes"),
    list(name = "NoType", displayName = "No Type")
  )

  changes <- compare_sp_list(definitions, sp_list = live_meta)
  added <- changes[changes[["name"]] == "NoType", ]

  expect_identical(added[["action"]], "blocked")
  expect_identical(added[["note"]], "A column type is required to add a column.")
  expect_identical(
    plan_change_status(added, delete = FALSE, allow_data_loss = FALSE),
    "blocked"
  )
})
