# Microsoft Graph columnDefinition properties
#
# Rules used by `validate_column_definition()`. Each rule is one of:
# - "bool", "whole", "number", "string", "character", "formula"
# - "person_display_as" (string checked against `sp_person_display_as` with a
#   warning for other values)
# - "default" or "validation" (nested defaultColumnValue or columnValidation)
# - a character vector of allowed values
#
# See <https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>

#' Column-level columnDefinition properties that can be written
#' @noRd
sp_column_props <- list(
  name = "string",
  displayName = "string",
  description = "string",
  enforceUniqueValues = "bool",
  hidden = "bool",
  indexed = "bool",
  required = "bool",
  readOnly = "bool",
  defaultValue = "default",
  validation = "validation",
  isDeletable = "bool",
  isSealed = "bool",
  propagateChanges = "bool",
  columnGroup = "string"
)

#' Read-only columnDefinition properties
#' @noRd
sp_column_read_only_props <- c(
  "id",
  "isReorderable",
  "sourceContentType",
  "sourceColumn",
  "type"
)

#' Properties for each column type key (facet)
#' @noRd
sp_column_type_props <- list(
  boolean = list(),
  calculated = list(
    format = c("dateOnly", "dateTime"),
    formula = "formula",
    outputType = c("boolean", "currency", "dateTime", "number", "text")
  ),
  choice = list(
    allowTextEntry = "bool",
    choices = "character",
    displayAs = c("checkBoxes", "dropDownMenu", "radioButtons")
  ),
  contentApprovalStatus = list(),
  currency = list(
    locale = "string"
  ),
  dateTime = list(
    displayAs = c("default", "friendly", "standard"),
    format = c("dateOnly", "dateTime")
  ),
  geolocation = list(),
  hyperlinkOrPicture = list(
    isPicture = "bool"
  ),
  lookup = list(
    allowMultipleValues = "bool",
    allowUnlimitedLength = "bool",
    columnName = "string",
    listId = "string",
    primaryLookupColumnId = "string"
  ),
  number = list(
    decimalPlaces = c(
      "automatic",
      "none",
      "one",
      "two",
      "three",
      "four",
      "five"
    ),
    displayAs = c("number", "percentage"),
    maximum = "number",
    minimum = "number"
  ),
  personOrGroup = list(
    allowMultipleSelection = "bool",
    chooseFromType = c("peopleAndGroups", "peopleOnly"),
    displayAs = "person_display_as"
  ),
  term = list(
    allowMultipleValues = "bool",
    showFullyQualifiedName = "bool"
  ),
  text = list(
    allowMultipleLines = "bool",
    appendChangesToExistingText = "bool",
    linesForEditing = "whole",
    maxLength = "whole",
    textType = c("plain", "richText")
  ),
  thumbnail = list()
)

#' Documented personOrGroupColumn displayAs values
#' @noRd
sp_person_display_as <- c(
  "account",
  "department",
  "firstName",
  "id",
  "lastName",
  "mobilePhone",
  "name",
  "nameWithPictureAndDetails",
  "nameWithPresence",
  "office",
  "pictureOnly36x36",
  "pictureOnly48x48",
  "pictureOnly72x72",
  "sipAddress",
  "title",
  "userName",
  "workEmail",
  "workPhone"
)

#' Column types the Graph API doesn't support creating on a list
#'
#' Tested against the beta and v1.0 endpoints in October 2026: a POST to
#' `lists/{id}/columns` with these column types fails with "Invalid request".
#' @noRd
sp_column_types_create_unsupported <- c(
  "geolocation",
  "hyperlinkOrPicture",
  "term",
  "thumbnail"
)

