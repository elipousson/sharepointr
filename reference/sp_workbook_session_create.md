# Create or close a workbook session

**\[experimental\]**

## Usage

``` r
sp_workbook_session_create(x, ..., persist_changes = TRUE, call = caller_env())

sp_workbook_session_close(x, session_id, ..., call = caller_env())
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

- call:

  The execution environment used in error messages. Defaults to the
  environment of the calling function.

- session_id:

  A workbook session ID from `sp_workbook_session_create()`.

## Value

`sp_workbook_session_create()` returns a session ID.
`sp_workbook_session_close()` returns `x` invisibly.

## Details

Use a session to make several requests to a workbook. Requests without a
session are sent in a new temporary session by the API. If
`persist_changes = FALSE`, changes made in the session are discarded
when it is closed. A session that isn't closed expires after a few
minutes.

Requests in the same session see each other's changes immediately.
Requests sent without a session may not (see "Reading after writing" in
[sp_workbook](https://elipousson.github.io/sharepointr/reference/sp_workbook.md)).

## See also

Other workbooks:
[`local_sp_workbook_session()`](https://elipousson.github.io/sharepointr/reference/local_sp_workbook_session.md),
[`sp_workbook`](https://elipousson.github.io/sharepointr/reference/sp_workbook.md)
