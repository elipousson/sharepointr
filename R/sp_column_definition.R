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

  col_definition <- vctrs::list_drop_empty(col_definition)

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

    params <- vctrs::list_drop_empty(
      list2(...)
    )

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
  )
) {
  display_as <- arg_match(display_as)
  check_bool(allow_text, allow_null = TRUE)

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
    .col_type = "number",
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
#' @export
create_calculated_column <- function(
  name,
  ...,
  formula,
  format = NULL,
  output_type = c("boolean", "currency", "dateTime", "number", "text")
) {
  check_string(formula)
  output_type <- arg_match(output_type)
  if (output_type == "dateTime") {
    format <- arg_match0(
      format,
      c("dateOnly", "dateTime")
    )
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
#' [get_column_default()] returns a formula or value or NULL
#' @keywords internal
#' @export
get_column_default <- function(
  value = NULL,
  formula = NULL,
  allow_null = TRUE
) {
  if (allow_null && is.null(formula) && is.null(value)) {
    return(invisible(NULL))
  }

  check_exclusive_strings(formula, value)

  if (!is.null(value)) {
    return(list(value = value))
  }

  list(formula = formula)
}
