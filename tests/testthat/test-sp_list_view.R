new_fake_ms_list <- function(id = "list-1") {
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$properties <- list(id = id, displayName = "Projects")
  sp_list
}

# A view as returned by the SharePoint REST API with expanded ViewFields
rest_view <- function(
  id,
  title,
  default = FALSE,
  hidden = FALSE,
  fields = c("LinkTitle", "Amount"),
  query = "<OrderBy><FieldRef Name=\"ID\" /></OrderBy>"
) {
  list(
    Id = id,
    Title = title,
    DefaultView = default,
    Hidden = hidden,
    PersonalView = FALSE,
    ViewType = "HTML",
    RowLimit = 30L,
    Paged = TRUE,
    Scope = 0L,
    ViewQuery = query,
    CustomFormatter = "",
    MobileView = FALSE,
    MobileDefaultView = FALSE,
    ServerRelativeUrl = paste0("/sites/Site/Lists/Projects/", title, ".aspx"),
    HtmlSchemaXml = "<View />",
    ViewFields = list(Items = as.list(fields), SchemaXml = "")
  )
}

# Mock the REST helper with a fake set of views and record requests
local_mock_views <- function(views, env = parent.frame()) {
  requests <- list()

  local_mocked_bindings(
    sp_list_rest_request = function(
      sp_list,
      path = NULL,
      method = "GET",
      body = NULL,
      merge = FALSE,
      call = caller_env()
    ) {
      requests[[length(requests) + 1]] <<- list(
        path = path,
        method = method,
        body = body,
        merge = merge
      )

      if (startsWith(path, "views?")) {
        return(list(value = views))
      }

      if (startsWith(path, "defaultview")) {
        return(purrr::detect(views, \(v) isTRUE(v$DefaultView)))
      }

      if (path == "views/add") {
        return(list(Id = "new-view"))
      }

      id <- regmatches(path, regexpr("(?<=views\\(guid')[^']+", path, perl = TRUE))
      if (length(id) == 1) {
        if (id == "new-view") {
          return(rest_view("new-view", body$parameters$Title %||% "New"))
        }
        return(purrr::detect(views, \(v) v$Id == id))
      }

      title <- regmatches(path, regexpr("(?<=getbytitle\\(')[^']+", path, perl = TRUE))
      if (length(title) == 1) {
        title <- utils::URLdecode(title)
        return(purrr::detect(views, \(v) v$Title == title))
      }

      NULL
    },
    .env = env
  )

  environment()
}

test_that("list_sp_list_views returns a data frame of views", {
  local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE),
    rest_view("v2", "Working View", fields = "LinkTitle"),
    rest_view("v3", "Untitled Form", hidden = TRUE)
  ))

  views <- list_sp_list_views(new_fake_ms_list())

  expect_s3_class(views, "data.frame")
  expect_identical(views[["Title"]], c("All Items", "Working View"))
  expect_identical(views[["ViewFields"]], list(c("LinkTitle", "Amount"), "LinkTitle"))
  expect_identical(views[["DefaultView"]], c(TRUE, FALSE))
  expect_type(views[["RowLimit"]], "integer")
  expect_false("HtmlSchemaXml" %in% names(views))
  expect_false("CustomFormatter" %in% names(views))

  expect_identical(nrow(list_sp_list_views(new_fake_ms_list(), hidden = TRUE)), 3L)

  view_list <- list_sp_list_views(new_fake_ms_list(), as_data_frame = FALSE)
  expect_identical(view_list[[2]][["ViewFields"]], "LinkTitle")
})

test_that("get_sp_list_view gets views by title, id, or the default view", {
  mock <- local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE),
    rest_view("v2", "Working View")
  ))

  expect_identical(get_sp_list_view(new_fake_ms_list())[["Title"]], "All Items")
  expect_identical(
    get_sp_list_view(new_fake_ms_list(), view_title = "Working View")[["Id"]],
    "v2"
  )
  # Titles are URL encoded
  expect_identical(
    mock$requests[[2]][["path"]],
    "views/getbytitle('Working%20View')?$expand=ViewFields"
  )
  expect_identical(
    get_sp_list_view(new_fake_ms_list(), view_id = "v2")[["Title"]],
    "Working View"
  )

  expect_snapshot(
    get_sp_list_view(new_fake_ms_list(), view_title = "A", view_id = "B"),
    error = TRUE
  )
})

