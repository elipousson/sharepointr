# Create a column definition for use with the create column method for SharePoint lists

`create_column_definition()` builds a named list with the properties of
the columnDefinition resource type. The `create_*_column()` helpers
create a definition for a single column type.

Arguments that set a columnDefinition property note the matching Graph
property name. Graph property names can also be passed to `...` (e.g.
`create_text_column("Notes", allowMultipleLines = TRUE)` or
`create_column_definition("Notes", displayName = "Project Notes")`).
Column-level properties are added to the definition and any other values
are added to the properties for the column type. Supplying the same
property with both an argument and a Graph name is an error. Definitions
are checked with the same rules as
[`as_column_definition()`](https://elipousson.github.io/sharepointr/reference/as_column_definition.md).

Properties left as `NULL` aren't included in the definition so
SharePoint uses the default value when a column is created.

More information:
<https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0>

## Usage

``` r
create_column_definition(
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
)

create_text_column(
  name,
  ...,
  multiple_lines = NULL,
  append_changes = NULL,
  lines = NULL,
  max_length = NULL,
  text_type = NULL
)

create_choice_column(
  name,
  choices,
  ...,
  allow_text = NULL,
  display_as = NULL,
  allow_na = TRUE,
  na_replacement = "NA",
  split = NULL
)

create_number_column(
  name,
  ...,
  decimal_places = NULL,
  display_as = NULL,
  max = NULL,
  min = NULL,
  decimals = deprecated()
)

create_datetime_column(name, ..., display_as = NULL, format = NULL)

create_boolean_column(name, ...)

create_currency_column(name, ..., locale = NULL)

create_calculated_column(name, ..., formula, format = NULL, output_type = NULL)

create_lookup_column(
  name,
  lookup_list_column = NULL,
  ...,
  lookup_list_id = NULL,
  lookup_list = NULL,
  allow_multiple_values = NULL,
  allow_unlimited_length = NULL,
  primary_lookup_column_id = NULL,
  allow_multiple = deprecated()
)

create_person_column(
  name,
  ...,
  allow_multiple_selection = NULL,
  display_as = NULL,
  from_type = "peopleOnly",
  allow_multiple = deprecated()
)

create_group_column(
  name,
  ...,
  allow_multiple_selection = NULL,
  display_as = NULL,
  from_type = "peopleAndGroups",
  allow_multiple = deprecated()
)

create_hyperlink_column(name, ..., is_picture = FALSE)

create_picture_column(name, ..., is_picture = TRUE)

create_thumbnail_column(name, ...)

create_geolocation_column(name, ...)

create_term_column(
  name,
  ...,
  allow_multiple_values = NULL,
  show_full_name = NULL,
  allow_multiple = deprecated()
)
```

## Arguments

- name:

  Column name. Graph property: `name`. The name can't be changed after a
  column is created.

- ...:

  Additional arguments passed to `create_column_definition()` or
  columnDefinition properties using Graph property names.

- .col_type:

  Column type. Defaults to "text". Must be one of "boolean",
  "calculated", "choice", "currency", "dateTime", "lookup", "number",
  "personOrGroup", "text", "term", "hyperlinkOrPicture", "thumbnail",
  "contentApprovalStatus", or "geolocation".

- enforce_unique:

  Enforce unique values in column. Graph property:
  `enforceUniqueValues`.

- hidden:

  If `TRUE`, column will be hidden by default. Graph property: `hidden`.

- deletable:

  If `TRUE`, column can't be deleted separate from the list. Graph
  property: `isDeletable`.

- indexed, sealed, propagate_changes, read_only, id:

  Additional arguments used by `create_column_definition()`. Graph
  properties: `indexed`, `isSealed`, `propagateChanges`, `readOnly`, and
  `id`.

- required:

  If `TRUE`, column will be required. Graph property: `required`.

- validation:

  Column validation created with
  [`column_validation()`](https://elipousson.github.io/sharepointr/reference/column_validation.md).
  Graph property: `validation`.

- default:

  Default value set by helper
  [`get_column_default()`](https://elipousson.github.io/sharepointr/reference/get_column_default.md)
  function. Graph property: `defaultValue`.

- description:

  Column description. Graph property: `description`.

- display_name:

  Column display name. Graph property: `displayName`.

- displayname:

  **\[deprecated\]** Use `display_name`.

- call:

  The execution environment used in error messages. The
  `create_*_column()` helpers pass their own environment.

- multiple_lines:

  Logical. If `TRUE`, allow multiple lines of text. Graph property:
  `allowMultipleLines`.

- append_changes:

  Logical. If `TRUE`, append changes to existing value for column. Graph
  property: `appendChangesToExistingText`.

- lines:

  Whole number. Size of the text box. Graph property: `linesForEditing`.

- max_length:

  Whole number. Max length in number of characters. Graph property:
  `maxLength`.

- text_type:

  One of `c("plain", "richText")`. Graph property: `textType`.

- choices:

  A character vector of choice options. Graph property: `choices`.

- allow_text:

  If `TRUE`, allow text entry in the choice column. Graph property:
  `allowTextEntry`.

- display_as:

  Value displayed as option. For `create_choice_column` one
  of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
  `create_number_column`, one of `c("number", "percentage")`. For
  `create_datetime_column`, one of
  `c("default", "friendly", "standard")`. Graph property: `displayAs`.

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

- decimal_places:

  One of `c("automatic", "none", "one", "two", "three", "four", "five")`
  or a whole number between 0 and 5. Graph property: `decimalPlaces`.

- max, min:

  Minimum and maximum values allowed in number column. Graph properties:
  `maximum` and `minimum`.

- decimals:

  **\[deprecated\]** Use `decimal_places`.

- format:

  For `create_datetime_column()`, `"dateOnly"` or `"dateTime"`. Graph
  property: `format`.

- locale:

  Locale used to set the currency symbol, e.g. `"en-us"`. Graph
  property: `locale`.

- formula:

  Required string with formula for calculated column definition. See
  [examples of common formulas in
  lists](https://support.microsoft.com/en-us/office/examples-of-common-formulas-in-lists-d81f5f21-2b4e-45ce-b170-bf7ebf6988b3).
  Reference existing columns using the display name enclosed in square
  brackets. The formula must start with an equals sign `"="` which this
  function appends to the formula text if it is missing. The formula is
  processed with
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).
  Graph property: `formula`.

- output_type:

  Value type returned by calculated formula. One of
  `c("text", "boolean", "currency", "dateTime", "number")`. Defaults to
  `"text"`. Graph property: `outputType`.

- lookup_list_column:

  Name of lookup column in the lookup list to use. Graph property:
  `columnName`.

- lookup_list_id, lookup_list:

  Lookup list ID string or "ms_list" class object with id value in list
  properties. Graph property: `listId`.

- allow_multiple_values:

  If `TRUE`, allow a lookup or term column to store multiple values.
  Graph property: `allowMultipleValues`.

- allow_unlimited_length:

  If `TRUE`, allow lookup column to return any length value. Graph
  property: `allowUnlimitedLength`.

- primary_lookup_column_id:

  If column definition is for a secondary column, the primary lookup
  column ID must be supplied. Graph property: `primaryLookupColumnId`.

- allow_multiple:

  **\[deprecated\]** Use `allow_multiple_values` for
  `create_lookup_column()` and `create_term_column()` or
  `allow_multiple_selection` for `create_person_column()` and
  `create_group_column()`.

- allow_multiple_selection:

  If `TRUE`, allow a person or group column to store multiple values.
  Graph property: `allowMultipleSelection`.

- from_type:

  What type of resources to choose from. Defaults to "peopleOnly" for
  `create_person_column()` or "peopleAndGroups" for
  `create_group_column()`. Graph property: `chooseFromType`.

- is_picture:

  Logical indicator for display of hyperlink value as link (`FALSE`,
  default for `create_hyperlink_column()`) or image (`TRUE`, default for
  `create_picture_column()`). Graph property: `isPicture`.

- show_full_name:

  If `TRUE`, display the entire term path. Graph property:
  `showFullyQualifiedName`.

## Value

A named list of columnDefinition properties formatted for use as the
`columns` argument to
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
or as an element of the list returned by
[`create_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/create_column_definition_list.md).

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

Column types the Graph API can't create

As of October 2026, the Graph API returns an "Invalid request" error
when creating a list column with the hyperlinkOrPicture, thumbnail,
geolocation, or term column types. `create_hyperlink_column()`,
`create_picture_column()`, `create_thumbnail_column()`,
`create_geolocation_column()`, and `create_term_column()` still create
valid definitions, but
[`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
can't use them. The Graph API also doesn't return the column type for
hyperlinkOrPicture, thumbnail, or term columns when reading list
columns.

Term columns also need a term set, which isn't supported.

## Examples

``` r
create_text_column("TextColumn")
#> $name
#> [1] "TextColumn"
#> 
#> $text
#> named list()
#> 

create_text_column("NotesColumn", multiple_lines = TRUE)
#> $name
#> [1] "NotesColumn"
#> 
#> $text
#> $text$allowMultipleLines
#> [1] TRUE
#> 
#> 

# Graph property names are also supported
create_text_column("NotesColumn", allowMultipleLines = TRUE)
#> $name
#> [1] "NotesColumn"
#> 
#> $text
#> $text$allowMultipleLines
#> [1] TRUE
#> 
#> 

fruit <- c("apple", "banana", "pear", "pineapple")
create_choice_column("ChoiceColumn", fruit)
#> $name
#> [1] "ChoiceColumn"
#> 
#> $choice
#> $choice$choices
#> [1] "apple"     "banana"    "pear"      "pineapple"
#> 
#> 

create_number_column("NumberColumn")
#> $name
#> [1] "NumberColumn"
#> 
#> $number
#> named list()
#> 

create_number_column("PercentColumn", display_as = "percentage", max = 1)
#> $name
#> [1] "PercentColumn"
#> 
#> $number
#> $number$displayAs
#> [1] "percentage"
#> 
#> $number$maximum
#> [1] 1
#> 
#> 

create_datetime_column("DatetimeColumn")
#> $name
#> [1] "DatetimeColumn"
#> 
#> $dateTime
#> named list()
#> 

create_datetime_column("DateColumn", format = "dateOnly")
#> $name
#> [1] "DateColumn"
#> 
#> $dateTime
#> $dateTime$format
#> [1] "dateOnly"
#> 
#> 

create_calculated_column(
   name = "FormulaColumn",
   formula = "=[Text Column]"
)
#> $name
#> [1] "FormulaColumn"
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
