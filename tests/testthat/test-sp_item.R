test_that("get_sp_item and get_sp_item_properties works", {
  test_item_url <- "https://bmore.sharepoint.com/:x:/r/sites/DOP-CPR/Shared%20Documents/INSPIRE%20Program%20%F0%9F%8F%AB%F0%9F%9A%B8%F0%9F%8C%B3/INSPIRE%20Program%20Calendar.xlsx?d=w371f5202107241378dd79ad5d09c40f9&csf=1&web=1&e=87t30L"

  skip_if_no_ms_site(test_item_url)

  sp_item <- get_sp_item(test_item_url)

  expect_s3_class(
    sp_item,
    "ms_drive_item"
  )

  sp_item_properties <- get_sp_item_properties(test_item_url)

  expect_type(
    sp_item_properties,
    "list"
  )

  withr::with_tempdir(
    {
      download_sp_item(
        item = sp_item,
        new_path = "INSPIRE Program Calendar.xlsx"
      )

      expect_true(
        fs::file_exists("INSPIRE Program Calendar.xlsx")
      )
    }
  )
})

test_that("sp_share_id() encodes a URL as a sharing token", {
  url <- "https://contoso.sharepoint.com/:w:/r/sites/Team/Shared%20Documents/A%20file.docx?d=wabc&csf=1"
  share_id <- sp_share_id(url)

  expect_match(share_id, "^u!")
  expect_no_match(share_id, "[=+/\n]")

  encoded <- chartr("-_", "+/", sub("^u!", "", share_id))
  encoded <- paste0(encoded, strrep("=", (4 - nchar(encoded) %% 4) %% 4))
  expect_identical(rawToChar(jsonlite::base64_dec(encoded)), url)
})

test_that("is_sp_shares_url() excludes site, site page, and list URLs", {
  urls <- c(
    "https://contoso.sharepoint.com/:w:/r/sites/Team/Shared%20Documents/A.docx",
    "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/A.png",
    "https://contoso.sharepoint.com/sites/Team/_layouts/15/Doc.aspx?sourcedoc=%7Babc%7D",
    "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/Forms/AllItems.aspx",
    "https://contoso.sharepoint.com/sites/Team",
    "https://contoso.sharepoint.com/sites/Team/SitePages/Home.aspx",
    "https://contoso.sharepoint.com/:l:/r/sites/Team/Lists/Tasks",
    "https://contoso.sharepoint.com/sites/Team/Lists/Tasks/AllItems.aspx",
    "https://example.com/file.docx"
  )

  expect_identical(
    vapply(urls, is_sp_shares_url, logical(1), USE.NAMES = FALSE),
    c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )
  expect_false(is_sp_shares_url(NULL))
})

test_that("sp_url_site_url() gets the site URL from a URL path", {
  expect_identical(
    sp_url_site_url(
      "https://contoso.sharepoint.com/:w:/r/sites/Team_1/Shared%20Documents/A.docx"
    ),
    "https://contoso.sharepoint.com/sites/Team_1"
  )
  expect_identical(
    sp_url_site_url(
      "https://contoso.sharepoint.com/sites/Team/_layouts/15/Doc.aspx?sourcedoc=x"
    ),
    "https://contoso.sharepoint.com/sites/Team"
  )
  expect_null(sp_url_site_url(
    "https://contoso-my.sharepoint.com/personal/a_b_com/Documents/A.docx"
  ))
})

test_that("get_sp_item() uses the shares API for item URLs", {
  item <- list(properties = list(name = "A.png", id = "1"))
  shares_url <- NULL

  local_mocked_bindings(
    sp_shares_get_item = function(url, ...) {
      shares_url <<- url
      item
    },
    get_sp_drive = function(...) stop("get_sp_drive() shouldn't be called")
  )

  url <- "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/A.png"

  expect_identical(get_sp_item(url), item)
  expect_identical(shares_url, url)
  expect_identical(get_sp_item_properties(item_url = url), item$properties)
})

test_that("get_sp_item() falls back to the parsed URL if the shares API fails", {
  drive_args <- NULL

  local_mocked_bindings(
    sp_shares_get_item = function(...) cli::cli_abort("Forbidden (HTTP 403)."),
    get_sp_drive = function(drive_name = NULL, ..., site_url = NULL) {
      drive_args <<- list(drive_name = drive_name, site_url = site_url)
      list(get_item = function(path = NULL, itemid = NULL) list(path = path))
    },
    check_ms_drive = function(...) invisible(NULL)
  )

  item <- get_sp_item(
    "https://contoso.sharepoint.com/:x:/r/sites/Team/Shared%20Documents/Data/A.xlsx?d=wabc"
  )

  expect_identical(item, list(path = "Data/A.xlsx"))
  expect_identical(
    drive_args,
    list(
      drive_name = "Documents",
      site_url = "https://contoso.sharepoint.com/sites/Team"
    )
  )

  # The shares API error is the parent if the URL also can't be parsed
  expect_snapshot(error = TRUE, {
    get_sp_item(
      "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/A.png"
    )
  })
})
