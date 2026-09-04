# sharepointr (development version)

## Added

* Add `upload_sp_items()` function (2024-06-24).
* Add vignette for reading and writing items from SharePoint (#9; 2024-07-25).
* Add `update_sp_list_items()` function and refactor `update_sp_list_item()` to use `rlang::list2()` and `rlang::inject()` which adds support for data frame inputs. (2024-08-10)
* Add `display_nm` argument to `list_sp_list_items()` allowing use of list display names as labels or replacements for field names in results. (2024-08-10)
* Add `download_sp_list()` (2024-10-10).
* Add `create_column_definition()` and related functions for creating lists equivalent to columnDefinition objects. (2025-05-02)
* Add `update_sp_list()` for limited updates to Microsoft List metadata. (2025-07-24)
* Add `{purrr}` to imports to incorporate new `purrr::in_parallel()` function. Requires users have `{crate}` and `{mirai}` installed and set workers using `mirai::daemons()`. (2025-07-25)
* Add support for reading list items with `read_sharepoint()`. (2025-08-26)
* Add `delete_sp_list_item()` and `delete_sp_list_items()`. (2025-08-26)
* Add `copy_column_definition_list()` (2026-03-13)
* Add `update_sp_list_lookup_items()`. (2026-05-28)
* Add the `order_by` and `order_dir` arguments to `list_sp_list_items()`. (2026-06-05)
* Add support for `ms_drive_item` inputs for `dest` argument of `upload_sp_item()` and `upload_sp_items()`. (2026-06-12)
* Add support for updating list fields with multi-choice (checkbox) values — `update_sp_list_item()`/`create_sp_list_item()` now append @odata.type Collection hints so the Graph API accepts multi-value fields.
* Allow `delete_sp_list_item()`/`delete_sp_list_items()` to accept a data frame for `item_id` (uses its id column).

## Fixes

* Fix bug where `get_sp_list_item()` only returned item ID, not the `Microsoft365R::ms_list_item` object (2024-08-10)
* Fix bug where `read_sharepoint()` used `readr::read_lines()` for PowerPoint files. (2024-10-10)
* Fix `upload_sp_item()` overwrite check validating against the source filename instead of the actual destination filename when dest renames the file.
* Fix `sp_dir_info()` erroring (instead of warning) when `recurse = TRUE` and `type = "file"` are both supplied.
* Fix `sp_url_parse_path()` erroring on drive names containing regex metacharacters (e.g. parentheses) by matching the drive name as a fixed string instead of interpolating it unescaped into a regex.
* Fix `list_sp_tasks()`/`get_sp_task()` erroring when combining Planner tasks whose properties (e.g. `dueDateTime`, `appliedCategories`) are missing for some tasks but present for others, by no longer forcing a placeholder type for missing properties and by keeping dictionary-typed properties (`assignments`, `appliedCategories`) as consistent list columns. Also fixes a related crash in `list_sp_group_members()` for group members entirely missing an expected property.

## Changes

* Revise `read_sharepoint()` to support zipped shapefiles. (2024-07-25)
* Improve printing of custom `.f` argument in `read_sharepoint()`. (2024-10-10)
* Alert users if input `data` is empty for `create_sp_list_items()`, `update_sp_list_items()` and error if input `item_id` is length 0 for `delete_sp_list_items()`. (2026-01-06)
* Improve handling of `sf` data inputs for `create_sp_list_items()` (2026-05-27).
* Add `{httr}` and `{AzureGraph}` to Imports to re-implement an internal version of the `list_items` method for `Microsoft365R::ms_list` objects. (2026-06-05)
* Add `{dplyr}` and `{tidyselect}` to Suggests in support of the `update_sp_list_lookup_items()` function. (2026-09-04)

# sharepointr 0.1.0

* Initial version.
