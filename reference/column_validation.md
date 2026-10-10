# Create a column validation definition

`column_validation()` creates a columnValidation definition for the
`validation` property of a column definition. A validation formula must
evaluate to `TRUE` for a value to be saved.

## Usage

``` r
column_validation(formula, descriptions = NULL, default_language = "en-US")
```

## Arguments

- formula:

  Required. Validation formula. Reference columns with the display name
  enclosed in square brackets, e.g. `"=LEN([Title])<10"`. A leading
  `"="` is added if missing.

- descriptions:

  Optional message shown when validation fails. Either a string (used
  for `default_language`) or a named character vector with language tags
  as names, e.g. `c("en-US" = "Too long")`. Graph property:
  `descriptions`.

- default_language:

  Default BCP 47 language tag for `descriptions`. Graph property:
  `defaultLanguage`.

## Value

A named list formatted as a columnValidation resource.

## Details

The Graph API doesn't support creating or updating a list column with a
`validation` property, so
[`create_sp_list_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_column.md)
and
[`sync_sp_list()`](https://elipousson.github.io/sharepointr/reference/compare_sp_list.md)
apply validation with the SharePoint REST API instead. Validation isn't
returned when reading list columns with the Graph API, so it can't be
compared to an existing column.

## See also

[columnValidation resource
type](https://learn.microsoft.com/en-us/graph/api/resources/columnvalidation?view=graph-rest-1.0)

## Examples

``` r
column_validation("=LEN([Project Code])=8", "Use an 8 character code.")
#> $formula
#> [1] "=LEN([Project Code])=8"
#> 
#> $descriptions
#> $descriptions[[1]]
#> $descriptions[[1]]$languageTag
#> [1] "en-US"
#> 
#> $descriptions[[1]]$displayName
#> [1] "Use an 8 character code."
#> 
#> 
#> 
#> $defaultLanguage
#> [1] "en-US"
#> 
```
