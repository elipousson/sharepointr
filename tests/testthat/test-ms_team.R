test_that("get_ms_team_channels works", {
  test_team_name <- "DOP-ALL"
  test_tenant <- "bmore"

  skip_if_no_ms_team(
    team_name = test_team_name,
    tenant = test_tenant
  )

  channels_df <- get_ms_team_channels(
    team_name = test_team_name,
    tenant = test_tenant
  )

  expect_s3_class(channels_df, "data.frame")

  expect_true(
    all(c("displayName", "ms_team") %in% names(channels_df))
  )

  channels_list <- get_ms_team_channels(
    team_name = test_team_name,
    tenant = test_tenant,
    as_data_frame = FALSE
  )

  expect_type(channels_list, "list")

  expect_equal(nrow(channels_df), length(channels_list))

  channels_n <- get_ms_team_channels(
    team_name = test_team_name,
    tenant = test_tenant,
    n = 1
  )

  expect_equal(nrow(channels_n), 1)
})
