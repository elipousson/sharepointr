# Convert a data frame to a column definition list

`data_as_column_definition_list()` is used to create a column definition
list based on an existing data frame.

## Usage

``` r
data_as_column_definition_list(data, ..., split = "|", ignore_na = TRUE)
```

## Arguments

- data:

  A data frame input. Column types are used to infer the appropriate
  Microsoft Lists column definition.

- ...:

  Ignored.

- split:

  character vector (or object which can be coerced to such) containing
  [regular expression](https://rdrr.io/r/base/regex.html)(s) (unless
  `fixed = TRUE`) to use for splitting. If empty matches occur, in
  particular if `split` has length 0, `x` is split into single
  characters. If `split` has length greater than 1, it is re-cycled
  along `x`.

- ignore_na:

  If `TRUE`, drop any parameters with a `NA` value.

## Examples

``` r
data_as_column_definition_list(mtcars)
#> Error in purrr::map_chr(data, function(x) {    type <- switch(vctrs::vec_ptype_abbr(x), chr = "text", fct = "choice",         dbl = "number", int = "number", lgl = "boolean", date = "date",         dttm = "datetime", "text")    if (all(is_url(x) | is.na(x))) {        type <- "hyperlink"    }}): ℹ In index: 1.
#> ℹ With name: mpg.
#> Caused by error:
#> ! Result must be length 1, not 0.
```
