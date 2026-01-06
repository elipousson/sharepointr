# Create a list of column definitions

`create_column_definition_list()` is a vectorized version of
[`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
that uses a list or data frame input to create a list of column
definitions. This list can be used as the `fields` argument for
[`create_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md).

## Usage

``` r
create_column_definition_list(definitions, col_type = "text", ignore_na = TRUE)
```

## Arguments

- definitions:

  A list or data frame with arguments to use in creation of column
  definitions.

- col_type:

  Column type to use if not provided as a "type" column in the input
  definitions data frame. Allowed values include date and datetime,
  person, group, and personorgroup. Not case sensitive.

- ignore_na:

  If `TRUE`, drop any parameters with a `NA` value.

## Examples

``` r
definition_df <- data.frame(
  name = c("FirstColumn", "SecondColumn"),
  type = c("text", "number"),
  decimals = c(NA, 0),
  multiple_lines = c(TRUE, NA)
)

create_column_definition_list(definition_df)
#> [[1]]
#> [[1]]$name
#> [1] "FirstColumn"
#> 
#> [[1]]$hidden
#> [1] FALSE
#> 
#> [[1]]$text
#> [[1]]$text$allowMultipleLines
#> [1] TRUE
#> 
#> [[1]]$text$textType
#> [1] "plain"
#> 
#> 
#> 
#> [[2]]
#> [[2]]$name
#> [1] "SecondColumn"
#> 
#> [[2]]$hidden
#> [1] FALSE
#> 
#> [[2]]$number
#> [[2]]$number$decimalPlaces
#> [1] "none"
#> 
#> 
#> 
```
