# Convert a vector of user identifiers to lookup ID values (or another type of identifier) using the hidden SharePoint "User Information List"

Convert a vector of user identifiers to lookup ID values (or another
type of identifier) using the hidden SharePoint "User Information List"

## Usage

``` r
sp_user_id_as_lookup_id(
  users,
  ...,
  user_info_list = NULL,
  users_id = "EMail",
  lookup_id = "id",
  allow_hidden = FALSE
)
```

## Arguments

- users:

  A character vector of email addresses (or another identifier as
  specified by `users_id`). Not case sensitive.

- user_info_list:

  Data frame from "User Information List". Typically, created with
  [`list_sp_site_user_info()`](https://elipousson.github.io/sharepointr/reference/list_sp_site_user_info.md).
  @param ... Parameters passed to
  [`list_sp_site_user_info()`](https://elipousson.github.io/sharepointr/reference/list_sp_site_user_info.md)
  if `user_info_list` is not supplied.

- users_id:

  Type of `users` vector to expect as input. Defaults to `"EMail"`.

- lookup_id:

  Type of lookup ID value to return. Defaults to `"id"`.

- allow_hidden:

  If `TRUE`, include users with `UserInfoHidden = TRUE` in the possible
  results. Defaults to `FALSE`.
