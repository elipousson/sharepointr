test_that("sp_url_parse works", {
  test_file_url <- "https://bmore.sharepoint.com/:u:/r/sites/DOP-CPR/Shared%20Documents/Baltimore%20Greenway%20Trails%20Network/Green%20Network%20Addendum/Data/waterfront_promenade_osm.geojson?csf=1&web=1&e=jCKLbT"
  test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-CPR/Shared%20Documents/Baltimore%20Greenway%20Trails%20Network/Green%20Network%20Addendum/Data?csf=1&web=1&e=5VuyG6"
  # FIXME: Replace w/ a DOP-CPR site url
  test_list_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker/AllItems.aspx?env=WebViewList"
  test_drive_url <- "https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents/Forms/AllItems.aspx"

  expect_true(
    is_sp_type_url(test_file_url, "u")
  )

  expect_false(
    is_sp_url(character(0))
  )

  parsed_file_url <- sp_url_parse(test_file_url)

  expect_identical(parsed_file_url[["tenant"]], "bmore")

  expect_identical(parsed_file_url[["site_name"]], "DOP-CPR")

  expect_identical(
    parsed_file_url[["file"]],
    "waterfront_promenade_osm.geojson"
  )

  expect_identical(
    parsed_file_url[["file_path"]],
    "Baltimore Greenway Trails Network/Green Network Addendum/Data/waterfront_promenade_osm.geojson"
  )

  expect_true(
    is_sp_folder_url(test_dir_url)
  )

  parsed_dir_url <- sp_url_parse(test_dir_url)

  expect_identical(parsed_dir_url[["url_type"]], "f")

  expect_null(parsed_dir_url[["file"]])

  expect_true(
    is_sp_webview_list_url(test_list_url)
  )

  parsed_list_url <- sp_url_parse(test_list_url)

  expect_identical(
    parsed_list_url[["list_name"]],
    "Data Governance Progress Tracker"
  )

  expect_identical(
    parsed_list_url[["site_name"]],
    "MayorsOffice-DataGovernance"
  )

  expect_true(
    is_sp_drive_url(test_drive_url)
  )

  parsed_drive_url <- sp_url_parse(test_drive_url)

  expect_identical(parsed_drive_url[["drive_name"]], "Documents")

  expect_identical(parsed_drive_url[["file_path"]], "/")
})

test_that("sp_url_parse works with list URLs with no view", {
  urls <- c(
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Rooms",
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Rooms/",
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Rooms?e=abc",
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Rooms/Custom%20View.aspx"
  )

  expect_identical(is_sp_webview_list_url(urls), rep(TRUE, 4))

  for (url in urls) {
    parsed <- sp_url_parse(url)
    expect_identical(parsed[["list_name"]], "DOP Rooms")
    expect_identical(
      parsed[["site_url"]],
      "https://bmore.sharepoint.com/sites/DOP-ALL"
    )
  }

  expect_false(is_sp_webview_list_url(
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Rooms/Folder/Item"
  ))
})

test_that("sp_url_parse_path works with regex metacharacters in drive_name", {
  test_path <- "/:f:/r/sites/DOP-CPR/Shared Documents (1)/Data/file.csv"

  parsed_path <- sp_url_parse_path(test_path)

  expect_identical(parsed_path[["drive_name"]], "Documents (1)")

  expect_identical(parsed_path[["file_path"]], "Data/file.csv")
})

test_that("sp_url_parse decodes URL paths once", {
  parsed <- sp_url_parse(
    "https://bmore.sharepoint.com/:x:/r/sites/DOP-CPR/Shared%20Documents/C%23%20Notes%20100%25.xlsx?d=wabc"
  )
  expect_identical(parsed[["file"]], "C# Notes 100%.xlsx")
  expect_identical(parsed[["file_path"]], "/C# Notes 100%.xlsx")

  parsed <- sp_url_parse(
    "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/Rooms%20%2525%20Done/AllItems.aspx"
  )
  expect_identical(parsed[["list_name"]], "Rooms %25 Done")

  parsed <- sp_url_parse(
    "https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents%20%2525/Forms/AllItems.aspx"
  )
  expect_identical(parsed[["drive_name"]], "Documents %25")
})

test_that("sp_url_parse errors if a URL has no site name", {
  expect_snapshot(error = TRUE, {
    sp_url_parse(
      "https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents/file.csv"
    )
    sp_url_parse("https://contoso.sharepoint.us/sites/Team/Lists/Tasks")
  })
})
