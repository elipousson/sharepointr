# Convert a ms_obj object to a data frame of properties with a list column of objects

Convert a ms_obj object to a data frame of properties with a list column
of objects

## Usage

``` r
ms_obj_as_data_frame(
  ms_obj,
  obj_col = "ms_plan",
  keep_list_cols = NULL,
  unlist_cols = TRUE,
  .name_repair = "universal_quiet",
  .error_call = caller_env()
)
```

## Arguments

- ms_obj:

  A object with a 'ms_object" class.

- obj_col:

  Column name for list column with `ms_` objects. Defaults to
  `"ms_plan"`.

- keep_list_cols:

  Column names for those columns to maintain in a list format instead of
  attempting to convert to a character vector.

- unlist_cols:

  If `TRUE` (default), convert list columns to vectors.

- .name_repair:

  One of `"unique"`, `"universal"`, `"check_unique"`, `"unique_quiet"`,
  or `"universal_quiet"`. See
  [`vec_as_names()`](https://vctrs.r-lib.org/reference/vec_as_names.html)
  for the meaning of these options.

  With `vec_rbind()`, the repair function is applied to all inputs
  separately. This is because `vec_rbind()` needs to align their columns
  before binding the rows, and thus needs all inputs to have unique
  names. On the other hand, `vec_cbind()` applies the repair function
  after all inputs have been concatenated together in a final data
  frame. Hence `vec_cbind()` allows the more permissive minimal names
  repair.

- .error_call:

  The execution environment of a currently running function, e.g.
  `caller_env()`. The function will be mentioned in error messages as
  the source of the error. See the `call` argument of
  [`abort()`](https://rlang.r-lib.org/reference/abort.html) for more
  information.

## Value

A 1 row data frame with one column per scalar property of `ms_obj`, plus
a list column named `obj_col` containing `ms_obj` itself.
