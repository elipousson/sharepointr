# Create a new column definition based on an existing list

**\[experimental\]**

## Usage

``` r
copy_column_definition_list(sp_list = NULL, ..., keep = "visible")
```

## Arguments

- sp_list:

  A `ms_list` object or a data frame created by
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md).
  Optional if additional parameters are provided to `...` that can be
  used to get a SharePoint list to copy column definitions from.

- ...:

  Arguments passed on to
  [`get_sp_list_metadata`](https://elipousson.github.io/sharepointr/reference/sp_list.md)

  `list_name,list_id`

  :   SharePoint List name or ID string.

  `as_data_frame`

  :   If `TRUE`, return a data frame with a "ms_list" column.
      [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      returns a 1 row data frame and
      [`list_sp_lists()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      returns a data frame with n rows or all lists available for the
      SharePoint site or drive. Defaults to `FALSE`. Ignored is
      `metadata = TRUE` as list metadata is always returned as a data
      frame.

  `metadata`

  :   **\[deprecated\]** If `TRUE`,
      [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      applies the `get_column_info` method to the returned SharePoint
      list and returns a data frame with column metadata for the list.
      Use
      [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
      with `keep = "visible"` instead.

  `select`

  :   Optional character vector of columnDefinition properties to
      return, e.g. `c("name", "displayName")`, to reduce the size of the
      response. Must be one of the columnDefinition properties
      documented by the Graph API, including the column type properties
      such as "text" or "lookup". Properties required by `keep` are
      added: "hidden" for "all", "readOnly" for "editable", and "name"
      for "external". If `NULL` (default), the Graph API default
      properties are returned, except that `keep = "all"` requests every
      known columnDefinition property (and "hidden") because the API
      only returns hidden columns when a selection is made. A property
      that the package does not list is not returned by `keep = "all"`.

  `drive_name,drive_id`

  :   SharePoint Drive name or ID passed to `get_drive` method for
      SharePoint site object.

  `drive`

  :   A `ms_drive` object. If `drive` is supplied, `drive_name` and
      `drive_id` are ignored.

  `site_url`

  :   A SharePoint site URL in the format "https://\[tenant
      name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
      document URL can also be parsed to build a site URL using the
      tenant and site name included in the URL.

  `call`

  :   The execution environment of a currently running function, e.g.
      `caller_env()`. The function will be mentioned in error messages
      as the source of the error. See the `call` argument of
      [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
      information.

  `site`

  :   A `ms_site` object. If `site` is supplied, `site_url`,
      `site_name`, and `site_id` are ignored.

  `filter`

  :   A string with [an OData
      expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
      apply as a filter to the results. Learn more in the [Microsoft
      Graph API
      documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
      on using filter query parameters.

  `n`

  :   Maximum number of lists, plans, tasks, or other items to return.
      Defaults to `NULL` which sets n to `Inf`.

- keep:

  Passed to
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md).
  Defaults to "visible".

## Value

A list of named lists, each formatted as a columnDefinition (as created
by
[`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md))
for use as the `fields` argument to
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).

## Details

`copy_column_definition_list()` takes an existing SharePoint list and
uses the list metadata to create a column definition list that can be
used to create a new SharePoint list. Note: lookup columns retain the
original lookup list references so self-referencing lookup columns are
copied as lookup columns referencing the source list.
