# Create SharePoint list lookup column

`create_sp_list_lookup_column()` is a wrapper for
[`create_lookup_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
and
[`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
that allows for the creation of a column in one list (the "lookup" list)
and then create a lookup column in a second list.

## Usage

``` r
create_sp_list_lookup_column(
  column_name,
  sp_list = NULL,
  sp_lookup_list,
  lookup_list_column = column_name,
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  ...
)
```

## Arguments

- sp_list:

  A `ms_list` object. If supplied, `list_name`, `site`, and `site_url`
  are all ignored.

- lookup_list_column:

  Name of lookup column in the lookup list to use.

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

- ...:

  Arguments passed on to
  [`create_lookup_column`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)

  `allow_multiple`

  :   If `TRUE`, allow lookup column to return multiple values.

  `allow_unlimited_length`

  :   If `TRUE`, allow lookup column to return any length value.

  `primary_lookup_column_id`

  :   If column definition is for a secondary column, the primary lookup
      column ID must be supplied.
