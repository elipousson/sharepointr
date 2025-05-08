# Get a column definition
#
# <https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http>
# get_column_definition <- function(...) {
# }

#' Create a column definition for use with the create column method for SharePoint lists
#'
#' [create_column_definition()] builds a named list with the properties of the
#' columnDefinition resource type.
#'
#' <https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>
#'
#' @keywords internal
#' @export
create_column_definition <- function(
  name,
  ...,
  .col_type = "text",
  enforce_unique = NULL,
  hidden = FALSE,
  deletable = NULL,
  indexed = NULL,
  sealed = NULL,
  propagate_changes = NULL,
  read_only = NULL,
  required = NULL,
  validation = NULL,
  default = get_column_default(),
  description = NULL,
  displayname = NULL,
  id = NULL
) {
  # Validate columnDefinition properties
  check_bool(enforce_unique, allow_null = TRUE)
  check_bool(hidden, allow_null = TRUE)
  check_bool(deletable, allow_null = TRUE)
  check_bool(indexed, allow_null = TRUE)
  check_bool(sealed, allow_null = TRUE)
  check_bool(propagate_changes, allow_null = TRUE)
  check_bool(read_only, allow_null = TRUE)
  check_bool(required, allow_null = TRUE)
  check_string(displayname, allow_null = TRUE)
  check_name(name)

  col_definition <- list(
    name = name,
    enforceUniqueValues = enforce_unique,
    hidden = hidden,
    isDeletable = deletable,
    indexed = indexed,
    isSealed = sealed,
    propagateChanges = propagate_changes,
    readOnly = read_only,
    required = required,
    validation = validation,
    defaultValue = default,
    description = description,
    displayName = displayname,
    id = id
  )

  col_definition <- compact(col_definition)

  if (!is.null(.col_type)) {
    # The type-related properties are mutually exclusive;
    # a column can only have one of them specified.
    .col_type <- arg_match0(
      .col_type,
      values = c(
        "boolean",
        "calculated",
        "choice",
        "currency",
        "dateTime",
        "lookup",
        "number",
        "personOrGroup",
        "text",
        "term",
        "hyperlinkOrPicture",
        "thumbnail",
        "contentApprovalStatus"
      )
    )

    params <- compact(list2(...))

    if (is_empty(params)) {
      params <- structure(list(), names = character(0))
    }

    params <- list(params)

    col_definition <- c(
      col_definition,
      set_names(params, .col_type)
    )
  }

  col_definition
}

#' @rdname create_column_definition
#' @keywords internal
#' @export
create_text_column <- function(
  name,
  ...,
  multiple_lines = NULL,
  append_changes = NULL,
  lines = NULL,
  max_length = NULL,
  text_type = c("plain", "richText")
) {
  # Validate TextColumn resource properties
  # <https://learn.microsoft.com/en-us/graph/api/resources/textcolumn?view=graph-rest-1.0>
  check_bool(multiple_lines, allow_null = TRUE)
  check_bool(append_changes, allow_null = TRUE)
  check_number_whole(lines, allow_null = TRUE)
  check_number_whole(max_length, allow_null = TRUE)
  text_type <- arg_match(text_type)

  create_column_definition(
    name = name,
    ...,
    .col_type = "text",
    allowMultipleLines = multiple_lines,
    appendChangesToExistingText = append_changes,
    linesForEditing = lines,
    maxLength = max_length,
    textType = text_type
  )
}

#' @rdname create_column_definition
#' @keywords internal
#' @export
create_choice_column <- function(
  name,
  choices,
  ...,
  allow_text = TRUE,
  display_as = c(
    "checkBoxes",
    "dropDownMenu",
    "radioButtons"
  ),
  allow_na = TRUE,
  na_replacement = "NA",
  split = NULL
) {
  # Optionally validate `display_as`
  if (!is.null(display_as)) {
    display_as <- arg_match(display_as)
  }

  check_bool(allow_text, allow_null = TRUE)

  # Validate and process choices
  check_character(choices, allow_na = allow_na)
  choices <- stringr::str_replace_na(choices, replacement = na_replacement)

  # Split `choices` string if `split` is supplied
  if (!is.null(split)) {
    choices <- strsplit(choices, split = split)
  }

  create_column_definition(
    name = name,
    ...,
    .col_type = "choice",
    allowTextEntry = allow_text,
    choices = choices,
    displayAs = display_as
  )
}

#' @rdname create_column_definition
#' @keywords internal
#' @export
create_number_column <- function(
  name,
  ...,
  decimals = "automatic",
  display_as = NULL,
  max = NULL,
  min = NULL
) {
  # Convert numeric decimalPlaces values
  if (is.numeric(decimals)) {
    check_number_whole(
      decimals,
      min = 0,
      max = 5
    )

    decimal_num <- c("none", "one", "two", "three", "four", "five")
    decimals <- decimal_num[as.integer(decimals) + 1]
  }

  # Validate decimalPlaces value
  arg_match0(
    decimals,
    c("automatic", "none", "one", "two", "three", "four", "five")
  )

  # Validate displayAs value
  if (!is.null(display_as)) {
    display_as <- arg_match0(
      display_as,
      c("number", "percentage")
    )
  }

  check_number_whole(max, allow_null = TRUE)
  check_number_whole(min, allow_null = TRUE)

  create_column_definition(
    name = name,
    ...,
    .col_type = "number",
    decimalPlaces = decimals,
    displayAs = display_as,
    maximum = max,
    minimum = min
  )
}

