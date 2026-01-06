# Convert a ms_obj object to a data frame of properties with a list column of objects

Convert a ms_obj object to a data frame of properties with a list column
of objects

## Usage

``` r
ms_obj_as_data_frame(
  ms_obj,
  obj_col = "ms_plan",
  recursive = FALSE,
  keep_list_cols = NULL,
  unlist_cols = TRUE,
  .name_repair = "universal_quiet",
  .error_call = caller_env()
)
```

## Arguments

- obj_col:

  Column name for list column with `ms_` objects. Defaults to
  `"ms_plan"`.

- keep_list_cols:

  Column names for those columns to maintain in a list format instead of
  attempting to convert to a character vector.
