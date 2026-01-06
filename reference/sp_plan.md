# Get a SharePoint plan or list SharePoint plans

`get_sp_plan()` returns a single `ms_plan` object using the `get_plan`
method. `list_sp_plans()` returns a data frame with plan properties or a
list of `ms_plan` objects.

## Usage

``` r
get_sp_plan(
  plan_title = NULL,
  plan_id = NULL,
  ...,
  site = NULL,
  site_url = NULL,
  as_data_frame = FALSE,
  call = caller_env()
)

list_sp_plans(
  ...,
  filter = NULL,
  n = NULL,
  site = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)
```

## Arguments

- plan_title, plan_id:

  Planner title or ID. Exactly one of the two arguments must be
  supplied.

- ...:

  Additional arguments passed to
  [`get_sp_group()`](https://elipousson.github.io/sharepointr/reference/get_sp_group.md).

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- as_data_frame:

  If `TRUE` (default for `list_sp_plans()`), return a data frame with
  the plan title, id, creation date/time, and owner ID with a list
  column named "ms_plan" containing `ms_plan` objects. If `FALSE`
  (default `get_sp_plan()`), return a `ms_plan` object or list of
  `ms_plan` objects.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- filter:

  A string with [an OData
  expression](https://learn.microsoft.com/en-us/graph/query-parameters?tabs=http#filter-parameter)
  apply as a filter to the results. Learn more in the [Microsoft Graph
  API
  documentation](https://learn.microsoft.com/en-us/graph/filter-query-parameter)
  on using filter query parameters.

- n:

  Maximum number of lists, plans, tasks, or other items to return.
  Defaults to `NULL` which sets n to `Inf`.

## Value

For `get_sp_plan()`, a `ms_plan` class object or a 1 row data frame with
a "ms_plan" column.

For `list_sp_plans()`, A list of `ms_plan` class objects or a data frame
with a list column named "ms_plan".

## See also

[Microsoft365R::ms_plan](https://rdrr.io/pkg/Microsoft365R/man/ms_plan.html)
