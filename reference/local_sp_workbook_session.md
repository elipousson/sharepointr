# Use a workbook session until the calling function exits

**\[experimental\]**

## Usage

``` r
local_sp_workbook_session(
  x,
  ...,
  persist_changes = TRUE,
  .local_envir = caller_env(),
  call = caller_env()
)
```

## Arguments

- x:

  A SharePoint or OneDrive Excel workbook. Can be a `ms_drive_item`
  object, a SharePoint URL, or a path passed to
  [`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md).

- ...:

  Additional parameters passed to
  [`get_sp_item()`](https://elipousson.github.io/sharepointr/reference/get_sp_item.md)
  if `x` is not a `ms_drive_item` object.

- persist_changes:

  If `TRUE` (default), changes made in the session are saved to the
  workbook.

- .local_envir:

  The environment to use for scoping.

- call:

  The execution environment used in error messages. Defaults to the
  environment of the calling function.

## Value

The session ID, invisibly.

## Details

`local_sp_workbook_session()` creates a session and sets it as the
session for `x` so that it doesn't need to be passed to each function
with `session_id`. The session is closed, and the previous option value
restored, when the function it is called from exits. Wrap the code in
[`local()`](https://rdrr.io/r/base/eval.html) to limit the session when
working interactively.

The session is stored in the `sharepointr.workbook_session` option as a
character vector of session IDs named with the item ID of the workbook.
Since a session only works for one workbook, the session is only used
for requests to that workbook. An unnamed session ID in the option is
used for all workbooks.

## See also

Other workbooks:
[`sp_workbook`](https://elipousson.github.io/sharepointr/reference/sp_workbook.md),
[`sp_workbook_session_create()`](https://elipousson.github.io/sharepointr/reference/sp_workbook_session_create.md)

## Examples

``` r
sp_workbook_url <- "<SharePoint workbook url>"

if (is_sp_url(sp_workbook_url)) {
  local({
    local_sp_workbook_session(sp_workbook_url)
    sp_workbook_range_write(sp_workbook_url, data.frame(a = 1), "A1")
    sp_workbook_range_write(sp_workbook_url, data.frame(b = 2), "C1")
  })
}
```
