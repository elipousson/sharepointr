#' @returns `TRUE` if `x` inherits from `"ms_object"` (and, if supplied,
#'   `what`), `FALSE` otherwise.
#' @noRd
is_ms_obj <- function(x, what = NULL) {
  inherits_all(x, c(what, "ms_object"))
}

#' @returns `TRUE` if `x` is a `ms_site` object, `FALSE` otherwise.
#' @noRd
is_ms_site <- function(x) {
  is_ms_obj(x, "ms_site")
}

#' @returns `TRUE` if `x` is a `ms_drive` object, `FALSE` otherwise.
#' @noRd
is_ms_drive <- function(x) {
  is_ms_obj(x, "ms_drive")
}

#' @returns `TRUE` if `x` is a `ms_drive_item` object (and, if
#'   `require_folder = TRUE`, a folder), `FALSE` otherwise.
#' @noRd
is_ms_drive_item <- function(x, require_folder = FALSE) {
  is_ms_obj(x, "ms_drive_item") && (!require_folder || x$is_folder())
}

#' @returns Invisibly returns `NULL` if `x` is a `what` object. Otherwise,
#'   errors via [stop_input_type()].
#' @noRd
check_ms_obj <- function(
  x,
  what,
  ...,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  if (is_ms_obj(x, what)) {
    return(invisible(NULL))
  }

  stop_input_type(
    x = x,
    what = what,
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}

#' @returns Invisibly returns `NULL` if `x` is a `ms_site` object. Otherwise,
#'   errors.
#' @noRd
check_ms_site <- function(
  x,
  ...,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  check_ms_obj(
    x,
    what = "ms_site",
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}

#' @returns Invisibly returns `NULL` if `x` is a `ms_drive` object.
#'   Otherwise, errors.
#' @noRd
check_ms_drive <- function(
  x,
  ...,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  check_ms_obj(
    x,
    what = "ms_drive",
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}