test_that("create_sp_list_view sends SP.ViewCreationInformation properties", {
  mock <- local_mock_views(list(rest_view("v1", "All Items", default = TRUE)))

  view <- create_sp_list_view(
    new_fake_ms_list(),
    title = "Active",
    view_fields = "Amount",
    view_query = "<Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Choice\">Active</Value></Eq></Where>",
    row_limit = 50,
    default_view = TRUE,
    custom_formatter = list(additionalRowClass = "sp-field-severity--good"),
    hidden = TRUE
  ) |>
    suppressMessages()

  add <- purrr::detect(mock$requests, \(r) r$path == "views/add")
  expect_identical(add$method, "POST")
  expect_identical(
    add$body$parameters,
    list(
      Title = "Active",
      ViewFields = list("Amount"),
      Query = "<Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Choice\">Active</Value></Eq></Where>",
      RowLimit = 50L,
      SetAsDefaultView = TRUE,
      CustomFormatter = "{\"additionalRowClass\":\"sp-field-severity--good\"}",
      PersonalView = FALSE
    )
  )

  # Hidden is set with a MERGE request after the view is created
  merge <- purrr::detect(mock$requests, \(r) isTRUE(r$merge))
  expect_identical(merge$path, "views(guid'new-view')")
  expect_identical(merge$body, list(Hidden = TRUE))

  expect_identical(view[["Id"]], "new-view")
})

test_that("create_sp_list_view uses the default view fields if view_fields is NULL", {
  mock <- local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE, fields = c("LinkTitle", "Status"))
  ))

  suppressMessages(create_sp_list_view(new_fake_ms_list(), title = "Copy"))

  add <- purrr::detect(mock$requests, \(r) r$path == "views/add")
  expect_identical(add$body$parameters$ViewFields, list("LinkTitle", "Status"))
})

test_that("update_sp_list_view only changes properties that differ", {
  mock <- local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE),
    rest_view("v2", "Working View", fields = c("LinkTitle", "Amount"))
  ))

  # SharePoint saves queries with a space before "/>"
  expect_message(
    update_sp_list_view(
      new_fake_ms_list(),
      view_title = "Working View",
      view_query = "<OrderBy><FieldRef Name=\"ID\"/></OrderBy>",
      row_limit = 30,
      view_fields = c("LinkTitle", "Amount")
    ),
    "unchanged"
  )

  mock$requests <- list()

  suppressMessages(update_sp_list_view(
    new_fake_ms_list(),
    view_title = "Working View",
    title = "Renamed",
    row_limit = 30,
    view_fields = c("Amount", "LinkTitle")
  ))

  paths <- purrr::map_chr(mock$requests, "path")
  merge <- purrr::detect(mock$requests, \(r) isTRUE(r$merge))

  expect_identical(merge$body, list(Title = "Renamed"))
  expect_identical(
    paths[grepl("viewfields", paths)],
    c(
      "views(guid'v2')/viewfields/removeallviewfields",
      "views(guid'v2')/viewfields/addviewfield('Amount')",
      "views(guid'v2')/viewfields/addviewfield('LinkTitle')"
    )
  )
})

test_that("update_sp_list_view and delete_sp_list_view protect the default view", {
  local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE),
    rest_view("v2", "Working View")
  ))

  expect_snapshot(error = TRUE, {
    update_sp_list_view(new_fake_ms_list(), view_title = "All Items", default_view = FALSE)
    delete_sp_list_view(new_fake_ms_list(), view_title = "All Items", confirm = FALSE)
    delete_sp_list_view(new_fake_ms_list())
  })
})