#' Default property values returned by the Graph API
#'
#' Used to drop default values when writing definitions and to treat a
#' declared default value as equal to a property missing from a response.
#' @noRd
sp_column_default_values <- list(
  column = list(
    description = "",
    enforceUniqueValues = FALSE,
    hidden = FALSE,
    indexed = FALSE,
    readOnly = FALSE,
    required = FALSE
  ),
  text = list(
    allowMultipleLines = FALSE,
    appendChangesToExistingText = FALSE,
    textType = "plain"
  ),
  choice = list(
    allowTextEntry = FALSE,
    displayAs = "dropDownMenu"
  ),
  number = list(
    decimalPlaces = "automatic",
    displayAs = "number"
  ),
  dateTime = list(
    displayAs = "default"
  ),
  lookup = list(
    allowMultipleValues = FALSE,
    allowUnlimitedLength = FALSE
  ),
  personOrGroup = list(
    allowMultipleSelection = FALSE,
    displayAs = "nameWithPresence"
  )
)

#' Common names used in place of columnDefinition property names
#'
#' Used to suggest the Graph property name in validation errors.
#' @noRd
sp_column_prop_hints <- c(
  label = "displayName",
  displayname = "displayName",
  display_name = "displayName",
  enforce_unique = "enforceUniqueValues",
  default = "defaultValue",
  type = "a column type key, e.g. `text: {}`",
  sp_col_type = "a column type key, e.g. `text: {}`",
  multiple_lines = "allowMultipleLines",
  append_changes = "appendChangesToExistingText",
  lines = "linesForEditing",
  max_length = "maxLength",
  text_type = "textType",
  allow_text = "allowTextEntry",
  values = "choices",
  display_as = "displayAs",
  decimals = "decimalPlaces",
  decimal_places = "decimalPlaces",
  max = "maximum",
  min = "minimum",
  output_type = "outputType",
  allow_multiple = "allowMultipleValues or allowMultipleSelection",
  from_type = "chooseFromType",
  lookup_list_id = "listId",
  lookup_list_column = "columnName",
  is_picture = "isPicture",
  show_full_name = "showFullyQualifiedName"
)

#' Validate a column definition
#'
#' @description
#' [as_column_definition()] validates a named list of Microsoft Graph
#' columnDefinition properties, such as a column read from a YAML file with
#' [read_sp_list_yaml()] or returned by [create_column_definition()].
#'
#' A column definition must have a `name` and exactly one column type key
#' (e.g. `text`, `choice`, or `dateTime`) holding the properties for that type.
#' Property names must match the Graph API documentation. Unknown properties
#' and read-only properties (e.g. `type`) are errors. A column `id` is allowed
#' as a reference to an existing column but isn't used to match, create, or
#' update columns. A `custom` element is allowed and isn't validated, so it
#' can hold metadata used by other applications.
#'
#' Formulas for calculated columns, default values, and validation have a
#' leading `"="` added if missing. Unlike [create_calculated_column()], the
#' formula isn't processed with [glue::glue()].
#'
#' @param x A named list of columnDefinition properties.
#' @param ... Must be empty.
#' @param allow_custom If `TRUE` (default), allow a `custom` element.
#' @inheritParams rlang::args_error_context
#' @returns The validated column definition `x` with `choices` converted to a
#'   character vector and formulas normalized.
#' @seealso
#' - [columnDefinition resource type](https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0)
#' - [read_sp_list_yaml()] for the YAML format that uses these definitions.
#' @keywords lists
#' @examples
#' as_column_definition(
#'   list(
#'     name = "Notes",
#'     displayName = "Project Notes",
#'     text = list(allowMultipleLines = TRUE)
#'   )
#' )
#'
#' @export
as_column_definition <- function(
  x,
  ...,
  allow_custom = TRUE,
  call = caller_env()
) {
  check_dots_empty()
  validate_column_definition(
    x,
    allow_read_only = FALSE,
    allow_custom = allow_custom,
    require_type = TRUE,
    call = call
  )
}

