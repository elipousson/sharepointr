test_that("list_sp_site_user_info works", {
  test_site_url <- "https://bmore.sharepoint.com/sites/DOP-ALL/"

  skip_if_no_ms_site(test_site_url)

  user_info <- list_sp_site_user_info(
    site_url = test_site_url
  )

  expect_s3_class(user_info, "data.frame")

  visible_user_info <- list_sp_site_user_info(
    site_url = test_site_url,
    user_type = "visible"
  )

  expect_false(any(visible_user_info[["UserInfoHidden"]] %in% TRUE))
  expect_identical(
    nrow(visible_user_info),
    sum(!(user_info[["UserInfoHidden"]] %in% TRUE))
  )
})

test_that("update_sp_list_person_items matches users from the User Information List", {
  site_ids <- character(0)
  user_types <- character(0)

  local_mocked_bindings(
    get_sp_site = function(...) stop("The site should not be requested"),
    list_sp_site_user_info = function(..., sp_site = NULL, user_type = "all") {
      site_ids <<- c(site_ids, sp_site$properties$id)
      user_types <<- c(user_types, user_type)
      user_info <- data.frame(
        id = c("7", "8", "9"),
        EMail = c("a@example.com", "b@example.com", "c@example.com"),
        UserInfoHidden = c(FALSE, FALSE, TRUE)
      )

      if (user_type == "visible") {
        user_info <- user_info[!user_info$UserInfoHidden, ]
      }

      user_info
    },
    update_sp_list_items = function(data, ...) data
  )

  # Minimal stand-in for a Microsoft365R::ms_list
  sp_list <- structure(new.env(), class = c("ms_list", "ms_object"))
  sp_list$properties <- list(parentReference = list(siteId = "site-123"))

  # Hidden users (c@example.com) are not matched by default
  expect_message(
    items <- update_sp_list_person_items(
      sp_list = sp_list,
      data = list(
        list(id = "1", Owner = "A@example.com"),
        list(id = "2", Owner = "b@example.com"),
        list(id = "3", Owner = "c@example.com")
      ),
      column_name = "Owner"
    ),
    "can't be matched"
  )

  expect_identical(site_ids, "site-123")
  # Hidden users are excluded by the User Information List query
  expect_identical(user_types, "visible")
  expect_identical(
    items,
    data.frame(id = c("1", "2", "3"), OwnerLookupId = c("7", "8", NA))
  )

  # Hidden users can be matched with `allow_hidden = TRUE`
  expect_identical(
    update_sp_list_person_items(
      sp_list = sp_list,
      data = data.frame(id = "3", Owner = "c@example.com"),
      column_name = "Owner",
      allow_hidden = TRUE
    ),
    data.frame(id = "3", OwnerLookupId = "9")
  )
  expect_identical(user_types, c("visible", "all"))

  # Hidden users are dropped from user supplied data
  expect_identical(
    update_sp_list_person_items(
      sp_list = sp_list,
      data = data.frame(id = "3", Owner = "c@example.com"),
      column_name = "Owner",
      user_info_data = data.frame(
        id = c("7", "9"),
        EMail = c("a@example.com", "c@example.com"),
        UserInfoHidden = c(FALSE, TRUE)
      )
    ),
    data.frame(id = "3", OwnerLookupId = NA_character_)
  ) |>
    expect_message("can't be matched")
})

test_that("drop_hidden_users drops hidden users from data frames and records", {
  expect_identical(
    drop_hidden_users(
      data.frame(id = c("1", "2", "3"), UserInfoHidden = c(FALSE, NA, TRUE))
    ),
    data.frame(id = c("1", "2"), UserInfoHidden = c(FALSE, NA))
  )

  expect_identical(
    drop_hidden_users(
      list(list(id = "1"), list(id = "2", UserInfoHidden = TRUE))
    ),
    list(list(id = "1"))
  )
})
