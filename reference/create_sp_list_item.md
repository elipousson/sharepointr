# Alternate syntax for create list item

`create_sp_list_item()` is an alternative to the `create_item` method
for
[`Microsoft365R::ms_list`](https://rdrr.io/pkg/Microsoft365R/man/ms_list.html)
objects. This is used by
[`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
(instead of the `bulk_import` method) to better handle NA values that
broken for number columns.

## Usage

``` r
create_sp_list_item(
  ...,
  .sp_list = NULL,
  .fields = NULL,
  .keep_na = FALSE,
  .multi_fields = NULL
)
```

## Arguments

- ...:

  Ignored if .fields is supplied.

- .sp_list:

  A `ms_list` object.

- .fields:

  A named list or single row data frame.

- .multi_fields:

  Optional. Names of multi-value (Collection) fields, such as
  multi-select choice columns, that should always be sent as an array
  with an `"@odata.type"` annotation. If `NULL`, only fields with a
  length other than 1 are treated as multi-value fields.
