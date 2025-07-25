# Get a column definition
#
# <https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http>
# get_column_definition <- function(...) {
# }

#' Create a column definition for use with the create column method for
#' SharePoint lists
#'
#' @description
#' [create_column_definition()] builds a named list with the properties of the
#' columnDefinition resource type.
#'
#' More information:
#' <https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>
#'
#' @param name Column name.
#' @param display_as Value displayed as option. For `create_choice_column` one
#' of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
#' `create_number_column`, one of `c("number", "percentage")`. For
#' `create_datetime_column`, one of `c("default", "friendly", "standard")`.
#' @param ... Additional arguments passed to [create_column_definition()] or
#' appended to the end of the column definition list.
#' @param .col_type Column type. Defaults to "text". Must be one of "boolean",
#' "calculated", "choice", "currency", "dateTime", "lookup", "number",
#' "personOrGroup", "text", "term", "hyperlinkOrPicture", "thumbnail",
#' "contentApprovalStatus", or "geolocation".
#' @param enforce_unique Enforce unique values in column.
#' @param hidden If `TRUE`, column will be hidden by default.
#' @param deletable If `TRUE`, column can't be deleted separate from the list.
#' @param required If `TRUE`, column will be required.
#' @param default Default value set by helper [get_column_default()] function.
#' @param description Column description.
#' @param displayname Column display name.
#' @keywords lists
#'
#' @details Display as options
#'
#' Display as options vary by columnDefinition type:
#'
#' - Options for personOrGroupColumn: https://learn.microsoft.com/en-us/graph/api/resources/personorgroupcolumn?view=graph-rest-1.0#displayas-options
#'
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

  col_definition <- purrr::compact(col_definition)

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
        "contentApprovalStatus",
        "geolocation"
      )
    )

    params <- purrr::compact(list2(...))

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
#' @param multiple_lines Logical. If `TRUE`, allow multiple lines of text.
#' @param append_changes Logical. If `TRUE`, append changes to existing value
#' for column.
#' @param lines Whole number.
#' @param max_length Whole number. Max length in number of characters.
#' @param text_type One of `c("plain", "richText")`
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
#' @param choices A character vector of choice options.
#' @param allow_na If `TRUE`, allow NA values in `choices`.
#' @param na_replacement Used as `replacement` by [stringr::str_replace_na()] on
#'  `choices` if they contain NA values.
#' @param allow_text If `TRUE`, allow text entry in the choice column.
#' @inheritParams base::strsplit
#' @export
create_choice_column <- function(
  name,
  choices,
  ...,
  allow_text = TRUE,
  display_as = c(
    "dropDownMenu",
    "checkBoxes",
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
  # TODO: Check if this works w/ factors
  check_character(choices, allow_na = allow_na)
  choices <- stringr::str_replace_na(choices, replacement = na_replacement)

  # Split `choices` string if `split` is supplied
  if (!is.null(split) && is_string(choices)) {
    choices <- strsplit(choices, split = split, fixed = TRUE)[[1]]
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
#' @param decimals One of `c("none", "one", "two", "three", "four", "five")` or
#' a numeric value between 0 and 5.
#' @param max,min Minimum and maximum values allowed in number column.
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
#' @param locale Locale
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
#' See [examples of common formulas in
#' lists](https://support.microsoft.com/en-us/office/examples-of-common-formulas-in-lists-d81f5f21-2b4e-45ce-b170-bf7ebf6988b3).
#' @param format `"dateOnly"` or `"dateTime"`. Required by
#' `create_calculated_column` if `output_type` is "dateTime" otherwise ignored.
#' @param output_type Value type returned by calculated formula. One of
#' `c("text", "boolean", "currency", "dateTime", "number")`
#' @export
create_calculated_column <- function(
  name,
  ...,
  formula,
  format = c("dateOnly", "dateTime"),
  output_type = c("text", "boolean", "currency", "dateTime", "number")
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
    formula = trimws(formula),
    outputType = output_type,
    .col_type = "calculated"
  )
}

#' @rdname create_column_definition
#' @param lookup_list_column Name of lookup column in the lookup list to use.
#' @param lookup_list_id,lookup_list Lookup list ID string or "ms_list" class
#' object with id value in list properties.
#' @param allow_multiple If `TRUE`, allow lookup column to return multiple
#' values.
#' @param allow_unlimited_length If `TRUE`, allow lookup column to
#' return any length value.
#' @param primary_lookup_column_id If column definition is for a secondary
#' column, the primary lookup column ID must be supplied.
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

#' @rdname create_column_definition
#' @param from_type What type of resources to choose from. Defaults to
#' "peopleOnly" for [create_person_column()] or "peopleAndGroups" for
#' [create_group_column()]
#' @export
create_person_column <- function(
  name,
  ...,
  allow_multiple = NULL,
  display_as = NULL,
  from_type = "peopleOnly"
) {
  check_string(display_as, allow_null = TRUE, allow_empty = FALSE)
  check_bool(allow_multiple, allow_null = TRUE)
  from_type <- arg_match0(from_type, c("peopleOnly", "peopleAndGroups"))

  create_column_definition(
    name = name,
    ...,
    displayAs = display_as,
    allowMultipleSelection = allow_multiple,
    chooseFromType = from_type,
    .col_type = "personOrGroup"
  )
}

#' @rdname create_column_definition
#' @export
create_group_column <- function(
  name,
  ...,
  allow_multiple = NULL,
  display_as = NULL,
  from_type = "peopleAndGroups"
) {
  create_person_column(
    name = name,
    ...,
    display_as = display_as,
    allow_multiple = allow_multiple,
    from_type = from_type
  )
}


#' @rdname create_column_definition
#' @param is_picture Logical indicator for display of hyperlink value as link
#' (`FALSE`, default for [create_hyperlink_column()]) or image (`TRUE`, default
#' for [create_picture_column()]).
#' @export
create_hyperlink_column <- function(name, ..., is_picture = FALSE) {
  create_person_column(
    name = name,
    ...,
    isPicture = is_picture,
    .col_type = "hyperlinkOrPicture"
  )
}

#' @rdname create_column_definition
#' @export
create_picture_column <- function(name, ..., is_picture = TRUE) {
  create_person_column(
    name = name,
    ...,
    isPicture = is_picture,
    .col_type = "hyperlinkOrPicture"
  )
}

#' @rdname create_column_definition
#' @export
create_thumbnail_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "thumbnail"
  )
}

