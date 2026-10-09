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
#' columnDefinition resource type. The `create_*_column()` helpers create a
#' definition for a single column type.
#'
#' Arguments that set a columnDefinition property note the matching Graph
#' property name. Graph property names can also be passed to `...` (e.g.
#' `create_text_column("Notes", allowMultipleLines = TRUE)` or
#' `create_column_definition("Notes", displayName = "Project Notes")`).
#' Column-level properties are added to the definition and any other values
#' are added to the properties for the column type. Supplying the same
#' property with both an argument and a Graph name is an error. Definitions
#' are checked with the same rules as [as_column_definition()].
#'
#' Properties left as `NULL` aren't included in the definition so SharePoint
#' uses the default value when a column is created.
#'
#' More information:
#' <https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>
#'
#' @param name Column name. Graph property: `name`. The name can't be changed
#'   after a column is created.
#' @param display_as Value displayed as option. For `create_choice_column` one
#' of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
#' `create_number_column`, one of `c("number", "percentage")`. For
#' `create_datetime_column`, one of `c("default", "friendly", "standard")`.
#' Graph property: `displayAs`.
#' @param ... Additional arguments passed to [create_column_definition()] or
#' columnDefinition properties using Graph property names.
#' @param .col_type Column type. Defaults to "text". Must be one of "boolean",
#' "calculated", "choice", "currency", "dateTime", "lookup", "number",
#' "personOrGroup", "text", "term", "hyperlinkOrPicture", "thumbnail",
#' "contentApprovalStatus", or "geolocation".
#' @param enforce_unique Enforce unique values in column. Graph property:
#'   `enforceUniqueValues`.
#' @param hidden If `TRUE`, column will be hidden by default. Graph property:
#'   `hidden`.
#' @param deletable If `TRUE`, column can't be deleted separate from the list.
#'   Graph property: `isDeletable`.
#' @param required If `TRUE`, column will be required. Graph property:
#'   `required`.
#' @param default Default value set by helper [get_column_default()] function.
#'   Graph property: `defaultValue`.
#' @param description Column description. Graph property: `description`.
#' @param display_name Column display name. Graph property: `displayName`.
#' @param displayname `r lifecycle::badge("deprecated")` Use `display_name`.
#' @param validation Column validation created with [column_validation()].
#'   Graph property: `validation`.
#' @param call The execution environment used in error messages. The
#'   `create_*_column()` helpers pass their own environment.
#' @param indexed,sealed,propagate_changes,read_only,id Additional arguments
#'   used by [create_column_definition()]. Graph properties: `indexed`,
#'   `isSealed`, `propagateChanges`, `readOnly`, and `id`.
#' @keywords lists
#'
#' @details Display as options
#'
#' Display as options vary by columnDefinition type. See documentation for more
#' details:
#'
#' - personOrGroupColumn: <https://learn.microsoft.com/en-us/graph/api/resources/personorgroupcolumn?view=graph-rest-1.0#displayas-options>
#' - choiceColumn: <https://learn.microsoft.com/en-us/graph/api/resources/choicecolumn?view=graph-rest-1.0#properties>
#' - numberColumn: <https://learn.microsoft.com/en-us/graph/api/resources/numbercolumn?view=graph-rest-1.0#properties>
#' - dateTimeColumn: <https://learn.microsoft.com/en-us/graph/api/resources/datetimecolumn?view=graph-rest-1.0>
#'
#' @details Column types the Graph API can't create
#'
#' As of October 2026, the Graph API returns an "Invalid request" error when
#' creating a list column with the hyperlinkOrPicture, thumbnail, geolocation,
#' or term column types. [create_hyperlink_column()],
#' [create_picture_column()], [create_thumbnail_column()],
#' [create_geolocation_column()], and [create_term_column()] still create
#' valid definitions, but [create_sp_list_column()] can't use them. The Graph
#' API also doesn't return the column type for hyperlinkOrPicture, thumbnail,
#' or term columns when reading list columns.
#'
#' Term columns also need a term set, which isn't supported.
#'
#' @returns A named list of columnDefinition properties formatted for use as
#'   the `columns` argument to [create_sp_list()] or as an element of the list
#'   returned by [create_column_definition_list()].
#' @export
create_column_definition <- function(
  name,
  ...,
  .col_type = "text",
  enforce_unique = NULL,
  hidden = NULL,
  deletable = NULL,
  indexed = NULL,
  sealed = NULL,
  propagate_changes = NULL,
  read_only = NULL,
  required = NULL,
  validation = NULL,
  default = get_column_default(),
  description = NULL,
  display_name = NULL,
  id = NULL,
  displayname = deprecated(),
  call = current_env()
) {
  if (lifecycle::is_present(displayname)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_column_definition(displayname)",
      "create_column_definition(display_name)"
    )
    display_name <- display_name %||% displayname
  }

  col_definition <- purrr::compact(
    list(
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
      displayName = display_name,
      id = id
    )
  )

  params <- purrr::compact(list2(...))

  if (length(params) > 0 && !is_named(params)) {
    cli_abort("All arguments passed to {.arg ...} must be named.", call = call)
  }

  dupes <- unique(names(params)[duplicated(names(params))])

  if (length(dupes) > 0) {
    cli_abort(
      "{.field {dupes}} can't be supplied more than once. Use an argument or
      the Graph property name, not both.",
      call = call
    )
  }

  # Graph column-level property names passed to `...`
  col_params <- params[names(params) %in% names(sp_column_props)]
  conflicts <- intersect(names(col_params), names(col_definition))

  if (length(conflicts) > 0) {
    cli_abort(
      "{.field {conflicts}} can't be supplied as both an argument and a Graph
      property name.",
      call = call
    )
  }

  col_definition <- c(col_definition, col_params)
  params <- params[!names(params) %in% names(sp_column_props)]

  if (!is.null(.col_type)) {
    # The type-related properties are mutually exclusive;
    # a column can only have one of them specified.
    .col_type <- arg_match(
      .col_type,
      values = sp_list_col_types,
      error_call = call
    )

    if (is_empty(params)) {
      params <- set_names(list(), character(0))
    }

    col_definition[[.col_type]] <- params
  } else if (length(params) > 0) {
    cli_abort(
      "{.arg .col_type} must be supplied to use {.field {names(params)}}.",
      call = call
    )
  }

  validate_column_definition(
    col_definition,
    allow_read_only = TRUE,
    allow_custom = FALSE,
    require_type = FALSE,
    call = call
  )
}

