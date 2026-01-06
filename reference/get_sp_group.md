# Get SharePoint group for a site or list group members

`get_sp_group()` gets the group associated with an individual site using
the `get_group` method. `list_sp_group_members()` lists members in the
group. Note that, as of February 1, 2024, the returned member data frame
when `as_data_frame = TRUE` contains a large number of list columns that
could be coerced into character columns. This should be addressed in a
later update.

## Usage

``` r
get_sp_group(
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  ...,
  site = NULL,
  call = caller_env()
)

list_sp_group_members(
  site_url = NULL,
  site_name = NULL,
  site_id = NULL,
  ...,
  as_data_frame = TRUE,
  call = caller_env()
)
```

## Arguments

- site_url:

  A SharePoint site URL in the format "https://\[tenant
  name\].sharepoint.com/sites/\[site name\]". Any SharePoint item or
  document URL can also be parsed to build a site URL using the tenant
  and site name included in the URL.

- site_name, site_id:

  Site name or ID of the SharePoint site as an alternative to the
  SharePoint site URL. Exactly one of `site_url`, `site_name`, and
  `site_id` must be supplied.

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  or
  [`Microsoft365R::get_sharepoint_site()`](https://rdrr.io/pkg/Microsoft365R/man/client.html).

- site:

  A `ms_site` object. If `site` is supplied, `site_url`, `site_name`,
  and `site_id` are ignored.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

- as_data_frame:

  If `TRUE` (default), converted list of members into a data frame with
  a list column named `az_user` that contains the member list and
  properties converted into columns.
