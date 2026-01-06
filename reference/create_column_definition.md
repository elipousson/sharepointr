# Create a column definition for use with the create column method for SharePoint lists

`create_column_definition()` builds a named list with the properties of
the columnDefinition resource type.

More information:
<https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>

## Usage

``` r
create_column_definition(
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
)

create_text_column(
  name,
  ...,
  multiple_lines = NULL,
  append_changes = NULL,
  lines = NULL,
  max_length = NULL,
  text_type = c("plain", "richText")
)

create_choice_column(
  name,
  choices,
  ...,
  allow_text = TRUE,
  display_as = c("dropDownMenu", "checkBoxes", "radioButtons"),
  allow_na = TRUE,
  na_replacement = "NA",
  split = NULL
)

create_number_column(
  name,
  ...,
  decimals = "automatic",
  display_as = NULL,
  max = NULL,
  min = NULL
)

create_datetime_column(
  name,
  ...,
  display_as = c("default", "friendly", "standard"),
  format = c("dateOnly", "dateTime")
)

create_boolean_column(name, ...)

create_currency_column(name, ..., locale = "en-us")

create_calculated_column(
  name,
  ...,
  formula,
  format = c("dateOnly", "dateTime"),
  output_type = c("text", "boolean", "currency", "dateTime", "number")
)

create_lookup_column(
  name,
  lookup_list_column,
  ...,
  lookup_list_id = NULL,
  lookup_list = NULL,
  allow_multiple = NULL,
  allow_unlimited_length = NULL,
  primary_lookup_column_id = NULL
)

create_person_column(
  name,
  ...,
  allow_multiple = NULL,
  display_as = NULL,
  from_type = "peopleOnly"
)

create_group_column(
  name,
  ...,
  allow_multiple = NULL,
  display_as = NULL,
  from_type = "peopleAndGroups"
)

create_hyperlink_column(name, ..., is_picture = FALSE)

create_picture_column(name, ..., is_picture = TRUE)

create_thumbnail_column(name, ...)

create_geolocation_column(name, ...)

create_term_column(name, ..., allow_multiple = TRUE, show_full_name = NULL)
```

## Arguments

- name:

  Column name.

- ...:

  Additional arguments passed to `create_column_definition()` or
  appended to the end of the column definition list.

- .col_type:

  Column type. Defaults to "text". Must be one of "boolean",
  "calculated", "choice", "currency", "dateTime", "lookup", "number",
  "personOrGroup", "text", "term", "hyperlinkOrPicture", "thumbnail",
  "contentApprovalStatus", or "geolocation".

- enforce_unique:

  Enforce unique values in column.

- hidden:

  If `TRUE`, column will be hidden by default.

- deletable:

  If `TRUE`, column can't be deleted separate from the list.

- required:

  If `TRUE`, column will be required.