#' Is a Graph property name supplied to `...`?
#' @noRd
dots_has_name <- function(name, ...) {
  name %in% names(list2(...))
}

#' @rdname create_column_definition
#' @param multiple_lines Logical. If `TRUE`, allow multiple lines of text.
#'   Graph property: `allowMultipleLines`.
#' @param append_changes Logical. If `TRUE`, append changes to existing value
#' for column. Graph property: `appendChangesToExistingText`.
#' @param lines Whole number. Size of the text box. Graph property:
#'   `linesForEditing`.
#' @param max_length Whole number. Max length in number of characters. Graph
#'   property: `maxLength`.
#' @param text_type One of `c("plain", "richText")`. Graph property:
#'   `textType`.
#' @examples
#' create_text_column("TextColumn")
#'
#' create_text_column("NotesColumn", multiple_lines = TRUE)
#'
#' # Graph property names are also supported
#' create_text_column("NotesColumn", allowMultipleLines = TRUE)
#'
#' @export
create_text_column <- function(
  name,
  ...,
  multiple_lines = NULL,
  append_changes = NULL,
  lines = NULL,
  max_length = NULL,
  text_type = NULL
) {
  # Validate TextColumn resource properties
  # <https://learn.microsoft.com/en-us/graph/api/resources/textcolumn?view=graph-rest-1.0>
  check_bool(multiple_lines, allow_null = TRUE)
  check_bool(append_changes, allow_null = TRUE)
  check_number_whole(lines, allow_null = TRUE)
  check_number_whole(max_length, allow_null = TRUE)

  if (!is.null(text_type)) {
    text_type <- arg_match0(text_type, c("plain", "richText"))
  }

  create_column_definition(
    name = name,
    ...,
    .col_type = "text",
    allowMultipleLines = multiple_lines,
    appendChangesToExistingText = append_changes,
    linesForEditing = lines,
    maxLength = max_length,
    textType = text_type,
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @param choices A character vector of choice options. Graph property:
#'   `choices`.
#' @param allow_na If `TRUE`, allow NA values in `choices`.
#' @param na_replacement Used as `replacement` by [stringr::str_replace_na()] on
#'  `choices` if they contain NA values.
#' @param allow_text If `TRUE`, allow text entry in the choice column. Graph
#'   property: `allowTextEntry`.
#' @inheritParams base::strsplit
#' @examples
#' fruit <- c("apple", "banana", "pear", "pineapple")
#' create_choice_column("ChoiceColumn", fruit)
#'
#' @export
create_choice_column <- function(
  name,
  choices,
  ...,
  allow_text = NULL,
  display_as = NULL,
  allow_na = TRUE,
  na_replacement = "NA",
  split = NULL
) {
  # Optionally validate `display_as`
  if (!is.null(display_as)) {
    display_as <- arg_match0(
      display_as,
      c("dropDownMenu", "checkBoxes", "radioButtons")
    )
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
    displayAs = display_as,
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @param decimal_places One of `c("automatic", "none", "one", "two", "three",
#'   "four", "five")` or a whole number between 0 and 5. Graph property:
#'   `decimalPlaces`.
#' @param max,min Minimum and maximum values allowed in number column. Graph
#'   properties: `maximum` and `minimum`.
#' @param decimals `r lifecycle::badge("deprecated")` Use `decimal_places`.
#'
#' @examples
#' create_number_column("NumberColumn")
#'
#' create_number_column("PercentColumn", display_as = "percentage", max = 1)
#'
#' @export
create_number_column <- function(
  name,
  ...,
  decimal_places = NULL,
  display_as = NULL,
  max = NULL,
  min = NULL,
  decimals = deprecated()
) {
  if (lifecycle::is_present(decimals)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_number_column(decimals)",
      "create_number_column(decimal_places)"
    )
    decimal_places <- decimal_places %||% decimals
  }

  decimal_places <- as_decimal_places(decimal_places)

  # Validate displayAs value
  if (!is.null(display_as)) {
    display_as <- arg_match0(
      display_as,
      c("number", "percentage")
    )
  }

  check_number_decimal(max, allow_null = TRUE)
  check_number_decimal(min, allow_null = TRUE)

  create_column_definition(
    name = name,
    ...,
    .col_type = "number",
    decimalPlaces = decimal_places,
    displayAs = display_as,
    maximum = max,
    minimum = min,
    call = current_env()
  )
}

#' Convert numeric decimal places to a numberColumn decimalPlaces value
#' @noRd
as_decimal_places <- function(
  decimal_places,
  arg = caller_arg(decimal_places),
  call = caller_env()
) {
  if (is.null(decimal_places)) {
    return(NULL)
  }

  # Convert character values to integers
  if (is_string(decimal_places) && decimal_places %in% as.character(0:5)) {
    decimal_places <- as.integer(decimal_places)
  }

  if (is.numeric(decimal_places)) {
    check_number_whole(
      decimal_places,
      min = 0,
      max = 5,
      arg = arg,
      call = call
    )

    decimal_num <- c("none", "one", "two", "three", "four", "five")
    decimal_places <- decimal_num[as.integer(decimal_places) + 1]
  }

  arg_match0(
    decimal_places,
    sp_column_type_props[["number"]][["decimalPlaces"]],
    arg_nm = arg,
    error_call = call
  )
}

#' @rdname create_column_definition
#' @param format For `create_datetime_column()`, `"dateOnly"` or `"dateTime"`.
#'   Graph property: `format`.
#' @examples
#' create_datetime_column("DatetimeColumn")
#'
#' create_datetime_column("DateColumn", format = "dateOnly")
#'
#' @export
create_datetime_column <- function(
  name,
  ...,
  display_as = NULL,
  format = NULL
) {
  # Validate datetime column properties
  if (!is.null(display_as)) {
    display_as <- arg_match0(display_as, c("default", "friendly", "standard"))
  }

  if (!is.null(format)) {
    format <- arg_match0(format, c("dateOnly", "dateTime"))
  }

  create_column_definition(
    name = name,
    ...,
    .col_type = "dateTime",
    format = format,
    displayAs = display_as,
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @export
create_boolean_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "boolean",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @param locale Locale used to set the currency symbol, e.g. `"en-us"`.
#'   Graph property: `locale`.
#' @export
create_currency_column <- function(name, ..., locale = NULL) {
  check_string(locale, allow_null = TRUE)
  create_column_definition(
    name = name,
    ...,
    locale = locale,
    .col_type = "currency",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @param formula Required string with formula for calculated column definition.
#' See [examples of common formulas in
#' lists](https://support.microsoft.com/en-us/office/examples-of-common-formulas-in-lists-d81f5f21-2b4e-45ce-b170-bf7ebf6988b3).
#' Reference existing columns using the display name enclosed in square
#' brackets. The formula must start with an equals sign `"="` which this
#' function appends to the formula text if it is missing. The formula is
#' processed with [glue::glue()]. Graph property: `formula`.
#' @param output_type Value type returned by calculated formula. One of
#' `c("text", "boolean", "currency", "dateTime", "number")`. Defaults to
#' `"text"`. Graph property: `outputType`.
#' @export
#' @examples
#' create_calculated_column(
#'    name = "FormulaColumn",
#'    formula = "=[Text Column]"
#' )
#'
create_calculated_column <- function(
  name,
  ...,
  formula,
  format = NULL,
  output_type = NULL
) {
  if (is.null(output_type) && !dots_has_name("outputType", ...)) {
    output_type <- "text"
  }

  # Validate output_type and format
  if (!is.null(output_type)) {
    output_type <- arg_match0(
      output_type,
      sp_column_type_props[["calculated"]][["outputType"]]
    )
  }

  if (!is.null(format)) {
    format <- arg_match0(format, c("dateOnly", "dateTime"))
  }

  formula <- as.character(as_sp_formula(formula))

  create_column_definition(
    name = name,
    ...,
    format = format,
    formula = formula,
    outputType = output_type,
    .col_type = "calculated",
    call = current_env()
  )
}

#' Validate and format formula string
#' @returns A string with a leading `"="` (added if missing), processed with
#'   [glue::glue()].
#' @noRd
as_sp_formula <- function(
  formula,
  .trim = TRUE,
  call = caller_env(),
  .envir = parent.frame()
) {
  check_string(formula, call = call)

  # Check for leading `=`
  if (!stringr::str_detect(formula, "^=")) {
    formula <- paste0("=", formula)
  }

  glue::glue(formula, .trim = .trim, .envir = .envir)
}

#' @rdname create_column_definition
#' @param lookup_list_column Name of lookup column in the lookup list to use.
#'   Graph property: `columnName`.
#' @param lookup_list_id,lookup_list Lookup list ID string or "ms_list" class
#' object with id value in list properties. Graph property: `listId`.
#' @param allow_multiple_values If `TRUE`, allow a lookup or term column to
#'   store multiple values. Graph property: `allowMultipleValues`.
#' @param allow_unlimited_length If `TRUE`, allow lookup column to
#' return any length value. Graph property: `allowUnlimitedLength`.
#' @param primary_lookup_column_id If column definition is for a secondary
#' column, the primary lookup column ID must be supplied. Graph property:
#' `primaryLookupColumnId`.
#' @param allow_multiple `r lifecycle::badge("deprecated")` Use
#'   `allow_multiple_values` for [create_lookup_column()] and
#'   [create_term_column()] or `allow_multiple_selection` for
#'   [create_person_column()] and [create_group_column()].
#' @export
create_lookup_column <- function(
  name,
  lookup_list_column = NULL,
  ...,
  lookup_list_id = NULL,
  lookup_list = NULL,
  allow_multiple_values = NULL,
  allow_unlimited_length = NULL,
  primary_lookup_column_id = NULL,
  allow_multiple = deprecated()
) {
  if (lifecycle::is_present(allow_multiple)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_lookup_column(allow_multiple)",
      "create_lookup_column(allow_multiple_values)"
    )
    allow_multiple_values <- allow_multiple_values %||% allow_multiple
  }

  check_string(lookup_list_column, allow_empty = FALSE, allow_null = TRUE)
  check_bool(allow_multiple_values, allow_null = TRUE)
  check_bool(allow_unlimited_length, allow_null = TRUE)
  check_name(primary_lookup_column_id, allow_null = TRUE)

  if (is.null(lookup_list_id) && !is.null(lookup_list)) {
    check_ms_obj(lookup_list, "ms_list")
    lookup_list_id <- lookup_list[["properties"]][["id"]]
  }

  check_string(lookup_list_id, allow_empty = FALSE, allow_null = TRUE)

  create_column_definition(
    name = name,
    ...,
    allowMultipleValues = allow_multiple_values,
    allowUnlimitedLength = allow_unlimited_length,
    listId = lookup_list_id,
    columnName = lookup_list_column,
    primaryLookupColumnId = primary_lookup_column_id,
    .col_type = "lookup",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @param allow_multiple_selection If `TRUE`, allow a person or group column
#'   to store multiple values. Graph property: `allowMultipleSelection`.
#' @param from_type What type of resources to choose from. Defaults to
#' "peopleOnly" for [create_person_column()] or "peopleAndGroups" for
#' [create_group_column()]. Graph property: `chooseFromType`.
#' @export
create_person_column <- function(
  name,
  ...,
  allow_multiple_selection = NULL,
  display_as = NULL,
  from_type = "peopleOnly",
  allow_multiple = deprecated()
) {
  if (lifecycle::is_present(allow_multiple)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_person_column(allow_multiple)",
      "create_person_column(allow_multiple_selection)"
    )
    allow_multiple_selection <- allow_multiple_selection %||% allow_multiple
  }

  check_string(display_as, allow_null = TRUE, allow_empty = FALSE)
  check_bool(allow_multiple_selection, allow_null = TRUE)

  # A Graph property name supplied to `...` replaces the default
  if (dots_has_name("chooseFromType", ...)) {
    from_type <- NULL
  } else {
    from_type <- arg_match0(from_type, c("peopleOnly", "peopleAndGroups"))
  }

  create_column_definition(
    name = name,
    ...,
    displayAs = display_as,
    allowMultipleSelection = allow_multiple_selection,
    chooseFromType = from_type,
    .col_type = "personOrGroup",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @export
create_group_column <- function(
  name,
  ...,
  allow_multiple_selection = NULL,
  display_as = NULL,
  from_type = "peopleAndGroups",
  allow_multiple = deprecated()
) {
  if (lifecycle::is_present(allow_multiple)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_group_column(allow_multiple)",
      "create_group_column(allow_multiple_selection)"
    )
    allow_multiple_selection <- allow_multiple_selection %||% allow_multiple
  }

  create_person_column(
    name = name,
    ...,
    display_as = display_as,
    allow_multiple_selection = allow_multiple_selection,
    from_type = from_type
  )
}


#' @rdname create_column_definition
#' @param is_picture Logical indicator for display of hyperlink value as link
#' (`FALSE`, default for [create_hyperlink_column()]) or image (`TRUE`, default
#' for [create_picture_column()]). Graph property: `isPicture`.
#' @export
create_hyperlink_column <- function(name, ..., is_picture = FALSE) {
  create_column_definition(
    name = name,
    ...,
    isPicture = if (!dots_has_name("isPicture", ...)) is_picture,
    .col_type = "hyperlinkOrPicture",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @export
create_picture_column <- function(name, ..., is_picture = TRUE) {
  create_hyperlink_column(name = name, ..., is_picture = is_picture)
}

#' @rdname create_column_definition
#' @export
create_thumbnail_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "thumbnail",
    call = current_env()
  )
}

#' @rdname create_column_definition
#' @export
create_geolocation_column <- function(name, ...) {
  create_column_definition(
    name = name,
    ...,
    .col_type = "geolocation",
    call = current_env()
  )
}


#' @rdname create_column_definition
#' @param show_full_name If `TRUE`, display the entire term path. Graph
#'   property: `showFullyQualifiedName`.
#' @export
create_term_column <- function(
  name,
  ...,
  allow_multiple_values = NULL,
  show_full_name = NULL,
  allow_multiple = deprecated()
) {
  if (lifecycle::is_present(allow_multiple)) {
    lifecycle::deprecate_soft(
      "0.2.0",
      "create_term_column(allow_multiple)",
      "create_term_column(allow_multiple_values)"
    )
    allow_multiple_values <- allow_multiple_values %||% allow_multiple
  }

  check_bool(allow_multiple_values, allow_null = TRUE)
  check_bool(show_full_name, allow_null = TRUE)

  create_column_definition(
    name = name,
    ...,
    showFullyQualifiedName = show_full_name,
    allowMultipleValues = allow_multiple_values,
    .col_type = "term",
    call = current_env()
  )
}

#' Create a list of column definitions
#'
#' [create_column_definition_list()] is a vectorized version of
#' [create_column_definition()] that uses a list or data frame input to create
#' a list of column definitions. This list can be used as the `columns` argument
#' for [create_sp_list()].
#'
#' Columns in `definitions` can use the argument names of the
#' `create_*_column()` helpers (e.g. `multiple_lines`) or Graph property names
#' (e.g. `allowMultipleLines`). See [create_column_definition()] for details.
#'
#' @param definitions A list or data frame with arguments to use in creation of
#' column definitions.
#' @param col_type Column type to use if not provided as a "type" column in the
#' input definitions data frame. Allowed values include the Graph column type
#' keys (e.g. "dateTime" or "personOrGroup") and the shorter names date,
#' datetime, person, group, hyperlink, and picture. Not case sensitive. A
#' "date" column uses `format = "dateOnly"` unless a format is supplied.
#' @param ignore_na If `TRUE`, drop any parameters with a `NA` value.
#' @keywords lists
#' @examples
#' definition_df <- data.frame(
#'   name = c("FirstColumn", "SecondColumn"),
#'   type = c("text", "number"),
#'   decimal_places = c(NA, 0),
#'   multiple_lines = c(TRUE, NA)
#' )
#'
#' create_column_definition_list(definition_df)
#'
#' @returns A list of named lists, one per row of `definitions`, each
#'   formatted as a columnDefinition (as created by
#'   [create_column_definition()]) for use as the `columns` argument to
#'   [create_sp_list()].
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
        calculated = create_calculated_column,
        hyperlinkorpicture = create_hyperlink_column,
        thumbnail = create_thumbnail_column,
        geolocation = create_geolocation_column,
        term = create_term_column,
        cli_abort(
          "Column {.field {name}} has an unknown column type: {.val {type}}."
        )
      )

      if (ignore_na) {
        na_params <- purrr::map_lgl(params, \(x) all(is.na(x)))
        params <- vctrs::vec_slice(
          params,
          i = !na_params
        )
      }

      if (tolower(type) == "date" && is.null(params[["format"]])) {
        params[["format"]] <- "dateOnly"
      }

      params[["name"]] <- name
      rlang::exec(.fn, !!!params)
    }
  )
}

#' Get a column default value or formula
#'
#' [get_column_default()] returns a formula or value or NULL. See documentation
#' for more information
#' <https://learn.microsoft.com/en-us/graph/api/resources/defaultcolumnvalue?view=graph-rest-1.0>
#'
#' @param formula Formula used as default value.
#' @param value Value used as default value.
#' @param allow_null If `TRUE`, return `NULL` if both `value` and `formula` are
#' `NULL`.
#' @inheritParams rlang::args_error_context
#' @keywords lists internal
#' @examples
#' get_column_default("Missing")
#'
#' get_column_default(formula = "=[Title]")
#'
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

  list(formula = as_sp_formula(formula, call = call))
}

#' Convert a data frame to a column definition list
#'
#'
#' [data_as_column_definition_list()] is used to create a column definition list
#' based on an existing data frame. This function is used internally by
#' `create_sp_list_items()` when `create_list = TRUE`.
#'
#' @param data A data frame input. Column types are used to infer the
#' appropriate Microsoft Lists column definition.
#' @param definitions_as If `"definition_list"` (default) return named list
#' output from `create_column_definition_list()`. If `"table"` return a
#' dataframe with the column names and types.
#' @param ... Ignored.
#'
#' @details Converting R data types to SharePoint column definitions
#'
#' The type for each vector in the input data frame is checked with
#' `vctrs::vec_ptype_abbr` and mapped to corresponding SharePoint list column
#' definitions:
#'
#' - factors are specified as choice columns
#' - integers are specified as number columns with `decimal_places` set to "none"
#' - characters with any value exceeding 255 characters have `multiple_lines` set to `TRUE`
#' - characters composed entirely of URL values are specified as hyperlink columns
#' - dates are specified as date columns
#' - dttm values are specified as datetime columns
#' - logical values are specified as boolean columns if they include no NA values or text columns if they do
#'
#' All other vectors are specified as text columns.
#' If the levels of any input factor column contain the character specified with `split`, this function errors.
#'
#' @inheritParams create_column_definition_list
#' @inheritParams create_choice_column
#' @examples
#' data_as_column_definition_list(mtcars)
#'
#' @returns If `definitions_as = "definition_list"` (default), a list of
#'   named lists formatted as columnDefinitions for use as the `fields`
#'   argument to [create_sp_list()]. If `definitions_as = "table"`, a data
#'   frame with one row per column of `data` describing the inferred name,
#'   type, and other definition properties.
#' @keywords lists
#' @export
data_as_column_definition_list <- function(
  data,
  ...,
  split = "|",
  ignore_na = TRUE,
  definitions_as = c("definition_list", "table")
) {
  definitions_as <- arg_match(definitions_as)

  # TODO: Pull display names from column labels
  col_types <- purrr::map_chr(
    data,
    \(x) {
      type <- switch(
        vctrs::vec_ptype_abbr(x),
        "chr" = "text",
        "fct" = "choice",
        "dbl" = "number",
        "int" = "number",
        "lgl" = "boolean",
        "date" = "date",
        "dttm" = "datetime",
        # NOTE: "list" type columns are treated as text
        "text"
        # NA_character_
      )

      na_x <- is.na(x)

      if (!all(na_x) && all(is_url(x) | na_x)) {
        type <- "hyperlink"
      }

      # NOTE: Logical NA values are not supported, use text instead
      if (any(na_x) && type == "boolean") {
        # TODO: Add warning
        type <- "text"
      }

      type
    }
  )

  definitions_list <- purrr::map(
    seq_along(col_types),
    \(x) {
      def <- list(
        name = names(data)[[x]],
        type = col_types[[x]]
      )

      has_long_text <- def[["type"]] == "text" &&
        any(nchar(data[[x]], keepNA = FALSE) > 255)

      if (has_long_text) {
        def[["multiple_lines"]] <- TRUE
      }

      if (def[["type"]] == "choice") {
        # type is only "choices" if column value is factor
        # TODO: Explore passing choices as a list column
        lvls <- levels(data[[x]])

        if (any(grepl(split, lvls, fixed = TRUE))) {
          cli_abort(
            "{.arg split} ({.val {split}}) can't appear in the levels of
            factor column {.field {names(data)[[x]]}}."
          )
        }

        def[["choices"]] <- paste0(lvls, collapse = split)
        def[["split"]] <- split
      }

      if ((def[["type"]] == "number") && is.integer(data[1, x])) {
        def[["decimal_places"]] <- "none"
      }

      if (def[["type"]] == "date") {
        def[["format"]] <- "dateOnly"
      } else if (def[["type"]] == "datetime") {
        def[["format"]] <- "dateTime"
      }

      as.data.frame(def)
    }
  )

  definitions <- vctrs::vec_rbind(!!!definitions_list)

  if (definitions_as == "table") {
    return(definitions)
  }

  create_column_definition_list(
    definitions,
    ignore_na = ignore_na
  )
}


#' Format the nested data frame list included in the SharePoint list metadata
#' @returns `x` with element `key` dropped if empty for every row, otherwise
#'   set to its non-missing values.
#' @noRd
fmt_sp_list_metadata_df <- function(x, key) {
  values <- vctrs::list_drop_empty(as.list(x[[key]]))
  missing_values <- purrr::map_lgl(
    values,
    \(i) {
      # NOTE: `is.na(i)` is only safe to call when `i` has length 1. A
      # populated nested field (e.g. a "choice" or "number" column
      # definition) has multiple named elements, and `is.na()` on a
      # multi-element list returns one value per element instead of a
      # single TRUE/FALSE.
      (length(i) == 1 && is.na(i)) |
        (length(i) == 1 & length(i[[1]]) == 0)
    }
  )

  if (all(missing_values)) {
    x[[key]] <- NULL
  } else {
    x[[key]] <- values[!missing_values]
  }

  x
}

#' Create a new column definition based on an existing list
#'
#' `r lifecycle::badge("experimental")`
#'
#' [copy_column_definition_list()] takes an existing SharePoint list and uses
#' the list metadata to create a column definition list that can be used to
#' create a new SharePoint list. Note: lookup columns retain the original lookup
#' list references so self-referencing lookup columns are copied as lookup
#' columns referencing the source list.
#'
#' @param sp_list A `ms_list` object or a data frame created by
#' [get_sp_list_metadata()]. Optional if additional parameters are provided to
#' `...` that can be used to get a SharePoint list to copy column definitions
#' from.
#' @inheritDotParams get_sp_list_metadata
#' @returns A list of named lists, each formatted as a columnDefinition (as
#'   created by [create_column_definition()]) for use as the `fields`
#'   argument to [create_sp_list()].
#' @keywords lists
#' @export
copy_column_definition_list <- function(sp_list = NULL, ...) {
  if (
    is.data.frame(sp_list) &&
      all(has_name(sp_list, c("name", "id", "columnGroup", "definition")))
  ) {
    sp_list_meta <- sp_list
    # TODO: Add an alert when this is done
  } else {
    sp_list_meta <- get_sp_list_metadata(
      sp_list = sp_list,
      ...
    )
  }

  src_col_definitions <- vctrs::vec_slice(
    sp_list_meta,
    i = !(sp_list_meta[["name"]] %in% c("Title", sp_list_internal_colnames))
  )

  src_col_definitions[["columnGroup"]] <- NULL
  src_col_definitions[["id"]] <- NULL

  col_definition <- src_col_definitions |>
    vctrs::vec_chop() |>
    purrr::map(
      \(x) {
        x <- as.list(x)

        # Drop blank description values
        if (!is.na(x[["description"]]) && x[["description"]] == "") {
          x[["description"]] <- NULL
        }

        x <- purrr::reduce(
          c("text", "dateTime", "number", "choice", "personOrGroup", "lookup"),
          \(l, i) {
            fmt_sp_list_metadata_df(x = l, key = i)
          },
          .init = x
        )
        # TODO: lookup column types are not tested

        # Unlist choice definitions
        if (has_name(x, "choice")) {
          x[["choice"]][["choices"]] <- unlist(x[["choice"]][["choices"]])
        }

        # Drop read only columns
        if (!x[["readOnly"]]) {
          x[["readOnly"]] <- NULL
        }

        # Coerce default values to lists and drop empty defaults
        if (has_name(x, "defaultValue")) {
          x[["defaultValue"]] <- as.list(x[["defaultValue"]])

          if (all(is.na(x[["defaultValue"]]))) {
            x[["defaultValue"]] <- NULL
          }
        }

        vctrs::list_drop_empty(x)
      }
    )

  col_definition
}