#' @rdname create_column_definition
#' @export
create_geolocation_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "geolocation"
  )
}


#' @rdname create_column_definition
#' @export
create_term_column <- function(
  name,
  ...,
  allow_multiple = TRUE,
  show_full_name = NULL
) {
  create_column_definition(
    name = name,
    ...,
    showFullyQualifiedName = show_full_name,
    allowMultipleValues = allow_multiple,
    .col_type = "termColumn"
  )
}

#' Create a list of column definitions
#'
#' [create_column_definition_list()] is a vectorized version of
#' [create_column_definition()] that uses a list or data frame input to create
#' a list of column definitions. This list can be used as the `fields` argument
#' for [create_sp_list()].
#'
#' @param definitions A list or data frame with arguments to use in creation of
#' column definitions.
#' @param col_type Column type to use if not provided as a "type" column in the
#' input definitions data frame. Allowed values include date and datetime,
#' person, group, and personorgroup. Not case sensitive.
#' @param ignore_na If `TRUE`, drop any parameters with a `NA` value.
#' @keywords lists
#' @export
create_column_definition_list <- function(
  definitions,
  col_type = "text",
  ignore_na = TRUE
) {
  purrr::pmap(
    definitions,
    function(name, ...) {
      check_string(name, allow_empty = FALSE)
      params <- rlang::list2(...)
      # params <- vctrs::list_drop_empty(params)

      if (!is_empty(params[["type"]]) && !is.na(params[["type"]])) {
        type <- params[["type"]]
        params[["type"]] <- NULL
      } else {
        type <- col_type
      }

      .fn <- switch(
        tolower(type),
        text = create_text_column,
        choice = create_choice_column,
        number = create_number_column,
        date = create_datetime_column,
        datetime = create_datetime_column,
        boolean = create_boolean_column,
        currency = create_currency_column,
        lookup = create_lookup_column,
        person = create_person_column,
        group = create_group_column,
        personorgroup = create_group_column,
        hyperlink = create_hyperlink_column,
        picture = create_picture_column,
        hyperlinkorpicture = create_hyperlink_column,
        thumbnail = create_thumbnail_column,
        geolocation = create_geolocation_column,
        term = create_term_column
      )

      if (ignore_na) {
        na_params <- purrr::map_lgl(params, is.na)
        params <- vctrs::vec_slice(
          params,
          i = !na_params
        )
      }

      params[["name"]] <- name
      rlang::exec(.fn, !!!params)
    }
  )
}

#' Get a column default value or formula
#'
#' [get_column_default()] returns a formula or value or NULL.
#'
#' @param formula Formula used as default value.
#' @param value Value used as default value.
#' @param allow_null If `TRUE`, return `NULL` if both `value` and `formula` are
#' `NULL`.
#' @inheritParams rlang::args_error_context
#' @keywords lists internal
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

#' Convert a data frame to a column definition list
#'
#'
#' [data_as_column_definition_list()] is used to create a column definition list
#' based on an existing data frame.
#' @param data A data frame input. Column types are used to infer the
#' appropriate Microsoft Lists column definition.
#' @param ... Ignored.
#' @inheritParams create_column_definition_list
#' @inheritParams create_choice_column
#' @examples
#' data_as_column_definition_list(mtcars)
#'
#' @keywords lists
#' @export
data_as_column_definition_list <- function(
  data,
  ...,
  split = "|",
  ignore_na = TRUE
) {
  col_types <- vapply(
    data,
    \(x) {
      switch(
        vctrs::vec_ptype_abbr(x),
        "chr" = "text",
        "fct" = "choice",
        "dbl" = "number",
        "int" = "number",
        "lgl" = "boolean",
        "date" = "date",
        "dttm" = "datetime",
        "text"
        # NA_character_
      )
    },
    character(1)
  )

  # FIXME: Replace purrr::map_dfr
  definitions_list <- purrr::map(
    seq_along(col_types),
    \(x) {
      def <- list(
        name = names(data)[[x]],
        type = col_types[[x]]
      )

      # TODO: Add check for length for text columns

      if (def[["type"]] == "choice") {
        # type is only "choices" if column value is factor
        # TODO: Explore passing choices as a list column
        # FIXME: Add warning if `split` in levels/choices
        def[["choices"]] <- paste0(levels(data[[x]]), collapse = split)
        def[["split"]] <- split
      }

      if ((def[["type"]] == "number") && is.integer(data[1, x])) {
        def[["decimals"]] <- "none"
      }

      as.data.frame(def)
    }
  )

  definitions <- vctrs::vec_rbind(!!!definitions_list)

  create_column_definition_list(
    definitions,
    ignore_na = ignore_na
  )
}
