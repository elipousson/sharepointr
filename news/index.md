# Changelog

## sharepointr (development version)

### Added

- Add
  [`upload_sp_items()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
  function (2024-06-24).
- Add vignette for reading and writing items from SharePoint
  ([\#9](https://github.com/elipousson/sharepointr/issues/9);
  2024-07-25).
- Add
  [`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  function and refactor
  [`update_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  to use
  [`rlang::list2()`](https://rlang.r-lib.org/reference/list2.html) and
  [`rlang::inject()`](https://rlang.r-lib.org/reference/inject.html)
  which adds support for data frame inputs. (2024-08-10)
- Add `display_nm` argument to
  [`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)
  allowing use of list display names as labels or replacements for field
  names in results. (2024-08-10)
- Add
  [`download_sp_list()`](https://elipousson.github.io/sharepointr/reference/download_sp_list.md)
  (2024-10-10).
- Add
  [`create_column_definition()`](https://elipousson.github.io/sharepointr/reference/create_column_definition.md)
  and related functions for creating lists equivalent to
  columnDefinition objects. (2025-05-02)
- Add
  [`update_sp_list()`](https://elipousson.github.io/sharepointr/reference/create_sp_list.md)
  for limited updates to Microsoft List metadata. (2025-07-24)
- Add [purrr](https://purrr.tidyverse.org/) to imports to incorporate
  new
  [`purrr::in_parallel()`](https://purrr.tidyverse.org/reference/in_parallel.html)
  function. Requires users have `{crate}` and
  [mirai](https://mirai.r-lib.org) installed and set workers using
  `mirai::daemons()`. (2025-07-25)
- Add support for reading list items with
  [`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md).
  (2025-08-26)
- Add
  [`delete_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  and
  [`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md).
  (2025-08-26)
- Add
  [`copy_column_definition_list()`](https://elipousson.github.io/sharepointr/reference/copy_column_definition_list.md)
  (2026-03-13)
- Add
  [`update_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md).
  (2026-05-28)
- Add the `order_by` and `order_dir` arguments to
  [`list_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md).
  (2026-06-05)
- Add support for `ms_drive_item` inputs for `dest` argument of
  [`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
  and
  [`upload_sp_items()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md).
  (2026-06-12)
- Add
  [`pull_sp_list_cols()`](https://elipousson.github.io/sharepointr/reference/pull_sp_list_cols.md)
  (internal) to get a named index of list columns from
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  output matching a column type (e.g. “lookup” or “choice”), a column
  property (e.g. “required” or “hidden”), or a `keep` value (“all”,
  “editable”, or “external”). Supports both data frame and list
  metadata;
  [`get_sp_list_metadata()`](https://elipousson.github.io/sharepointr/reference/sp_list.md)
  now uses it to filter columns. (2026-09-24)
- Add support for updating list fields with multi-choice (checkbox)
  values —
  [`update_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)/[`create_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_item.md)
  now append [@odata](https://github.com/odata).type Collection hints so
  the Graph API accepts multi-value fields.
- Allow
  [`delete_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)/[`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  to accept a data frame for `item_id` (uses its id column).
- Allow
  [`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  to accept an unnamed list of named lists (one record per item, each
  with an `.id` element) as well as a data frame. Fields missing from a
  record are left unchanged. (2026-10-01)
- Allow
  [`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  to accept an unnamed list of named lists (one record per item) for
  `item_id`. Add a `.id` argument to
  [`delete_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  and
  [`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  to set the id column or element name. (2026-10-01)
- Add
  [`update_sp_list_person_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  for updating person or group columns (matched by email address using
  the site “User Information List”) and
  [`fmt_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  for formatting lookup or person columns as “{column_name}LookupId”
  values. These replace `sp_user_id_as_lookup_id()` and
  `fmt_person_lookup_id_values()`. (2026-10-01)
- Add
  [`create_sp_list_person_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  (experimental) for creating person or group columns. (2026-10-01)
- Export
  [`create_sp_list_lookup_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md),
  [`update_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md),
  [`update_sp_list_person_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md),
  [`fmt_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md),
  and
  [`list_sp_site_user_info()`](https://elipousson.github.io/sharepointr/reference/list_sp_site_user_info.md)
  as experimental functions (no longer internal).
  [`create_sp_list_lookup_column()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  and the update functions now use a consistent argument order (`data`
  first for update functions and `sp_list` first for create functions),
  `lookup_list` can be a `ms_list` object, list name, or list URL (and
  must be in the same site as `sp_list`), and the `sp_lookup_list`
  argument is removed.
  [`update_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  and
  [`fmt_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  accept a data frame or list of records, support a different join
  column name for the lookup list (`lookup_join_column`) and
  case-insensitive matching (`ignore_case`), and list any values that
  can’t be matched. (2026-10-01)
- Add `user_type` and `filter` arguments to
  [`list_sp_site_user_info()`](https://elipousson.github.io/sharepointr/reference/list_sp_site_user_info.md).
  Use `user_type = "visible"` to exclude hidden users. (2026-10-01)

### Fixes

- Fix updates to multi-value lookup and person or group columns:
  `"{name}LookupId"` values are now sent as a `Collection(Edm.Int32)`
  (lookup ID values are often returned as strings). (2026-10-01)
- Fix
  [`delete_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  erroring with a data frame `item_id` (the id value is now pulled from
  the data frame before checking arguments and getting the list item).
  (2026-10-01)
- Fix
  [`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  validating fields again for every item: fields are now validated once
  per call, so `check_fields = FALSE` is respected, and list column
  metadata is requested once per call (and shared for field validation
  and identifying multi-value fields) instead of for each item.
  [`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  also shares a single list column metadata request for field validation
  and identifying multi-value fields. (2026-10-01)
- Fix multi-select (multi-value) fields when creating or updating list
  items from a data frame with list-columns:
  [`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)/[`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  now unwrap list-column values, use list column definitions to send
  single or empty selections for multi-value columns as a Collection,
  and convert `sfc` columns to WKT for updates as well as creates.
  `na_fields = "drop"` now also drops empty values (e.g. `character(0)`)
  so existing values are left in place. (2026-10-01)
- Fix bug where
  [`get_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/sp_list_item.md)
  only returned item ID, not the
  [`Microsoft365R::ms_list_item`](https://rdrr.io/pkg/Microsoft365R/man/ms_list_item.html)
  object (2024-08-10)
- Fix bug where
  [`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
  used
  [`readr::read_lines()`](https://readr.tidyverse.org/reference/read_lines.html)
  for PowerPoint files. (2024-10-10)
- Fix
  [`upload_sp_item()`](https://elipousson.github.io/sharepointr/reference/upload_sp_item.md)
  overwrite check validating against the source filename instead of the
  actual destination filename when dest renames the file.
- Fix
  [`sp_dir_info()`](https://elipousson.github.io/sharepointr/reference/sp_dir_info.md)
  erroring (instead of warning) when `recurse = TRUE` and
  `type = "file"` are both supplied.
- Fix
  [`sp_url_parse_path()`](https://elipousson.github.io/sharepointr/reference/sp_url_parse.md)
  erroring on drive names containing regex metacharacters
  (e.g. parentheses) by matching the drive name as a fixed string
  instead of interpolating it unescaped into a regex.
- Fix
  [`list_sp_tasks()`](https://elipousson.github.io/sharepointr/reference/sp_tasks.md)/[`get_sp_task()`](https://elipousson.github.io/sharepointr/reference/sp_tasks.md)
  erroring when combining Planner tasks whose properties
  (e.g. `dueDateTime`, `appliedCategories`) are missing for some tasks
  but present for others, by no longer forcing a placeholder type for
  missing properties and by keeping dictionary-typed properties
  (`assignments`, `appliedCategories`) as consistent list columns. Also
  fixes a related crash in
  [`list_sp_group_members()`](https://elipousson.github.io/sharepointr/reference/get_sp_group.md)
  for group members entirely missing an expected property.

### Changes

- Revise
  [`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md)
  to support zipped shapefiles. (2024-07-25)
- Improve printing of custom `.f` argument in
  [`read_sharepoint()`](https://elipousson.github.io/sharepointr/reference/read_sharepoint.md).
  (2024-10-10)
- Alert users if input `data` is empty for
  [`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md),
  [`update_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  and error if input `item_id` is length 0 for
  [`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md).
  (2026-01-06)
- Improve handling of `sf` data inputs for
  [`create_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)
  (2026-05-27).
- Add [httr](https://httr.r-lib.org/) and
  [AzureGraph](https://github.com/Azure/AzureGraph) to Imports to
  re-implement an internal version of the `list_items` method for
  [`Microsoft365R::ms_list`](https://rdrr.io/pkg/Microsoft365R/man/ms_list.html)
  objects. (2026-06-05)
- Add [dplyr](https://dplyr.tidyverse.org) and
  [tidyselect](https://tidyselect.r-lib.org) to Suggests in support of
  the
  [`update_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md)
  function. (2026-09-04)
- Remove [dplyr](https://dplyr.tidyverse.org) and
  [tidyselect](https://tidyselect.r-lib.org) from Suggests by using
  [vctrs](https://vctrs.r-lib.org/) to match items in
  [`update_sp_list_lookup_items()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_lookup_column.md).
  (2026-10-01)

## sharepointr 0.1.0

- Initial version.