#' @param allow_read_only If `TRUE`, allow read-only properties like `id`.
#' @param require_type If `TRUE`, require exactly one column type key.
#' @param label Label used to identify the column in error messages.
#' @noRd
validate_column_definition <- function(
  x,
  allow_read_only = FALSE,
  allow_custom = TRUE,
  require_type = TRUE,
  label = NULL,
  call = caller_env()
) {
  if (!is.list(x) || (length(x) > 0 && !is_named(x))) {
    cli_abort(
      "{label %||% 'A column definition'} must be a named list.",
      call = call
    )
  }

  name <- x[["name"]]
  label <- label %||% if (is_string(name)) name else "column"
  check_name(name, arg = paste0(label, ".name"), call = call)

  if (grepl("^[A-Za-z]{1,3}[0-9]+$", name)) {
    cli_warn(
      c(
        "Column name {.val {name}} looks like a spreadsheet cell reference.",
        "i" = "SharePoint encodes names like this (e.g. {.val V4} is stored
        as {.val _x0056_4})."
      ),
      call = call
    )
  }

  type_keys <- intersect(names(x), names(sp_column_type_props))

  allowed <- c(
    names(sp_column_props),
    names(sp_column_type_props),
    # A column id is allowed as a reference to an existing column
    "id",
    if (allow_read_only) sp_column_read_only_props,
    if (allow_custom) "custom"
  )

  unknown <- setdiff(names(x), allowed)

  if (length(unknown) > 0) {
    abort_unknown_props(
      unknown,
      label = label,
      read_only = intersect(unknown, sp_column_read_only_props),
      call = call
    )
  }

  if (length(type_keys) > 1) {
    cli_abort(
      "{.field {label}} must have one column type key, not
      {length(type_keys)}: {.field {type_keys}}.",
      call = call
    )
  }

  if (require_type && length(type_keys) == 0) {
    cli_abort(
      c(
        "{.field {label}} must have a column type key.",
        "i" = "Use one of {.or {.field {names(sp_column_type_props)}}},
        e.g. {.code text: {{}}}."
      ),
      call = call
    )
  }

  check_string(x[["id"]], allow_null = TRUE, arg = paste0(label, ".id"), call = call)

  # Validate column-level properties
  for (prop in intersect(names(x), names(sp_column_props))) {
    if (prop == "name") {
      next
    }

    x[[prop]] <- check_sp_prop(
      x[[prop]],
      rule = sp_column_props[[prop]],
      arg = paste0(label, ".", prop),
      call = call
    )
  }

  if (length(type_keys) == 1) {
    x[[type_keys]] <- validate_column_type_props(
      x[[type_keys]],
      type = type_keys,
      label = label,
      call = call
    )
  }

  if (allow_custom && !is.null(x[["custom"]])) {
    custom <- x[["custom"]]
    if (!is.list(custom) || (length(custom) > 0 && !is_named(custom))) {
      cli_abort(
        "{.field {label}.custom} must be a named list (a YAML mapping).",
        call = call
      )
    }
  }

  x
}

#' Validate the properties for a column type key
#' @noRd
validate_column_type_props <- function(
  props,
  type,
  label = "column",
  call = caller_env()
) {
  if (is.null(props) || (is.list(props) && length(props) == 0)) {
    return(set_names(list(), character(0)))
  }

  path <- paste0(label, ".", type)

  if (!is.list(props) || !is_named(props)) {
    cli_abort(
      "{.field {path}} must be a named list (a YAML mapping).",
      call = call
    )
  }

  rules <- sp_column_type_props[[type]]
  unknown <- setdiff(names(props), names(rules))

  if (length(unknown) > 0) {
    abort_unknown_props(
      unknown,
      label = path,
      allowed = names(rules),
      call = call
    )
  }

  for (prop in names(props)) {
    props[[prop]] <- check_sp_prop(
      props[[prop]],
      rule = rules[[prop]],
      arg = paste0(path, ".", prop),
      call = call
    )
  }

  if (type == "calculated") {
    if (is.null(props[["formula"]]) || is.null(props[["outputType"]])) {
      cli_abort(
        "{.field {path}} must have {.field formula} and {.field outputType}.",
        call = call
      )
    }

    if (!is.null(props[["format"]]) && props[["outputType"]] != "dateTime") {
      cli_abort(
        "{.field {path}.format} can only be used when {.field outputType} is
        {.val dateTime}.",
        call = call
      )
    }
  }

  if (type == "lookup") {
    if (is.null(props[["listId"]]) || is.null(props[["columnName"]])) {
      cli_abort(
        "{.field {path}} must have {.field listId} and {.field columnName}.",
        call = call
      )
    }
  }

  props
}

