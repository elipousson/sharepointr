# Convert a list definition to a data frame

**\[experimental\]**

`sp_list_definition_table()` converts a `sp_list_definition` object to a
data frame with one row per column. The
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) method
for `sp_list_definition` objects uses the same function.

The data frame has `list_name`, `name`, `displayName`, `description`,
and `type` columns followed by any other column-level properties, the
properties for each column type, and the `custom` metadata for each
column. Properties for column types aren't prefixed since each column
has a single column type. Properties with more than one value (e.g.
`choices`) are list columns and all other columns are simplified to
atomic vectors.

## Usage

``` r
sp_list_definition_table(x, custom = TRUE, custom_prefix = NULL)

# S3 method for class 'sp_list_definition'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  ...,
  custom = TRUE,
  custom_prefix = NULL
)
```

## Arguments

- x:

  A `sp_list_definition` object or a path to a YAML file.

- custom:

  If `TRUE` (default), include the `custom` metadata for each column.

- custom_prefix:

  Optional prefix added to the names of `custom` metadata columns. A
  `custom` key with the same name as a columnDefinition property is an
  error unless a prefix is supplied.

- row.names, optional, ...:

  Ignored.

## Value

A data frame with one row per column.

## Examples

``` r
path <- system.file("extdata", "example-list.yaml", package = "sharepointr")

sp_list_definition_table(path)
#>          list_name          name      displayName          description
#> 1 Example Projects         Title     Project Name                 <NA>
#> 2 Example Projects     ProjectID       Project ID Project reference ID
#> 3 Example Projects  ProjectNotes    Project Notes                 <NA>
#> 4 Example Projects ProjectStatus           Status                 <NA>
#> 5 Example Projects     StartDate       Start Date                 <NA>
#> 6 Example Projects        Budget           Budget                 <NA>
#> 7 Example Projects        Phases Number of Phases                 <NA>
#> 8 Example Projects      IsActive           Active                 <NA>
#> 9 Example Projects    BudgetText       Budget ($)                 <NA>
#>         type required enforceUniqueValues indexed maxLength form_order section
#> 1       text     TRUE                  NA      NA        NA         NA    <NA>
#> 2       text     TRUE                TRUE    TRUE        20          1 Summary
#> 3       text       NA                  NA      NA        NA          2 Summary
#> 4     choice       NA                  NA      NA        NA          3    <NA>
#> 5   dateTime       NA                  NA      NA        NA         NA    <NA>
#> 6   currency       NA                  NA      NA        NA         NA    <NA>
#> 7     number       NA                  NA      NA        NA         NA    <NA>
#> 8    boolean       NA                  NA      NA        NA         NA    <NA>
#> 9 calculated       NA                  NA      NA        NA         NA    <NA>
#>   allowMultipleLines                  choices    displayAs   format locale
#> 1                 NA                     NULL         <NA>     <NA>   <NA>
#> 2                 NA                     NULL         <NA>     <NA>   <NA>
#> 3               TRUE                     NULL         <NA>     <NA>   <NA>
#> 4                 NA Planning, Active, Closed radioButtons     <NA>   <NA>
#> 5                 NA                     NULL         <NA> dateOnly   <NA>
#> 6                 NA                     NULL         <NA>     <NA>  en-us
#> 7                 NA                     NULL         <NA>     <NA>   <NA>
#> 8                 NA                     NULL         <NA>     <NA>   <NA>
#> 9                 NA                     NULL         <NA>     <NA>   <NA>
#>   decimals decimalPlaces minimum                                        formula
#> 1     <NA>          <NA>      NA                                           <NA>
#> 2     <NA>          <NA>      NA                                           <NA>
#> 3     <NA>          <NA>      NA                                           <NA>
#> 4     <NA>          <NA>      NA                                           <NA>
#> 5     <NA>          <NA>      NA                                           <NA>
#> 6     none          <NA>      NA                                           <NA>
#> 7     <NA>          none       0                                           <NA>
#> 8     <NA>          <NA>      NA                                           <NA>
#> 9     <NA>          <NA>      NA =IF(ISBLANK([Budget]),"",USDOLLAR([Budget],0))
#>   outputType
#> 1       <NA>
#> 2       <NA>
#> 3       <NA>
#> 4       <NA>
#> 5       <NA>
#> 6       <NA>
#> 7       <NA>
#> 8       <NA>
#> 9       text
```
