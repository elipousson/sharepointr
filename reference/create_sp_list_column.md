# Create, update, and delete a SharePoint list column

`create_sp_list_column()` adds a column to a SharePoint list and
`delete_sp_list_column()` removes a column to a SharePoint list.
`update_sp_list_column()` updates a column definition for an existing
column in a SharePoint list.

## Usage

``` r
create_sp_list_column(
  sp_list = NULL,
  ...,
  column_name = NULL,
  column_definition = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL
)

update_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_definition = NULL,
  column_name_type = "name"
)

delete_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  list_name = NULL,
  site_url = NULL,
  site = NULL,
  column_name_type = "name"
)
```

## Arguments

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `list_id`, `site_url`,
  `site`, `drive_name`, `drive_id`, `drive`, and any additional
  parameters passed to `...` are all ignored.

- ...:

  Arguments passed on to
  [`create_column_definition`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)

  `name`

  :   Column name.

  `display_as`

  :   Value displayed as option. For `create_choice_column` one
      of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
      `create_number_column`, one of `c("number", "percentage")`. For
      `create_datetime_column`, one of
      `c("default", "friendly", "standard")`.

  `.col_type`

  :   Column type. Defaults to "text". Must be one of "boolean",
      "calculated", "choice", "currency", "dateTime", "lookup",
      "number", "personOrGroup", "text", "term", "hyperlinkOrPicture",
      "thumbnail", "contentApprovalStatus", or "geolocation".

  `enforce_unique`

  :   Enforce unique values in column.

  `hidden`

  :   If `TRUE`, column will be hidden by default.

  `deletable`

  :   If `TRUE`, column can't be deleted separate from the list.

  `required`

  :   If `TRUE`, column will be required.

  `default`

  :   Default value set by helper
      [`get_column_default()`](https://elipousson.github.io/sharepointr/reference/get_column_default.md)
      function.

  `description`

  :   Column description.

  `displayname`

  :   Column display name.

  `indexed,sealed,propagate_changes,read_only,validation,id,show_full_name`

  :   Additional arguments used by
      [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md).

  `multiple_lines`

  :   Logical. If `TRUE`, allow multiple lines of text.

  `append_changes`

  :   Logical. If `TRUE`, append changes to existing value for column.

  `lines`

  :   Whole number.

  `max_length`

  :   Whole number. Max length in number of characters.

  `text_type`

  :   One of `c("plain", "richText")`

  `choices`

  :   A character vector of choice options.

  `allow_na`

  :   If `TRUE`, allow NA values in `choices`.

  `na_replacement`

  :   Used as `replacement` by
      [`stringr::str_replace_na()`](https://stringr.tidyverse.org/reference/str_replace_na.html)
      on `choices` if they contain NA values.

  `allow_text`

  :   If `TRUE`, allow text entry in the choice column.

  `decimals`

  :   One of `c("none", "one", "two", "three", "four", "five")` or a
      numeric value between 0 and 5.

  `max,min`

  :   Minimum and maximum values allowed in number column.

  `locale`

  :   Locale

  `formula`

  :   Required string with formula for calculated column definition. See
      [examples of common formulas in
      lists](https://support.microsoft.com/en-us/office/examples-of-common-formulas-in-lists-d81f5f21-2b4e-45ce-b170-bf7ebf6988b3).
      Reference existing columns using the display name enclosed in
      square brackets. The formula must start with an equals sign `"="`
      which this function appends to the formula text if it is missing.

  `format`

  :   `"dateOnly"` or `"dateTime"`. Required by
      `create_calculated_column` if `output_type` is "dateTime"
      otherwise ignored.

  `output_type`

  :   Value type returned by calculated formula. One of
      `c("text", "boolean", "currency", "dateTime", "number")`

  `lookup_list_column`

  :   Name of lookup column in the lookup list to use.

  `lookup_list_id,lookup_list`

  :   Lookup list ID string or "ms_list" class object with id value in
      list properties.

  `allow_multiple`

  :   If `TRUE`, allow lookup column to return multiple values.

  `allow_unlimited_length`

  :   If `TRUE`, allow lookup column to return any length value.

  `primary_lookup_column_id`

  :   If column definition is for a secondary column, the primary lookup
      column ID must be supplied.

  `from_type`

  :   What type of resources to choose from. Defaults to "peopleOnly"
      for
      [`create_person_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
      or "peopleAndGroups" for
      [`create_group_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)

  `is_picture`

  :   Logical indicator for display of hyperlink value as link (`FALSE`,
      default for
      [`create_hyperlink_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md))
      or image (`TRUE`, default for
      [`create_picture_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)).

  `split`

  :   character vector (or object which can be coerced to such)
      containing [regular
      expression](https://rdrr.io/r/base/regex.html)(s) (unless
      `fixed = TRUE`) to use for splitting. If empty matches occur, in
      particular if `split` has length 0, `x` is split into single
      characters. If `split` has length greater than 1, it is re-cycled
      along `x`.

- column_name, column_id:

  Column ID for column to delete.

- column_definition:

  List with column definition created with
  [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  or a related function. Optional if `column_name` and any required
  additional parameters are provided.

- list_name:

  List name. Required if `sp_list` is `NULL`.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- column_name_type:

  "name" or "displayName". Used to match column ID so column_name must
  be unique if `column_name_type = "displayName"`.

## Details

See documentation:
<https://learn.microsoft.com/en-us/graph/api/list-post-columns?view=graph-rest-1.0&tabs=http>
