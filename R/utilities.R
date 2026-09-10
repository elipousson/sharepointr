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
#' @returns A logical vector the same length as `x`, or `FALSE` if `x` is not
#'   a vector or is empty.
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
#' @returns Invisibly returns `NULL` if `x` is a valid URL (or `NULL` and
#'   `allow_null = TRUE`). Otherwise, errors.
#' @noRd
check_url <- function(
  x,
  allow_null = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
  check_string(
    x,
    allow_empty = FALSE,
    allow_null = allow_null,
    arg = arg,
    call = call
  )

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
#' @returns Invisibly returns `NULL` if `x` is a valid SharePoint list URL
#'   (or `NULL` and `allow_null = TRUE`). Otherwise, errors.
#' @noRd
check_sp_list_url <- function(
  x,
  ...,
  allow_null = FALSE,
  allow_personal = FALSE,
  arg = caller_arg(x),
  call = caller_env()
) {
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
#' @returns A logical vector the same length as `x`.
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

#' @returns A character vector the same length as `string`, with leading
#'   and/or trailing `"/"` removed.
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

#' @returns A character vector with the elements of `...` concatenated using
#'   `sep`.
#' @noRd
str_c_url <- function(..., sep = "/") {
  stringr::str_c(..., sep = sep)
}

#' @returns A character vector with the elements of `...` concatenated using
#'   `fsep`.
#' @noRd
str_c_fsep <- function(..., fsep = .Platform$file.sep) {
  stringr::str_c(..., sep = fsep)
}

#' Variant of [stringr::str_match()] that returns a list where any `NA` values
#' are replaced with `NULL`
#'
#' @returns A named (if `nm` is supplied) or unnamed list of matched groups,
#'   with `NA` values replaced by `NULL`.
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
#' @returns A list the same length as `x`, with any `NA` elements replaced by
#'   `replace`.
#' @noRd
list_replace_na <- function(x, replace = NULL) {
  purrr::map(x, function(i) {
    if (is.na(i)) {
      return(replace)
    }
    i
  })
}

#' Replace empty elements in a list
#'
#' @returns A list the same length as `x`, with any empty elements replaced
#'   by `replace`.
#' @noRd
list_replace_empty <- function(x, replace = NULL) {
  purrr::map(x, function(i) {
    if (is_empty(i)) {
      return(replace)
    }
    i
  })
}

#' Convert a list of ms_obj elements to a data frame of properties with a list
#' column of objects
#'
#' @returns A data frame with one row per element of `ms_obj_list`, combining
#'   the columns produced by [ms_obj_as_data_frame()] for each element.
#' @noRd
#' @importFrom vctrs vec_rbind
ms_obj_list_as_data_frame <- function(
  ms_obj_list,
  obj_col = "ms_plan",
  keep_list_cols = NULL,
  unlist_cols = TRUE,
  .name_repair = "universal_quiet",
  .error_call = caller_env()
) {
  ms_obj_list <- purrr::map(
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
#' @param ms_obj A object with a 'ms_object" class.
#' @param obj_col Column name for list column with `ms_` objects. Defaults to
#'   `"ms_plan"`.
#' @param keep_list_cols Column names for those columns to maintain in a list
#'   format instead of attempting to convert to a character vector.
#' @param unlist_cols If `TRUE` (default), convert list columns to vectors.
#' @inheritParams vctrs::vec_rbind
#' @returns A 1 row data frame with one column per scalar property of
#'   `ms_obj`, plus a list column named `obj_col` containing `ms_obj` itself.
#' @keywords internal
#' @importFrom vctrs list_sizes
ms_obj_as_data_frame <- function(
  ms_obj,
  obj_col = "ms_plan",
  keep_list_cols = NULL,
  unlist_cols = TRUE,
  .name_repair = "universal_quiet",
  .error_call = caller_env()
) {
  if (has_name(as.list(ms_obj), "properties")) {
    properties <- ms_obj$properties
  } else {
    properties <- ms_obj
  }

  sizes <- vctrs::list_sizes(properties)
  len1_props <- properties[sizes == 1]
  list_props <- properties[sizes > 1]
  # Properties with size 0 (missing or NULL) are dropped instead of kept as
  # a placeholder column. This lets vctrs::vec_rbind() infer the correct
  # type for that property (atomic NA or list(NULL)) from the other objects
  # being combined in ms_obj_list_as_data_frame(), instead of forcing a
  # type here that may not match how the property appears elsewhere (e.g. a
  # scalar column here vs. a multi-value list column for another object)

  # Combine as a plain list (instead of unlisting len1_props first) so each
  # property keeps its own type instead of being coerced to a type shared
  # with sibling properties in the same object (e.g. a single-item list
  # property like "assignments" previously caused unlist() to leave
  # scalar properties like "isArchived" un-coerced for that object only,
  # producing inconsistent column types across objects when combined by
  # ms_obj_list_as_data_frame())
  df <- vctrs::vec_rbind(
    c(len1_props, list_props),
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
#' @returns Invisibly returns `NULL` if exactly one of `x`/`y` is a valid
#'   string (or neither, if `require = FALSE`). Otherwise, errors.
#' @noRd
check_exclusive_strings <- function(
  x = NULL,
  y = NULL,
  x_arg = caller_arg(x),
  y_arg = caller_arg(y),
  allow_empty = FALSE,
  require = TRUE,
  message = NULL,
  call = caller_env()
) {
  check_exclusive_args(
    x = x,
    y = y,
    x_arg = x_arg,
    y_arg = y_arg,
    require = require,
    message = message,
    call = call
  )

  check_string(
    x,
    allow_empty = allow_empty,
    allow_null = TRUE,
    call = call
  )
  check_string(
    y,
    allow_empty = allow_empty,
    allow_null = TRUE,
    call = call
  )
}


#' Check if x or y is not `NULL` and error if neither or both are supplied
#'
#' @returns Invisibly returns `NULL` if exactly one of `x`/`y` is supplied
#'   (or neither, if `require = FALSE`). Otherwise, errors.
#' @noRd
check_exclusive_args <- function(
  x = NULL,
  y = NULL,
  x_arg = caller_arg(x),
  y_arg = caller_arg(y),
  require = TRUE,
  message = NULL,
  call = caller_env()
) {
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
      message %||%
        "Exactly one of {.arg {x_arg}} or {.arg {y_arg}} must be supplied.",
      call = call
    )
  }

  invisible(NULL)
}

#' Repair column names using `vctrs::vec_as_names` and `rlang::set_names`
#' @returns `data` with names set to (optionally repaired) `nm`.
#' @noRd
.set_as_names <- function(
  data,
  nm = NULL,
  repair = "unique",
  repair_arg = caller_arg(repair),
  call = caller_env()
) {
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
#' @returns `data` with a `"label"` attribute set on each matched column.
#' @noRd
label_cols <- function(
  data,
  values
) {
  nm <- intersect(names(values), colnames(data))

  for (v in nm) {
    label_attr(data[[v]]) <- values[[v]]
  }

  data
}

#' Set label attribute
#' @seealso [labelled::set_label_attribute()]
#' @source <https://github.com/cran/labelled/blob/master/R/var_label.R>
#' @returns `x` with a `"label"` attribute set to `value`.
#' @noRd
`label_attr<-` <- function(x, value) {
  attr(x, "label") <- value
  x
}

utils::globalVariables(
  c(
    ".fields",
    ".sp_list",
    "fn",
    "item_id",
    "x"
  )
)

# https://github.com/elipousson/cliExtras/blob/main/R/cli_yesno.R
#' @returns Invisibly returns `NULL` if the user responds with a value in
#'   `yes`. Otherwise, errors.
#' @noRd
check_yes <- function(
  prompt = NULL,
  yes = c("", "Y", "Yes", "Yup", "Yep", "Yeah"),
  message = "Aborted. A yes is required.",
  .envir = caller_env(),
  call = .envir
) {
  resp <- cli_ask(paste0("?\u00a0", prompt, "\u00a0(Y/n)"), .envir = .envir)

  if (all(tolower(resp) %in% tolower(yes))) {
    return(invisible(NULL))
  }

  cli_abort(
    message = message,
    .envir = .envir,
    call = call
  )
}

# https://github.com/elipousson/cliExtras/blob/main/R/cli_ask.R
#' @returns A string with the user's response from [readline()]. Errors if
#'   the session is not interactive.
#' @noRd
cli_ask <- function(
  prompt = "?",
  ...,
  .envir = rlang::caller_env(),
  call = .envir
) {
  check_interactive(call = call)
  if (!rlang::is_empty(rlang::list2(...))) {
    cli::cli_bullets(..., .envir = .envir)
  }
  readline(paste0(prompt, "\u00a0"))
}

# https://github.com/elipousson/cliExtras/blob/main/R/utils-check.R
#' @returns Invisibly returns `NULL` if the session is interactive.
#'   Otherwise, errors.
#' @noRd
check_interactive <- function(
  ...,
  message = "User input is required but this session is not interactive.",
  .envir = parent.frame(),
  call = caller_env()
) {
  if (is_interactive()) {
    return(invisible(NULL))
  }

  cli_abort(
    message = message,
    ...,
    .envir = .envir,
    call = call
  )
}
