test_that("sp_url_parse works", {
  test_file_url <- "https://bmore.sharepoint.com/:u:/r/sites/DOP-CPR/Shared%20Documents/Baltimore%20Greenway%20Trails%20Network/Green%20Network%20Addendum/Data/waterfront_promenade_osm.geojson?csf=1&web=1&e=jCKLbT"
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
  parsed_dir_url <- sp_url_parse(test_dir_url)

  expect_equal(
    parsed_dir_url[["url_type"]],
    "f"
  )

  expect_equal(
    parsed_dir_url[["file"]],
    NULL
  )
})