#' Check a single property value against a rule
#' @returns The (possibly normalized) value.
#' @noRd
check_sp_prop <- function(x, rule, arg, call = caller_env()) {
  if (length(rule) > 1) {
    check_string(x, arg = arg, call = call)
    return(arg_match0(x, rule, arg_nm = arg, error_call = call))
  }

  switch(
    rule,
    bool = check_bool(x, arg = arg, call = call),
    whole = check_number_whole(x, arg = arg, call = call),
    number = check_number_decimal(x, arg = arg, call = call),
    string = check_string(x, arg = arg, call = call),
    character = {
      x <- unlist(x)
      check_character(x, arg = arg, call = call)
      if (anyNA(x)) {
        cli_abort("{.arg {arg}} can't contain missing values.", call = call)
      }
    },
    formula = {
      check_string(x, arg = arg, call = call)
      x <- as_sp_formula_string(x)
    },
    person_display_as = {
      check_string(x, arg = arg, call = call)
      if (!x %in% sp_person_display_as) {
        cli_warn(
          "{.arg {arg}} value {.val {x}} isn't a documented value.",
          call = call
        )
      }
    },
    default = {
      x <- check_sp_default_value(x, arg = arg, call = call)
    },
    validation = {
      x <- check_sp_validation(x, arg = arg, call = call)
    }
  )

  x
}

#' Check a defaultColumnValue
#' @noRd
check_sp_default_value <- function(x, arg, call = caller_env()) {
  x <- purrr::compact(x)

  if (
    !is.list(x) ||
      !is_named(x) ||
      length(x) != 1 ||
      !names(x) %in% c("value", "formula")
  ) {
    cli_abort(
      "{.arg {arg}} must have either a {.field value} or {.field formula}
      element.",
      call = call
    )
  }

  if (has_name(x, "formula")) {
    check_string(x[["formula"]], arg = paste0(arg, ".formula"), call = call)
    x[["formula"]] <- as_sp_formula_string(x[["formula"]])
    return(x)
  }

  value <- x[["value"]]

  if (!is_scalar_atomic(value) || is.na(value)) {
    cli_abort(
      "{.arg {arg}.value} must be a single value.",
      call = call
    )
  }

  # Graph defaultColumnValue values are strings
  x[["value"]] <- as.character(value)
  x
}

#' Check a columnValidation
#' @noRd
check_sp_validation <- function(x, arg, call = caller_env()) {
  allowed <- c("formula", "descriptions", "defaultLanguage")

  if (!is.list(x) || !is_named(x) || !all(names(x) %in% allowed)) {
    cli_abort(
      c(
        "{.arg {arg}} must be a named list with {.or {.field {allowed}}}
        elements.",
        "i" = "Use {.fn column_validation} to create a validation definition."
      ),
      call = call
    )
  }

  check_string(x[["formula"]], arg = paste0(arg, ".formula"), call = call)
  x[["formula"]] <- as_sp_formula_string(x[["formula"]])
  check_string(
    x[["defaultLanguage"]],
    allow_null = TRUE,
    arg = paste0(arg, ".defaultLanguage"),
    call = call
  )

  descriptions <- x[["descriptions"]]

  if (!is.null(descriptions)) {
    valid <- is.list(descriptions) &&
      all(purrr::map_lgl(
        descriptions,
        \(d) {
          is.list(d) &&
            is_string(d[["languageTag"]]) &&
            is_string(d[["displayName"]])
        }
      ))

    if (!valid) {
      cli_abort(
        "{.arg {arg}.descriptions} must be a list of elements with
        {.field languageTag} and {.field displayName} strings.",
        call = call
      )
    }
  }

  x
}