test_that("delete_sp_list_view deletes a view", {
  mock <- local_mock_views(list(
    rest_view("v1", "All Items", default = TRUE),
    rest_view("v2", "Working View")
  ))

  suppressMessages(
    delete_sp_list_view(new_fake_ms_list(), view_title = "Working View", confirm = FALSE)
  )

  delete <- purrr::detect(mock$requests, \(r) r$method == "DELETE")
  expect_identical(delete$path, "views(guid'v2')")
})

test_that("validate_view_definition validates view properties", {
  expect_identical(
    validate_view_definition(list(Title = "A", RowLimit = 10, ViewFields = list("X", "Y"))),
    list(Title = "A", RowLimit = 10L, ViewFields = c("X", "Y"))
  )

  expect_snapshot(error = TRUE, {
    validate_view_definition(list(Title = "A", row_limit = 10))
    validate_view_definition(list(RowLimit = 10))
    validate_view_definition(list(Title = "A", Scope = 5))
    validate_view_definition(list(Title = "A", CustomFormatter = "{not json"))
  })
})

test_that("normalize_view_query matches queries saved by SharePoint", {
  expect_identical(
    normalize_view_query("<Where>\n  <Eq><FieldRef Name=\"A\"/><Value Type=\"Text\">x</Value></Eq>\n</Where>"),
    normalize_view_query("<Where><Eq><FieldRef Name=\"A\" /><Value Type=\"Text\">x</Value></Eq></Where>")
  )

  expect_true(same_view_value("{\"a\": 1}", "{\"a\":1}", "CustomFormatter"))
})

test_that("list view functions work with a live list", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-CIP/"
  skip_if_no_ms_site(test_site_url)

  sp_list <- suppressMessages(
    create_sp_list(
      list_name = sp_test_marker("views"),
      description = "Temporary list created by sharepointr tests",
      columns = list(
        create_text_column("Project"),
        create_choice_column("Status", c("Active", "Closed")),
        create_number_column("Amount")
      ),
      site_url = test_site_url
    )
  )

  withr::defer(
    try(
      suppressMessages(delete_sp_list(sp_list = sp_list, confirm = FALSE)),
      silent = TRUE
    )
  )

  views <- list_sp_list_views(sp_list)
  expect_identical(views[["Title"]], "All Items")

  view <- suppressMessages(
    create_sp_list_view(
      sp_list,
      title = "Active Projects",
      view_fields = c("LinkTitle", "Status", "Amount"),
      view_query = "<Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Choice\">Active</Value></Eq></Where>",
      row_limit = 50,
      custom_formatter = list(
        `$schema` = "https://developer.microsoft.com/json-schemas/sp/v2/row-formatting.schema.json",
        additionalRowClass = "sp-field-severity--good"
      )
    )
  )

  expect_identical(view[["ViewFields"]], c("LinkTitle", "Status", "Amount"))
  expect_identical(view[["RowLimit"]], 50L)

  # The saved query matches the proposed query
  expect_message(
    update_sp_list_view(
      sp_list,
      view_title = "Active Projects",
      view_query = "<Where><Eq><FieldRef Name=\"Status\"/><Value Type=\"Choice\">Active</Value></Eq></Where>"
    ),
    "unchanged"
  )

  updated <- suppressMessages(
    update_sp_list_view(
      sp_list,
      view_title = "Active Projects",
      title = "Active",
      view_fields = c("LinkTitle", "Amount"),
      default_view = TRUE
    )
  )

  expect_identical(updated[["Title"]], "Active")
  expect_identical(updated[["ViewFields"]], c("LinkTitle", "Amount"))
  expect_true(updated[["DefaultView"]])
  expect_identical(get_sp_list_view(sp_list)[["Title"]], "Active")

  # All Items is no longer the default view, so it can be deleted
  suppressMessages(delete_sp_list_view(sp_list, view_title = "All Items", confirm = FALSE))
  expect_identical(list_sp_list_views(sp_list)[["Title"]], "Active")

  expect_error(
    delete_sp_list_view(sp_list, view_title = "Active", confirm = FALSE),
    "default view"
  )
})
