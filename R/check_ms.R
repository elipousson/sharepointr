#' @noRd
check_ms <- function(x,
                     what,
                     ...,
                     allow_null = FALSE,
                     arg = caller_arg(x),
                     call = caller_env()) {
  if (inherits(x, what)) {
    return(invisible(NULL))
  }

  stop_input_type(
    x,
    what,
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}

#' @noRd
is_ms_site <- function(x) {
  inherits(x, "ms_site")
}

#' @noRd
check_ms_site <- function(x,
                          ...,
                          allow_null = FALSE,
                          arg = caller_arg(x),
                          call = caller_env()) {
  check_ms(
    x,
    what = "ms_site",
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}

#' @noRd
is_ms_drive <- function(x) {
  inherits(x, "ms_drive")
}

#' @noRd
check_ms_drive <- function(x,
                           ...,
                           allow_null = FALSE,
                           arg = caller_arg(x),
                           call = caller_env()) {
  check_ms(
    x,
    what = "ms_drive",
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}

#' @noRd
check_ms_drive_item <- function(x,
                                ...,
                                allow_null = FALSE,
                                arg = caller_arg(x),
                                call = caller_env()) {
  check_ms(
    x,
    what = "ms_drive_item",
    ...,
    allow_null = allow_null,
    arg = arg,
    call = call
  )
}
