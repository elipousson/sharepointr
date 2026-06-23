test_that("read_sharepoint works", {
  test_doc_url <- "https://bmore.sharepoint.com/:w:/r/sites/DOP-CPR/Shared%20Documents/INSPIRE%20Program%20%F0%9F%8F%AB%F0%9F%9A%B8%F0%9F%8C%B3/INSPIRE%20Planning%20and%20Program%20Management%20Guide.docx?d=wb47abf38a0fa4a0686a1c1d5cbaa5d65&csf=1&web=1&e=7eGTL9"
  test_list_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/Lists/DOP%20Employees/Staff%20Directory.aspx"

  skip_if_no_ms_site(test_doc_url)

  rdocx_out <- suppressWarnings(
    read_sharepoint(test_doc_url)
  )

  expect_s3_class(
    rdocx_out,
    "rdocx"
  )

  skip_if_no_ms_site(test_list_url)

  list_df_out <- read_sharepoint(test_list_url)

  expect_s3_class(
    list_df_out,
    "data.frame"
  )
})
