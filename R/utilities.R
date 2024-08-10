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

#' Check if a URL is valid
#'
#' @noRd
check_url <- function(x,
                      allow_null = FALSE,
                      arg = caller_arg(x),
                      call = caller_env()) {
  check_string(x, allow_empty = FALSE, allow_null = allow_null, arg = arg, call = call)

  if (allow_null && is_null(x)) {
    return(invisible(NULL))
  }

  if (is_url(x)) {
    return(invisible(NULL))
  }

  stop_input_type(
    x,
    what = "a valid url",
    arg = arg,
    call = call
  )
}

#' Check if x matches the pattern of a SharePoint List URL
#'
#' @noRd
check_sp_list_url <- function(x,
                              ...,
                              allow_null = FALSE,
                              allow_personal = FALSE,
                              arg = caller_arg(x),
                              call = caller_env()) {
  if (allow_null && is.null(x)) {
    return(invisible(NULL))
  }

  check_url(x, arg = arg, call = call)

  if (!allow_personal && stringr::str_detect(x, "/personal/")) {
    cli_abort(
      "{.arg {arg}} can't be a personal SharePoint list URL.",
      ...,
      call = call
    )
  }

  if (stringr::str_detect(x, ":l:|/Lists/")) {
    return(invisible(NULL))
  }

  cli_abort(
    "{.arg {arg}} must be a URL with {.val :l:} or {.val /Lists/}
    to be a valid SharePoint list URL.",
    ...,
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
  map(x, function(i) {
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
  map(x, function(i) {
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
                                      unlist_cols = TRUE,
                                      .name_repair = "universal_quiet",
                                      .error_call = caller_env()) {
  ms_obj_list <- map(
    ms_obj_list,
    function(obj) {
      ms_obj_as_data_frame(
        obj,
        obj_col = obj_col,
        keep_list_cols = keep_list_cols,
        unlist_cols = unlist_cols,
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
#' @param obj_col Column name for list column with `ms_` objects. Defaults to
#'   `"ms_plan"`.
#' @param keep_list_cols Column names for those columns to maintain in a list
#'   format instead of attempting to convert to a character vector.
#' @keywords internal
#' @importFrom vctrs list_sizes
ms_obj_as_data_frame <- function(ms_obj,
                                 obj_col = "ms_plan",
                                 recursive = FALSE,
                                 keep_list_cols = NULL,
                                 unlist_cols = TRUE,
                                 .name_repair = "universal_quiet",
                                 .error_call = caller_env()) {
  if (has_name(as.list(ms_obj), "properties")) {
    properties <- ms_obj$properties
  } else {
    properties <- ms_obj
  }

  sizes <- vctrs::list_sizes(properties)
  len1_props <- properties[sizes == 1]
  list_props <- properties[sizes > 1]
  len0_props <- properties[sizes == 0]

  df <- vctrs::vec_rbind(
    c(
      unlist(len1_props, recursive = recursive, use.names = FALSE),
      len0_props,
      list_props
    ),
    .name_repair = .name_repair,
    .error_call = .error_call
  )

  df <- set_names(df, nm = names(c(len1_props, len0_props, list_props)))

  # Keep any supplied columns that need to stay as list columns
  # FIXME: This is only need for the "createdBy" and "lastModifiedBy" columns
  # from
  if (!is.null(keep_list_cols)) {
    len1_props <- len1_props[!(names(len1_props) %in% keep_list_cols)]
  }

  # Unlist select columns to create vector, not list columns
  # FIXME: Must be a better way to do this
  if (unlist_cols) {
    for (nm in names(len1_props)) {
      prop_col <- unlist(df[[nm]])
      # FIXME: This fixed an issue for turning member lists into data frames but
      # may create new issues
      if (has_length(prop_col, 1)) {
        df[[nm]] <- prop_col
      }
    }
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

#' Repair column names using `vctrs::vec_as_names` and `rlang::set_names`
#' @noRd
.set_as_names <- function(
    data,
    nm = NULL,
    repair = "unique",
    repair_arg = caller_arg(repair),
    call = caller_env()) {
  nm <- nm %||% names(data)

  if (!is.null(repair)) {
    nm <- vctrs::vec_as_names(
      names = nm,
      repair = repair,
      repair_arg = repair_arg,
      call = call
    )
  }

  set_names(data, nm = nm)
}


#' Apply a label attribute value to each column of a data frame
#' @noRd
label_cols <- function(
    data,
    values) {
  nm <- intersect(names(values), colnames(data))

  for (v in nm) {
    label_attr(data[[v]]) <- values[[v]]
  }

  data
}

#' Set label attribute
#' @seealso [labelled::set_label_attribute()]
#' @source <https://github.com/cran/labelled/blob/master/R/var_label.R>
#' @noRd
`label_attr<-` <- function(x, value) {
  attr(x, "label") <- value
  x
}
