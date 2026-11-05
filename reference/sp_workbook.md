# Read and write the cells of an Excel workbook

**\[experimental\]**

These functions use the [Excel REST
API](https://learn.microsoft.com/en-us/graph/excel-write-to-workbook) to
work with a workbook stored in SharePoint or OneDrive without
downloading and uploading the whole file. Changes are made to the live
workbook so edits by other people are not overwritten. The workbook must
be an `.xlsx` file.

- `sp_workbook_sheets()` lists the worksheets in a workbook.

- `sp_workbook_range_read()` reads a range (or the used range) of a
  worksheet into a data frame.

- `sp_workbook_range_write()` writes a data frame, matrix, or vector to
  a range.

Use
[`local_sp_workbook_session()`](https://elipousson.github.io/sharepointr/reference/local_sp_workbook_session.md)
to make several requests in one workbook session, or
[`sp_workbook_session_create()`](https://elipousson.github.io/sharepointr/reference/sp_workbook_session_create.md)
and
[`sp_workbook_session_close()`](https://elipousson.github.io/sharepointr/reference/sp_workbook_session_create.md)
to manage the session yourself.

## Usage

``` r
sp_workbook_sheets(x, ..., session_id = NULL, call = caller_env())

sp_workbook_range_read(
  x,
  range = NULL,
  ...,
  sheet = NULL,
  header = TRUE,
  session_id = NULL,
  call = caller_env()
)

sp_workbook_range_write(
  x,
  values,
  range = "A1",
  ...,
  sheet = NULL,
  col_names = TRUE,
  session_id = NULL,
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

- session_id:

  A workbook session ID from
  [`sp_workbook_session_create()`](https://elipousson.github.io/sharepointr/reference/sp_workbook_session_create.md).
  If `NULL` (default), the session for the workbook set by
  [`local_sp_workbook_session()`](https://elipousson.github.io/sharepointr/reference/local_sp_workbook_session.md)
  or the `sharepointr.workbook_session` option is used, if any.
  Otherwise the request is sent without a session.

- call:

  The execution environment used in error messages. Defaults to the
  environment of the calling function.

- range:

  A range in A1 notation (e.g. `"A1:C3"`). If `NULL`,
  `sp_workbook_range_read()` reads the used range of the worksheet. For
  `sp_workbook_range_write()`, `range` can be a single cell, which is
  expanded to fit `values`.

- sheet:

  Worksheet name or ID. If `NULL`, the first worksheet is used. A sheet
  name can also be included in `range` (e.g. `"Sheet1!A1:C3"`).

- header:

  If `TRUE` (default), the first row of the range is used for column
  names.

- values:

  A data frame, matrix, or vector. A vector is written as a single
  column. `NA` values are written as empty cells.

- col_names:

  If `TRUE` (default), the column names of a data frame (or matrix with
  column names) are written as the first row.

## Value

- `sp_workbook_sheets()`: A data frame with a row for each worksheet.

- `sp_workbook_range_read()`: A data frame.

- `sp_workbook_range_write()`: The address of the range written to,
  invisibly.

## Reading after writing

Requests sent without a session may not see each other's changes right
away. Writes are saved to the workbook, but a read sent without a
session straight afterward can return the earlier values for a short
time. To read back what you wrote, make the write and the read in the
same session (e.g. with
[`local_sp_workbook_session()`](https://elipousson.github.io/sharepointr/reference/local_sp_workbook_session.md)).
Requests in a session see the changes made in that session immediately.

## See also

Other workbooks:
[`local_sp_workbook_session()`](https://elipousson.github.io/sharepointr/reference/local_sp_workbook_session.md),
[`sp_workbook_session_create()`](https://elipousson.github.io/sharepointr/reference/sp_workbook_session_create.md)

## Examples

``` r
sp_workbook_url <- "<SharePoint workbook url>"

if (is_sp_url(sp_workbook_url)) {
  sp_workbook_sheets(sp_workbook_url)

  sp_workbook_range_read(sp_workbook_url, "A1:C10")
}
```
