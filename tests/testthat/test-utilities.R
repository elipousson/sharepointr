test_that("ms_obj_list_as_data_frame combines objects with missing properties", {
  # A property that is sometimes NULL (e.g. a task without a due date) and
  # sometimes a length-1 scalar must not cause a type mismatch when combined
  obj_with_value <- list(title = "Task 1", dueDateTime = "2024-01-01T00:00:00Z")
  obj_without_value <- list(title = "Task 2", dueDateTime = NULL)

  df <- ms_obj_list_as_data_frame(
    list(obj_with_value, obj_without_value),
    obj_col = "ms_obj"
  )

  expect_identical(nrow(df), 2L)
  expect_type(df[["dueDateTime"]], "character")
  expect_identical(df[["dueDateTime"]], c("2024-01-01T00:00:00Z", NA))
})

test_that("ms_obj_as_data_frame does not coerce sibling scalar properties", {
  # A length-1 list-valued property (e.g. a single Planner assignment) should
  # not cause other scalar properties in the same object to be left uncoerced
  obj <- list(
    title = "Task 1",
    isArchived = FALSE,
    assignments = list(user1 = list(orderHint = " !"))
  )

  df <- ms_obj_as_data_frame(obj, obj_col = "ms_obj")

  expect_type(df[["isArchived"]], "logical")
})

test_that("ms_obj_list_as_data_frame keeps keep_list_cols consistent across sizes", {
  # A dictionary-typed property (e.g. Planner appliedCategories) can appear
  # as missing, a single entry, or multiple entries across objects. Passing
  # its name via keep_list_cols should keep it as a list column throughout.
  obj_missing <- list(title = "Task 1", appliedCategories = list())
  obj_one <- list(title = "Task 2", appliedCategories = list(category1 = TRUE))
  obj_many <- list(
    title = "Task 3",
    appliedCategories = list(category1 = TRUE, category2 = TRUE)
  )

  df <- ms_obj_list_as_data_frame(
    list(obj_missing, obj_one, obj_many),
    obj_col = "ms_obj",
    keep_list_cols = "appliedCategories"
  )

  expect_identical(nrow(df), 3L)
  expect_type(df[["appliedCategories"]], "list")
})

test_that("sp_in_parallel() returns a plain function without daemons", {
  local_mocked_bindings(sp_use_parallel = function() FALSE)

  add <- function(x, y) x + y
  f <- sp_in_parallel(\(i) fn(i, k), fn = add, k = 10)

  expect_false(inherits(f, "crate"))
  expect_identical(purrr::map_dbl(1:3, f), c(11, 12, 13))
})

test_that("sp_in_parallel() uses purrr::in_parallel() with daemons", {
  skip_on_cran()
  skip_if_not_installed("carrier", "0.3.0")
  skip_if_not_installed("mirai", "2.5.1")

  mirai::daemons(1)
  withr::defer(mirai::daemons(0))

  add <- function(x, y) x + y
  f <- sp_in_parallel(\(i) fn(i, k), fn = add, k = 10)

  expect_s3_class(f, "crate")
  expect_identical(purrr::map_dbl(1:3, f), c(11, 12, 13))
})
