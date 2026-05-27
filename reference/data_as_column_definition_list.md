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

## Details

Converting R data types to SharePoint column definitions

The type for each vector in the input data frame is checked with
[`vctrs::vec_ptype_abbr`](https://vctrs.r-lib.org/reference/vec_ptype_full.html)
and mapped to corresponding SharePoint list column definitions:

- factors are specified as choice columns

- integers are specified as number columns with `decimals` set to "none"

- characters with any value exceeding 255 characters have
  `multiple_lines` set to `TRUE`

- characters composed entirely of URL values are specified as hyperlink
  columns

- dates are specified as date columns

- dttm values are specified as datetime columns

- logical values are specified as boolean columns if they include no NA
  values or text columns if they do

All other vectors are specified as text columns. If the values of any
input factor column contain the same character specified with `split`
the choices will not be configured correctly.

## Examples

``` r
data_as_column_definition_list(mtcars)
#> [[1]]
#> [[1]]$name
#> [1] "mpg"
#> 
#> [[1]]$hidden
#> [1] FALSE
#> 
#> [[1]]$number
#> [[1]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "cyl"
#> 
#> [[2]]$hidden
#> [1] FALSE
#> 
#> [[2]]$number
#> [[2]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[3]]
#> [[3]]$name
#> [1] "disp"
#> 
#> [[3]]$hidden
#> [1] FALSE
#> 
#> [[3]]$number
#> [[3]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[4]]
#> [[4]]$name
#> [1] "hp"
#> 
#> [[4]]$hidden
#> [1] FALSE
#> 
#> [[4]]$number
#> [[4]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[5]]
#> [[5]]$name
#> [1] "drat"
#> 
#> [[5]]$hidden
#> [1] FALSE
#> 
#> [[5]]$number
#> [[5]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[6]]
#> [[6]]$name
#> [1] "wt"
#> 
#> [[6]]$hidden
#> [1] FALSE
#> 
#> [[6]]$number
#> [[6]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[7]]
#> [[7]]$name
#> [1] "qsec"
#> 
#> [[7]]$hidden
#> [1] FALSE
#> 
#> [[7]]$number
#> [[7]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[8]]
#> [[8]]$name
#> [1] "vs"
#> 
#> [[8]]$hidden
#> [1] FALSE
#> 
#> [[8]]$number
#> [[8]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[9]]
#> [[9]]$name
#> [1] "am"
#> 
#> [[9]]$hidden
#> [1] FALSE
#> 
#> [[9]]$number
#> [[9]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[10]]
#> [[10]]$name
#> [1] "gear"
#> 
#> [[10]]$hidden
#> [1] FALSE
#> 
#> [[10]]$number
#> [[10]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
#> [[11]]
#> [[11]]$name
#> [1] "carb"
#> 
#> [[11]]$hidden
#> [1] FALSE
#> 
#> [[11]]$number
#> [[11]]$number$decimalPlaces
#> [1] "automatic"
#> 
#> 
#> 
```
