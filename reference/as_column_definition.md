# Validate a column definition

`as_column_definition()` validates a named list of Microsoft Graph
columnDefinition properties, such as a column read from a YAML file with
[`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)
or returned by
[`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md).

A column definition must have a `name` and exactly one column type key
(e.g. `text`, `choice`, or `dateTime`) holding the properties for that
type. Property names must match the Graph API documentation. Unknown
properties and read-only properties (e.g. `type`) are errors. A column
`id` is allowed as a reference to an existing column but isn't used to
match, create, or update columns. A `custom` element is allowed and
isn't validated, so it can hold metadata used by other applications.

Formulas for calculated columns, default values, and validation have a
leading `"="` added if missing. Unlike
[`create_calculated_column()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md),
the formula isn't processed with
[`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).

## Usage

``` r
as_column_definition(x, ..., allow_custom = TRUE, call = caller_env())
```

## Arguments

- x:

  A named list of columnDefinition properties.

- ...:

  Must be empty.

- allow_custom:

  If `TRUE` (default), allow a `custom` element.

- call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

The validated column definition `x` with `choices` converted to a
character vector and formulas normalized.

## See also

- [columnDefinition resource
  type](https://learn.microsoft.com/en-us/graph/api/resources/columndefinition?view=graph-rest-1.0)

- [`read_sp_list_yaml()`](https://elipousson.github.io/sharepointr/reference/sp_list_definition.md)
  for the YAML format that uses these definitions.

## Examples

``` r
as_column_definition(
  list(
    name = "Notes",
    displayName = "Project Notes",
    text = list(allowMultipleLines = TRUE)
  )
)
#> $name
#> [1] "Notes"
#> 
#> $displayName
#> [1] "Project Notes"
#> 
#> $text
#> $text$allowMultipleLines
#> [1] TRUE
#> 
#> 
```
