# List or delete files from the AzureR configuration directory

`AzureR_config_ls()` uses
[`rappdirs::user_config_dir()`](https://rappdirs.r-lib.org/reference/user_data_dir.html)
and [`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html) to list
files from the AzureR configuration directory. `AzureR_config_delete()`
uses [`fs::file_delete()`](https://fs.r-lib.org/reference/delete.html)
to remove the "graph_logins.json" configuration file if needed. Use this
function with caution but it may be an option to address a "Unable to
refresh token" error.

## Usage

``` r
AzureR_config_ls(path = NULL, glob = "*.json")

AzureR_config_delete(path = NULL, filename = "graph_logins.json")
```

## Arguments

- path:

  Path to configuration directory for AzureR package where the JSON file
  for graph_logins is stored. If `NULL`, path is set with
  `rappdirs::user_config_dir("AzureR")`.

- glob:

  A wildcard aka globbing pattern (e.g. `*.csv`) passed on to
  [`grep()`](https://rdrr.io/r/base/grep.html) to filter paths.

- filename:

  Filename to delete from configuration directory. Defaults to
  "graph_logins.json". Set to `NULL` if path contains a file name.
