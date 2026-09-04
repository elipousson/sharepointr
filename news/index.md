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
- Add support for updating list fields with multi-choice (checkbox)
  values —
  [`update_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_items.md)/[`create_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/create_sp_list_item.md)
  now append [@odata](https://github.com/odata).type Collection hints so
  the Graph API accepts multi-value fields.
- Allow
  [`delete_sp_list_item()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)/[`delete_sp_list_items()`](https://elipousson.github.io/sharepointr/reference/delete_sp_list_item.md)
  to accept a data frame for `item_id` (uses its id column).

### Fixes

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

## sharepointr 0.1.0

- Initial version.
