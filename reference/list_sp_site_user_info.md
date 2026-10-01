# List items from the hidden SharePoint "User Information List"

**\[experimental\]**

## Usage

``` r
list_sp_site_user_info(
  ...,
  sp_site = NULL,
  user_type = c("all", "visible"),
  filter = NULL,
  as_data_frame = TRUE,
  call = caller_env()
)
```

## Arguments

- ...:

  Additional parameters passed to
  [`get_sp_site()`](https://elipousson.github.io/sharepointr/reference/sp_site.md)
  if `sp_site` is not supplied.

- sp_site:

  A `ms_site` object.

- user_type:

  Type of users to return. "all" (default) returns all users and
  "visible" excludes users where `UserInfoHidden` is `TRUE`.

- filter:

  Optional. A filter query string passed to
  [`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md).
  If `user_type = "visible"`, `filter` is combined with a filter for
  visible users.

- as_data_frame:

  If `TRUE`, return a data frame with a "ms_list" column.
  [`get_sp_list()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  returns a 1 row data frame and
  [`list_sp_lists()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  returns a data frame with n rows or all lists available for the
  SharePoint site or drive. Defaults to `FALSE`. Ignored is
  `metadata = TRUE` as list metadata is always returned as a data frame.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Details

`list_sp_site_user_info()` lists users from the hidden "User Information
List" for a site. Use the results to match users to lookup ID values for
person or group columns with
[`fmt_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
or
[`update_sp_list_person_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md).
