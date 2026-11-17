# rlang fails with "`fn` must be supplied" when an error with an `arg` is
# reported against an `eval()` frame, such as a knitr chunk or `source()`.
# Exported functions report errors from their own frame to avoid this.
eval_top_level <- function(expr) {
  eval(expr, globalenv())
}

test_that("argument errors keep their message when evaluated at top level", {
  expect_error(
    eval_top_level(quote(
      list_sp_list_items(list_name = "x", col_formatting = "bad")
    )),
    "`col_formatting` must be one of",
    fixed = TRUE
  )

  expect_error(
    eval_top_level(quote(get_sp_list(list_name = 1))),
    "must be supplied",
    fixed = TRUE
  )
})

test_that("errors are reported from the function called by the user", {
  cnd <- expect_error(
    eval_top_level(quote(
      list_sp_list_items(list_name = "x", col_formatting = "bad")
    ))
  )
  expect_identical(
    rlang::call_name(cnd$call),
    "list_sp_list_items"
  )
})
