#' Shared general definitions for Microsoft Graph API parameters
#'
#' @name ms_graph_arg_terms
#' @param filter A string with [an OData
#'   expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
#'   apply as a filter to the results. Learn more in the [Microsoft Graph API
#'   documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
#'   on using filter query parameters.
#' @param n Maximum number of lists, plans, tasks, or other items to return.
#'   Defaults to `NULL` which sets n to `Inf`.
#' @keywords internal
NULL

#' Shared general definitions for Microsoft Graph objects
#'
#' @name ms_graph_obj_terms
#' @param site A `ms_site` object. If `site` is supplied, `site_url`,
#'   `site_name`, and `site_id` are ignored.
#' @param plan A `ms_plan` object. If `plan` is supplied, `plan_title`,
#'   `plan_id`, and any additional parameters passed to `...` are ignored.
#' @param sp_list A `ms_list` object. If supplied, `list_name`, `list_id`,
#'   `site_url`, `site`, `drive_name`, `drive_id`, `drive`, and any additional
#'   parameters passed to `...` are all ignored.
#' @keywords internal
NULL


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

#' @noRd
str_remove_slash <- function(string, before = TRUE, after = FALSE) {
  pattern <- NULL

  if (before) {
    pattern <- c(pattern, "^/")
  }

  if (after) {
    pattern <- c(pattern, "/$")
  }

  stringr::str_remove_all(string, pattern = paste0(pattern, collapse = "|"))
}

#' @noRd
str_c_url <- function(..., sep = "/") {
  stringr::str_c(..., sep = sep)
}

#' @noRd
str_c_fsep <- function(..., fsep = .Platform$file.sep) {
  stringr::str_c(..., sep = fsep)
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

#' Convert a list of ms_obj elements to a data frame of properties with a list
#' column of objects
#'
#' @noRd
#' @importFrom vctrs vec_rbind
ms_obj_list_as_data_frame <- function(ms_obj_list,
                                      obj_col = "ms_plan",
                                      keep_list_cols = NULL,
                                      .name_repair = "universal_quiet",
                                      .error_call = caller_env()) {
  ms_obj_list <- lapply(
    ms_obj_list,
    function(obj) {
      ms_obj_as_data_frame(
        obj,
        obj_col = obj_col,
        keep_list_cols = keep_list_cols,
        .name_repair = .name_repair,
        .error_call = .error_call
      )
    }
  )

  vctrs::vec_rbind(!!!ms_obj_list, .error_call = .error_call)
}


#' Convert a ms_obj object to a data frame of properties with a list column of
#' objects
#'
#' @noRd
#' @importFrom vctrs list_sizes
ms_obj_as_data_frame <- function(ms_obj,
                                 obj_col = "ms_plan",
                                 recursive = FALSE,
                                 keep_list_cols = NULL,
                                 .name_repair = "universal_quiet",
                                 .error_call = caller_env()) {
  if (has_name(as.list(ms_obj), "properties")) {
    properties <- ms_obj$properties
  } else {
    properties <- ms_obj
  }

  sizes <- vctrs::list_sizes(properties)
  len1_props <- properties[sizes == 1]
  list_props <- properties[sizes != 1]

  df <- vctrs::vec_rbind(
    c(
      unlist(len1_props, recursive = recursive, use.names = FALSE),
      list_props
    ),
    .name_repair = .name_repair,
    .error_call = .error_call
  )

  df <- set_names(df, nm = names(c(len1_props, list_props)))

  # Keep any supplied columns that need to stay as list columns
  # FIXME: This is only need for the "createdBy" and "lastModifiedBy" columns
  # from
  if (!is.null(keep_list_cols)) {
    len1_props <- len1_props[!(names(len1_props) %in% keep_list_cols)]
  }

  # Unlist select columns to create vector, not list columns
  # FIXME: Must be a better way to do this
  for (nm in names(len1_props)) {
    df[[nm]] <- unlist(df[[nm]])
  }

  df[[obj_col]] <- list(ms_obj)

  df
}

#' Check if x or y is not `NULL` and is a string and error if neither or both
#' are supplied or if the supplied argument is not a string
#'
#' @noRd
check_exclusive_strings <- function(x = NULL,
                                    y = NULL,
                                    x_arg = caller_arg(x),
                                    y_arg = caller_arg(y),
                                    allow_empty = FALSE,
                                    require = TRUE,
                                    call = caller_env()) {
  check_exclusive_args(
    x = x, y = y,
    x_arg = x_arg, y_arg = y_arg,
    require = require, call = call
  )

  check_string(x, allow_empty = allow_empty, allow_null = TRUE, call = call)
  check_string(y, allow_empty = allow_empty, allow_null = TRUE, call = call)
}


#' Check if x or y is not `NULL` and error if neither or both are supplied
#'
#' @noRd
check_exclusive_args <- function(x = NULL,
                                 y = NULL,
                                 x_arg = caller_arg(x),
                                 y_arg = caller_arg(y),
                                 require = TRUE,
                                 call = caller_env()) {
  if (is_empty(c(x, y))) {
    if (!require) {
      return(invisible(NULL))
    }

    cli_abort(
      "One of {.arg {x_arg}} or {.arg {y_arg}} must be supplied.",
      call = call
    )
  }

  if (has_length(c(x, y), 2)) {
    cli_abort(
      "Exactly one of {.arg {x_arg}} or {.arg {y_arg}} must be supplied.",
      call = call
    )
  }

  invisible(NULL)
}
