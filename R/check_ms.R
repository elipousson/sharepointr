#' @noRd
is_ms_obj <- function(x, what = NULL) {
  inherits_all(x, c(what, "ms_object"))
}

#' @noRd
is_ms_site <- function(x) {
  is_ms_obj(x, "ms_site")
}

#' @noRd
is_ms_drive <- function(x) {
  is_ms_obj(x, "ms_drive")
}

#' @noRd
is_ms_drive_item <- function(x, require_folder = FALSE) {
  is_ms_obj(x, "ms_drive_item") && (!require_folder || x$is_folder())
}

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
