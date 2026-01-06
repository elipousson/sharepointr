# Cache a `ms_object` class object to a file

Cache a `ms_object` class object to a file

## Usage

``` r
cache_ms_obj(
  x,
  cache_file,
  cache_dir = NULL,
  what = "ms_site",
  overwrite = FALSE,
  arg = caller_arg(x),
  call = caller_env()
)
```

## Arguments

- cache_file:

  File name for cached file. Required.

- cache_dir:

  Cache directory. By default, uses an option named
  "sharepointr.cache_dir". If "sharepointr.cache_dir" is not set, the
  cache directory is set to `rappdirs::user_cache_dir("sharepointr")`.

- overwrite:

  If `TRUE`, replace the existing cached object named by `cache_file`
  with the new object. If `FALSE`, error if a cached file with the same
  `cache_file` name already exists.
