# Convert a data frame to a column definition list

`data_as_column_definition_list()` is used to create a column definition
list based on an existing data frame. This function is used internally
by
[`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
when `create_list = TRUE`.

## Usage

``` r
data_as_column_definition_list(
  data,
  ...,
  split = "|",
  ignore_na = TRUE,
  definitions_as = c("definition_list", "table")
)
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

- definitions_as:

  If `"definition_list"` (default) return named list output from
  [`create_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/create_column_definition_list.md).
  If `"table"` return a dataframe with the column names and types.

## Value

If `definitions_as = "definition_list"` (default), a list of named lists
formatted as columnDefinitions for use as the `fields` argument to
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).
If `definitions_as = "table"`, a data frame with one row per column of
`data` describing the inferred name, type, and other definition
properties.

## Details

Converting R data types to SharePoint column definitions

The type for each vector in the input data frame is checked with
[`vctrs::vec_ptype_abbr`](https://vctrs.r-lib.org/reference/vec_ptype_full.html)
and mapped to corresponding SharePoint list column definitions:

- factors are specified as choice columns

- integers are specified as number columns with `decimal_places` set to
  "none"

- characters with any value exceeding 255 characters have
  `multiple_lines` set to `TRUE`

- characters composed entirely of URL values are specified as hyperlink
  columns

- dates are specified as date columns

- dttm values are specified as datetime columns

- logical values are specified as boolean columns if they include no NA
  values or text columns if they do

All other vectors are specified as text columns. If the levels of any
input factor column contain the character specified with `split`, this
function errors.

## Examples

``` r
data_as_column_definition_list(mtcars)
#> [[1]]
#> [[1]]$name
#> [1] "mpg"
#> 
#> [[1]]$number
#> named list()
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "cyl"
#> 
#> [[2]]$number
#> named list()
#> 
#> 
#> [[3]]
#> [[3]]$name
#> [1] "disp"
#> 
#> [[3]]$number
#> named list()
#> 
#> 
#> [[4]]
#> [[4]]$name
#> [1] "hp"
#> 
#> [[4]]$number
#> named list()
#> 
#> 
#> [[5]]
#> [[5]]$name
#> [1] "drat"
#> 
#> [[5]]$number
#> named list()
#> 
#> 
#> [[6]]
#> [[6]]$name
#> [1] "wt"
#> 
#> [[6]]$number
#> named list()
#> 
#> 
#> [[7]]
#> [[7]]$name
#> [1] "qsec"
#> 
#> [[7]]$number
#> named list()
#> 
#> 
#> [[8]]
#> [[8]]$name
#> [1] "vs"
#> 
#> [[8]]$number
#> named list()
#> 
#> 
#> [[9]]
#> [[9]]$name
#> [1] "am"
#> 
#> [[9]]$number
#> named list()
#> 
#> 
#> [[10]]
#> [[10]]$name
#> [1] "gear"
#> 
#> [[10]]$number
#> named list()
#> 
#> 
#> [[11]]
#> [[11]]$name
#> [1] "carb"
#> 
#> [[11]]$number
#> named list()
#> 
#> 
```
