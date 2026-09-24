# Pull a named index of list columns matching a column type

Find the columns described by list metadata from
[`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
that match a single type or property, e.g. all lookup columns or all
required columns. Pass the result to
[`vctrs::vec_slice()`](https://vctrs.r-lib.org/reference/vec_slice.html)
to subset `sp_list_meta`.

## Usage

``` r
pull_sp_list_cols(
  sp_list_meta,
  col_type = c("required", "hidden", "indexed", "readOnly", "boolean", "calculated",
    "choice", "contentApprovalStatus", "currency", "dateTime", "geolocation",
    "hyperlinkOrPicture", "lookup", "number", "personOrGroup", "term", "text",
    "thumbnail", "all", "editable", "external"),
  names_from = c("name", "displayName"),
  call = caller_env()
)
```

## Arguments

- sp_list_meta:

  List column metadata returned by
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md):
  either a data frame (`as_data_frame = TRUE`) or a list with one
  element per column (`as_data_frame = FALSE`).

- col_type:

  Column type or property to match:

  - "hidden", "indexed", "readOnly", or "required" match columns where
    the logical property of the same name is `TRUE` (`NA` is treated as
    `FALSE`).

  - A column type from `sp_list_col_types`, e.g. "text", "number", or
    "lookup", matches columns with the column type property (facet) of
    the same name. For data frame input, a column matches if the nested
    facet data frame has any non-missing value for that column.
    "boolean", "contentApprovalStatus", "geolocation", and "thumbnail"
    columns can only be identified from list input because these facets
    are empty objects ([`{}`](https://rdrr.io/r/base/Paren.html)) that
    are dropped when the API response is simplified to a data frame.

  - "all" matches every column.

  - "editable" matches columns where `readOnly` is not `TRUE`.

  - "external" matches columns with a name not in
    `sp_list_internal_colnames`.

- names_from:

  Property to use for names of the returned vector. One of "name"
  (default) or "displayName".

## Value

A named integer vector of positions in `sp_list_meta` for the matching
columns, named with the corresponding values of `names_from`. Returns a
zero-length named integer vector if no columns match or if
`sp_list_meta` lacks the metadata needed to identify `col_type`.
