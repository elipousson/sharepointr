test_that("sp_url_parse works", {
  test_file_url <- "https://bmore.sharepoint.com/:u:/r/sites/DOP-CPR/Shared%20Documents/Baltimore%20Greenway%20Trails%20Network/Green%20Network%20Addendum/Data/waterfront_promenade_osm.geojson?csf=1&web=1&e=jCKLbT"

  expect_true(
    is_sp_type_url(test_file_url, "u")
  )

  parsed_file_url <- sp_url_parse(test_file_url)

  expect_equal(
    parsed_file_url[["tenant"]],
    "bmore"
  )

  expect_equal(
    parsed_file_url[["site_name"]],
    "DOP-CPR"
  )

  expect_equal(
    parsed_file_url[["file"]],
    "waterfront_promenade_osm.geojson"
  )

  expect_equal(
    parsed_file_url[["file_path"]],
    "Baltimore Greenway Trails Network/Green Network Addendum/Data/waterfront_promenade_osm.geojson"
  )

  test_dir_url <- "https://bmore.sharepoint.com/:f:/r/sites/DOP-CPR/Shared%20Documents/Baltimore%20Greenway%20Trails%20Network/Green%20Network%20Addendum/Data?csf=1&web=1&e=5VuyG6"

  expect_true(
    is_sp_folder_url(test_dir_url)
  )

  parsed_dir_url <- sp_url_parse(test_dir_url)

  expect_equal(
    parsed_dir_url[["url_type"]],
    "f"
  )

  expect_equal(
    parsed_dir_url[["file"]],
    NULL
  )

  # FIXME: Replace w/ a DOP-CPR site url
  test_list_url <- "https://bmore.sharepoint.com/sites/MayorsOffice-DataGovernance/Lists/Data%20Governance%20Progress%20Tracker/AllItems.aspx?env=WebViewList"

  expect_true(
    is_sp_webview_list_url(test_list_url)
  )

  parsed_list_url <- sp_url_parse(test_list_url)

  expect_equal(
    parsed_list_url[["list_name"]],
    "Data Governance Progress Tracker"
  )

  expect_equal(
    parsed_list_url[["site_name"]],
    "MayorsOffice-DataGovernance"
  )

  test_drive_url <- "https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents/Forms/AllItems.aspx"

  expect_true(
    is_sp_drive_url(test_drive_url)
  )

  parsed_drive_url <- sp_url_parse(test_drive_url)

  expect_equal(
    parsed_drive_url[["drive_name"]],
    "Documents"
  )

  expect_equal(
    parsed_drive_url[["file_path"]],
    "/"
  )
})
