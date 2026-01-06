# Create, update, and delete SharePoint list columns

`create_sp_list_column()` adds a column to a SharePoint list and
`delete_sp_list_column()` removes a column to a SharePoint list.
`update_sp_list_column()` updates a column definition for an existing
column in a SharePoint list (but is not yet implemented).

## Usage

``` r
create_sp_list_column(
  sp_list = NULL,
  ...,
  column_name = NULL,
  column_definition = NULL,
  list_name = NULL,
  site = NULL,
  site_url = NULL
)

update_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  column_definition = NULL,
  column_name_type = "name"
)

delete_sp_list_column(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  list_name = NULL,
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

- column_name, column_id:

  Column ID for column to delete.

- column_definition:

  List with column definition created with
  [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  or a related function. Optional if `column_name` and any required
  additional parameters are provided.

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

- column_name_type:

  "name" or "displayName". Used to match column ID so column_name must
  be unique if `column_name_type = "displayName"`.

## Details

See documentation:
<https://learn.microsoft.com/en-us/graph/api/list-post-columns?view=graph-rest-1.0&tabs=http>
