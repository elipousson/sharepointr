test_that("multiplication works", {
  sp_site <- rlang::try_fetch(
    get_sp_site(
      "https://bmore.sharepoint.com/sites/DOP-ALL"
    ),
    error = function(cnd) {
      NULL
    }
  )

  skip_if_not(
    inherits(sp_site, "ms_site"),
    message = "User must have access to DOP-ALL SharePoint site"
  )

  sp_item <- get_sp_item(
    "https://bmore.sharepoint.com/:b:/r/sites/DOP-ALL/Shared%20Documents/General/Benton%20Building%20Directory%20-%20By%20Agency.pdf?csf=1&web=1&e=67O0Ch",
    site = sp_site
  )

  expect_s3_class(
    sp_item,
    "ms_drive_item"
  )
})