- default:

  Default value set by helper
  [`get_column_default()`](https://elipousson.github.io/sharepointr/reference/get_column_default.md)
  function.

- description:

  Column description.

- displayname:

  Column display name.

- multiple_lines:

  Logical. If `TRUE`, allow multiple lines of text.

- append_changes:

  Logical. If `TRUE`, append changes to existing value for column.

- lines:

  Whole number.

- max_length:

  Whole number. Max length in number of characters.

- text_type:

  One of `c("plain", "richText")`

- choices:

  A character vector of choice options.

- allow_text:

  If `TRUE`, allow text entry in the choice column.

- display_as:

  Value displayed as option. For `create_choice_column` one
  of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
  `create_number_column`, one of `c("number", "percentage")`. For
  `create_datetime_column`, one of
  `c("default", "friendly", "standard")`.

- allow_na:

  If `TRUE`, allow NA values in `choices`.

- na_replacement:

  Used as `replacement` by
  [`stringr::str_replace_na()`](https://stringr.tidyverse.org/reference/str_replace_na.html)
  on `choices` if they contain NA values.

- split:

  character vector (or object which can be coerced to such) containing
  [regular expression](https://rdrr.io/r/base/regex.html)(s) (unless
  `fixed = TRUE`) to use for splitting. If empty matches occur, in
  particular if `split` has length 0, `x` is split into single
  characters. If `split` has length greater than 1, it is re-cycled
  along `x`.

- decimals:

  One of `c("none", "one", "two", "three", "four", "five")` or a numeric
  value between 0 and 5.

- max, min:

  Minimum and maximum values allowed in number column.

- format:

  `"dateOnly"` or `"dateTime"`. Required by `create_calculated_column`
  if `output_type` is "dateTime" otherwise ignored.

- locale:

  Locale

- formula:

  Required string with formula for calculated column definition. See
  [examples of common formulas in
  lists](https://support.microsoft.com/en-us/office/examples-of-common-formulas-in-lists-d81f5f21-2b4e-45ce-b170-bf7ebf6988b3).
  Reference existing columns using the display name enclosed in square
  brackets. The formula must start with an equals sign `"="` which this
  function appends to the formula text if it is missing.

- output_type:

  Value type returned by calculated formula. One of
  `c("text", "boolean", "currency", "dateTime", "number")`

- lookup_list_column:

  Name of lookup column in the lookup list to use.

- lookup_list_id, lookup_list:

  Lookup list ID string or "ms_list" class object with id value in list
  properties.

- allow_multiple:

  If `TRUE`, allow lookup column to return multiple values.

- allow_unlimited_length:

  If `TRUE`, allow lookup column to return any length value.

- primary_lookup_column_id:

  If column definition is for a secondary column, the primary lookup
  column ID must be supplied.

- from_type:

  What type of resources to choose from. Defaults to "peopleOnly" for
  `create_person_column()` or "peopleAndGroups" for
  `create_group_column()`

- is_picture:

  Logical indicator for display of hyperlink value as link (`FALSE`,
  default for `create_hyperlink_column()`) or image (`TRUE`, default for
  `create_picture_column()`).

## Details

Display as options

Display as options vary by columnDefinition type. See documentation for
more details:

- personOrGroupColumn:
  <https://learn.microsoft.com/en-us/graph/api/resources/personorgroupcolumn?view=graph-rest-1.0#displayas-options>

- choiceColumn:
  <https://learn.microsoft.com/en-us/graph/api/resources/choicecolumn?view=graph-rest-1.0#properties>

- numberColumn:
  <https://learn.microsoft.com/en-us/graph/api/resources/numbercolumn?view=graph-rest-1.0#properties>

- dateTimeColumn:
  <https://learn.microsoft.com/en-us/graph/api/resources/datetimecolumn?view=graph-rest-1.0>

## Examples

``` r
create_text_column("TextColumn")
#> $name
#> [1] "TextColumn"
#> 
#> $hidden
#> [1] FALSE
#> 
#> $text
#> $text$textType
#> [1] "plain"
#> 
#> 

fruit <- c("apple", "banana", "pear", "pineapple")
create_choice_column("ChoiceColumn", fruit)
#> $name
#> [1] "ChoiceColumn"
#> 
#> $hidden
#> [1] FALSE
#> 
#> $choice
#> $choice$allowTextEntry
#> [1] TRUE
#> 
#> $choice$choices
#> [1] "apple"     "banana"    "pear"      "pineapple"
#> 
#> $choice$displayAs
#> [1] "dropDownMenu"
#> 
#> 

create_number_column("NumberColumn")
#> $name
#> [1] "NumberColumn"
#> 
#> $hidden
#> [1] FALSE
#> 
#> $number
#> $number$decimalPlaces
#> [1] "automatic"
#> 
#> 

create_datetime_column("DatetimeColumn")
#> $name
#> [1] "DatetimeColumn"
#> 
#> $hidden
#> [1] FALSE
#> 
#> $dateTime
#> $dateTime$format
#> [1] "dateOnly"
#> 
#> $dateTime$displayAs
#> [1] "default"
#> 
#> 

create_calculated_column(
   name = "FormulaColumn",
   formula = "=[Text Column]"
)
#> $name
#> [1] "FormulaColumn"
#> 
#> $hidden
#> [1] FALSE
#> 
#> $calculated
#> $calculated$formula
#> [1] "=[Text Column]"
#> 
#> $calculated$outputType
#> [1] "text"
#> 
#> 
```