#' Error for unknown column definition properties
#' @noRd
abort_unknown_props <- function(
  unknown,
  label,
  allowed = NULL,
  read_only = NULL,
  call = caller_env()
) {
  hints <- sp_column_prop_hints[intersect(unknown, names(sp_column_prop_hints))]

  cli_abort(
    c(
      "{.field {label}} has unknown propert{?y/ies}: {.field {unknown}}.",
      if (length(read_only) > 0) {
        c("i" = "{.field {read_only}} {?is/are} read-only.")
      },
      purrr::set_names(
        purrr::imap_chr(hints, \(to, from) {
          # Escape braces so cli doesn't interpolate hint text
          to <- gsub("}", "}}", gsub("{", "{{", to, fixed = TRUE), fixed = TRUE)
          # Style property names but not longer hints
          if (!grepl(" ", to)) {
            to <- paste0("{.field ", to, "}")
          }
          paste0("Use ", to, " in place of {.field ", from, "}.")
        }),
        rep("i", length(hints))
      ),
      if (!is.null(allowed) && length(allowed) > 0) {
        c("i" = "Allowed properties: {.field {allowed}}.")
      } else if (!is.null(allowed)) {
        c("i" = "This column type has no properties. Use {.code {{}}}.")
      }
    ),
    call = call
  )
}

#' Add a leading `=` to a formula without glue processing
#' @noRd
as_sp_formula_string <- function(formula) {
  if (!grepl("^=", formula)) {
    formula <- paste0("=", formula)
  }

  formula
}

#' Get the column type key for a column definition
#' @returns A string or `NULL` if the definition has no column type key.
#' @noRd
column_type_key <- function(x) {
  type <- intersect(names(x), names(sp_column_type_props))

  if (length(type) == 0) {
    return(NULL)
  }

  type[[1]]
}

#' Create a column validation definition
#'
#' [column_validation()] creates a columnValidation definition for the
#' `validation` property of a column definition. A validation formula must
#' evaluate to `TRUE` for a value to be saved.
#'
#' The Graph API doesn't support creating or updating a list column with a
#' `validation` property, so [create_sp_list_column()] and
#' [sync_sp_list()] apply validation with the SharePoint REST API
#' instead. Validation isn't returned when reading list columns with the Graph
#' API, so it can't be compared to an existing column.
#'
#' @param formula Required. Validation formula. Reference columns with the
#'   display name enclosed in square brackets, e.g. `"=LEN([Title])<10"`. A
#'   leading `"="` is added if missing.
#' @param descriptions Optional message shown when validation fails. Either a
#'   string (used for `default_language`) or a named character vector with
#'   language tags as names, e.g. `c("en-US" = "Too long")`. Graph property:
#'   `descriptions`.
#' @param default_language Default BCP 47 language tag for `descriptions`.
#'   Graph property: `defaultLanguage`.
#' @returns A named list formatted as a columnValidation resource.
#' @seealso [columnValidation resource type](https://learn.microsoft.com/en-us/graph/api/resources/columnvalidation?view=graph-rest-1.0)
#' @keywords lists
#' @examples
#' column_validation("=LEN([Project Code])=8", "Use an 8 character code.")
#'
#' @export
column_validation <- function(
  formula,
  descriptions = NULL,
  default_language = "en-US"
) {
  check_string(formula)
  check_character(descriptions, allow_null = TRUE)
  check_string(default_language)

  if (!is.null(descriptions)) {
    if (is.null(names(descriptions))) {
      if (length(descriptions) > 1) {
        cli_abort(
          "{.arg descriptions} must be a string or a named character vector."
        )
      }
      names(descriptions) <- default_language
    }

    descriptions <- purrr::imap(
      descriptions,
      \(message, language) {
        list(languageTag = language, displayName = unname(message))
      }
    ) |>
      unname()
  }

  purrr::compact(
    list(
      formula = as_sp_formula_string(formula),
      descriptions = descriptions,
      defaultLanguage = default_language
    )
  )
}
