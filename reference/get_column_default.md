# Get a column default value or formula

`get_column_default()` returns a formula or value or NULL. See
documentation for more information
<https://learn.microsoft.com/en-us/graph/api/resources/defaultcolumnvalue?view=graph-rest-1.0>

## Usage

``` r
get_column_default(value = NULL, formula = NULL, allow_null = TRUE)
```

## Arguments

- value:

  Value used as default value.

- formula:

  Formula used as default value.

- allow_null:

  If `TRUE`, return `NULL` if both `value` and `formula` are `NULL`.

## Examples

``` r
get_column_default("Missing")
#> $value
#> [1] "Missing"
#> 

get_column_default(formula = "=[Title]")
#> $formula
#> =[Title]
#> 
```
