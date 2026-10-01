# Create SharePoint list lookup column and update lookup column items

**\[experimental\]**

`update_sp_list_person_items()` is a variant of
`update_sp_list_lookup_items()` for person or group columns. Person or
group columns are a type of lookup column where the lookup list is the
hidden "User Information List" for the site. By default, users are
matched by email address (ignoring case). Users that have never accessed
the site are not included in the "User Information List" and can't be
matched.

## Usage

``` r
create_sp_list_lookup_column(
  sp_list = NULL,
  column_name,
  lookup_list,
  lookup_list_column = column_name,
  ...,
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  call = caller_env()
)

create_sp_list_person_column(
  sp_list = NULL,
  column_name,
  ...,
  allow_multiple = NULL,
  display_as = NULL,
  from_type = "peopleOnly",
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  call = caller_env()
)

update_sp_list_lookup_items(
  data = NULL,
  sp_list = NULL,
  column_name,
  lookup_list_data = NULL,
  lookup_list = NULL,
  join_column = column_name,
  lookup_join_column = join_column,
  ...,
  .id = "id",
  ignore_case = FALSE,
  na_fields = c("drop", "replace"),
  .progress = TRUE,
  call = caller_env()
)

fmt_sp_list_lookup_items(
  data,
  column_name,
  lookup_list_data = NULL,
  lookup_list = NULL,
  lookup_join_column = column_name,
  ...,
  .id = "id",
  ignore_case = FALSE,
  call = caller_env()
)

update_sp_list_person_items(
  data = NULL,
  sp_list = NULL,
  column_name,
  join_column = column_name,
  user_column = "EMail",
  user_info_data = NULL,
  allow_hidden = FALSE,
  ...,
  .id = "id",
  na_fields = c("drop", "replace"),
  .progress = TRUE,
  call = caller_env()
)
```

## Arguments

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `site`, and `site_url`
  are all ignored.

- column_name:

  Name of the lookup (or person or group) column. For
  `create_sp_list_lookup_column()`, the name of the new column. For
  `update_sp_list_lookup_items()` and `update_sp_list_person_items()`,
  lookup ID values are written to the `"{column_name}LookupId"` field.
  For `fmt_sp_list_lookup_items()`, one or more column (or record
  element) names in `data` to format.

- lookup_list:

  The lookup list as a `ms_list` object, list name, or list URL. The
  lookup list must be in the same site as `sp_list` and a list name is
  retrieved from the same site as `sp_list`. For
  `update_sp_list_lookup_items()` and `fmt_sp_list_lookup_items()`,
  `lookup_list` is only used to retrieve `lookup_list_data` if not
  supplied. For `fmt_sp_list_lookup_items()`, a list name requires site
  information (e.g. `site_url`) passed with `...`.

- lookup_list_column:

  Name of lookup column in the lookup list to use.

- ...:

  Arguments passed on to
  [`create_lookup_column`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)

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

  `allow_unlimited_length`

  :   If `TRUE`, allow lookup column to return any length value.

  `primary_lookup_column_id`

  :   If column definition is for a secondary column, the primary lookup
      column ID must be supplied.

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

- list_name:

  List name. Required if `sp_list` is `NULL`.

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- allow_multiple:

  If `TRUE`, allow lookup column to return multiple values.

- display_as:

  Value displayed as option. For `create_choice_column` one
  of`c("checkBoxes", "dropDownMenu", "radioButtons")`. For
  `create_number_column`, one of `c("number", "percentage")`. For
  `create_datetime_column`, one of
  `c("default", "friendly", "standard")`.

- from_type:

  What type of resources to choose from. Defaults to "peopleOnly" for
  [`create_person_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  or "peopleAndGroups" for
  [`create_group_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)

- data:

  Optional. A data frame or an unnamed list of named lists (one record
  per item) with item ID values (`.id`) and join values (`join_column`)
  for the items to update. If `NULL`, items are retrieved from
  `sp_list`. Required for `fmt_sp_list_lookup_items()` where `data` must
  include all `column_name` values as column (or record element) names.

- lookup_list_data:

  Optional. A data frame or an unnamed list of named lists with item ID
  values (`.id`) and unique join values (`lookup_join_column`) for the
  lookup list items. If `NULL`, items are retrieved from `lookup_list`.

- join_column:

  Name of column (or record element) in `data` to match items to lookup
  list items. Defaults to `column_name`. Items without a matching lookup
  list item are not updated when `na_fields = "drop"`.

- lookup_join_column:

  Name of column (or record element) in `lookup_list_data` with values
  to match to `join_column` values. Defaults to `join_column`. For
  `fmt_sp_list_lookup_items()`, `lookup_join_column` must be length 1 or
  the same length as `column_name` and defaults to `column_name`.

- .id:

  Name of column (or record element) with item ID values in `data` and
  `lookup_list_data`. Defaults to "id".

- ignore_case:

  If `TRUE`, ignore case when matching join values. Defaults to `FALSE`.

- na_fields:

  How to handle `NA` fields in input data. One of `"drop"` (remove `NA`
  and empty fields, e.g. a multi-select value of `character(0)`, before
  updating list items, leaving existing values in place) or `"replace"`
  (overwrite existing list values with new replacement NA values or, for
  multi-value fields, an empty selection).

- .progress:

  Whether to show a progress bar. Use `TRUE` to turn on a basic progress
  bar, use a string to give it a name, or see
  [progress_bars](https://purrr.tidyverse.org/reference/progress_bars.html)
  for more details.

- user_column:

  Name of column (or record element) in `user_info_data` with values to
  match to `join_column` values. Defaults to `"EMail"`.

- user_info_data:

  Optional. A data frame or an unnamed list of named lists from the
  "User Information List" for the site. If `NULL`, items are retrieved
  with
  [`list_sp_site_user_info()`](https://elipousson.github.io/sharepointr/reference/list_sp_site_user_info.md)
  for the site of `sp_list`.

- allow_hidden:

  If `TRUE`, include users with `UserInfoHidden = TRUE` in the possible
  matches. Defaults to `FALSE`.

## Details

`create_sp_list_lookup_column()` is a wrapper for
[`create_lookup_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
and
[`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
that creates a lookup column in a list (`sp_list`) using a column from a
second list in the same site (the "lookup" list).
`create_sp_list_person_column()` is a wrapper for
[`create_person_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
and
[`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
that creates a person or group column.

`fmt_sp_list_lookup_items()` formats one or more lookup (or person or
group) columns in `data` by replacing the values with matching lookup
list item ID values and renaming the columns to
`"{column_name}LookupId"`. Use the output with
[`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
or
[`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md).

Values in `data` that can't be matched to a lookup list item are listed
in a message and replaced with `NA` values. Missing values are never
matched.