#' @rdname create_column_definition
#' @keywords internal
#' @export
create_datetime_column <- function(
  name,
  ...,
  display_as = c(
    "default",
    "friendly",
    "standard"
  ),
  format = c(
    "dateOnly",
    "dateTime"
  )
) {
  # Validate datetime column properties
  display_as <- arg_match(display_as)
  format <- arg_match(format)

  create_column_definition(
    name = name,
    ...,
    .col_type = "dateTime",
    format = format,
    displayAs = display_as
  )
}

#' @rdname create_column_definition
#' @export
create_boolean_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "boolean"
  )
}

#' @rdname create_column_definition
#' @export
create_currency_column <- function(name, ..., locale = "en-us") {
  check_string(locale)
  create_column_definition(
    name = name,
    ...,
    locale = locale,
    .col_type = "currency"
  )
}

#' @rdname create_column_definition
#' @param formula Required string with formula for calculated column definition.
#' @param format "dateOnly" or "dateTime". Required if `output_type` is "dateTime" otherwise ignored.
#' @param output_type Value type returned by calculated formula.
#' @export
create_calculated_column <- function(
  name,
  ...,
  formula,
  format = c("dateOnly", "dateTime"),
  output_type = c("boolean", "currency", "dateTime", "number", "text")
) {
  check_string(formula)
  output_type <- arg_match(output_type)
  if (output_type == "dateTime") {
    format <- arg_match0(
      format,
      c("dateOnly", "dateTime")
    )
  } else {
    format <- NULL
  }

  create_column_definition(
    name = name,
    ...,
    format = format,
    formula = formula,
    outputType = output_type,
    .col_type = "calculated"
  )
}

#' @rdname create_column_definition
#' @param lookup_list_column Name of lookup column in the lookup list to use.
#' @param lookup_list_id,lookup_list Lookup list ID string or "ms_list" class object with id value in list properties.
#' @param allow_multiple If `TRUE`, allow lookup column to return multiple values.
#' @param allow_unlimited_length If `TRUE`, allow lookup column to return any length value.
#' @param primary_lookup_column_id If column definnition is for a secondary column, the primary lookup column ID must be supplied.
#' @export
create_lookup_column <- function(
  name,
  lookup_list_column,
  ...,
  lookup_list_id = NULL,
  lookup_list = NULL,
  allow_multiple = NULL,
  allow_unlimited_length = NULL,
  primary_lookup_column_id = NULL
) {
  check_string(lookup_list_column, allow_empty = FALSE)
  check_bool(allow_multiple, allow_null = TRUE)
  check_bool(allow_unlimited_length, allow_null = TRUE)
  check_name(primary_lookup_column_id, allow_null = TRUE)

  if (is.null(lookup_list_id) && !is.null(lookup_list)) {
    check_ms_obj(lookup_list, "ms_list")
    lookup_list_id <- lookup_list[["properties"]][["id"]]
  }

  check_string(lookup_list_id, allow_empty = FALSE)

  create_column_definition(
    name = name,
    ...,
    allowMultipleValues = allow_multiple,
    allowUnlimitedLength = allow_unlimited_length,
    listId = lookup_list_id,
    columnName = lookup_list_column,
    primaryLookupColumnId = primary_lookup_column_id,
    .col_type = "lookup"
  )
}

#' Vectorized version of `create_column_definition()`
#' @keywords internal
#' @export
create_column_definition_list <- function(
  name,
  .col_type = "text",
  ...
) {
  pmap(
    vctrs::vec_recycle_common(
      name = name,
      .col_type = .col_type,
      .size = length(name)
    ),
    \(name, .col_type) {
      .f <- switch(
        .col_type,
        text = create_text_column,
        number = create_number_column,
        datetime = create_datetime_column,
        boolean = create_boolean_column,
        currency = create_currency_column
      )

      .f(name)
    }
  )
}

#' Get a column default value or formula
#'
#' [get_column_default()] returns a formula or value or NULL.
#'
#' @param formula Formula used as default value.
#' @param value Value used as default value.
#' @param allow_null If `TRUE`, return `NULL` if both `value` and `formula` are `NULL`.
#' @keywords internal
#' @export
get_column_default <- function(
  value = NULL,
  formula = NULL,
  allow_null = TRUE,
  call = caller_env()
) {
  if (allow_null && is.null(formula) && is.null(value)) {
    return(invisible(NULL))
  }

  check_exclusive_strings(formula, value, call = call)

  if (!is.null(value)) {
    return(list(value = value))
  }

  list(formula = formula)
}
