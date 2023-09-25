#' Does x match the pattern of a URL?
#'
#' @noRd
is_url <- function(x) {
  if (!is_vector(x) || is_empty(x)) {
    return(FALSE)
  }

  grepl(
    "http[s]?://(?:[[:alnum:]]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+",
    x
  )
}

#' Check is a URL is valid
#'
#' @noRd
check_url <- function(url,
                      allow_null = FALSE,
                      call = caller_env()) {
  check_string(url, allow_empty = FALSE, allow_null = allow_null, call = call)

  if (allow_null && is_null(url)) {
    return(invisible(NULL))
  }

  if (is_url(url)) {
    return(invisible(NULL))
  }

  stop_input_type(
    url,
    what = "a valid url",
    call = call
  )
}

#' Does x use the supplied file extension?
#'
#' @noRd
is_fileext_path <- function(x, fileext, ignore.case = TRUE) {
  grepl(
    paste0(
      "\\.",
      paste0(fileext, collapse = "|"),
      "$(?!\\.)"
    ),
    x,
    ignore.case = ignore.case,
    perl = TRUE
  )
}

#' Variant of [stringr::str_match()] that returns a list where any `NA` values
#' are replaced with `NULL`
#'
#' @noRd
str_match_list <- function(string, pattern, i = 1, nm = NULL) {
  matches <- str_match(string, pattern)

  if (is.integer(i)) {
    matches <- matches[i, ]
  }

  matches <- list_replace_na(as.list(matches))

  if (is.null(nm)) {
    return(matches)
  }

  set_names(matches, nm)
}

#' Replace NA elements in a list
#'
#' @noRd
list_replace_na <- function(x, replace = NULL) {
  lapply(x, function(i) {
    if (is.na(i)) {
      return(replace)
    }
    i
  })
}

#' Replace empty elements in a list
#'
#' @noRd
list_replace_empty <- function(x, replace = NULL) {
  lapply(x, function(i) {
    if (is_empty(i)) {
      return(replace)
    }
    i
  })
}
