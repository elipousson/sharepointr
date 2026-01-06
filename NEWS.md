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

## Fixes

* Fix bug where `get_sp_list_item()` only returned item ID, not the `Microsoft365R::ms_list_item` object (2024-08-10)
* Fix bug where `read_sharepoint()` used `readr::read_lines()` for PowerPoint files. (2024-10-10)

## Changes

* Revise `read_sharepoint()` to support zipped shapefiles. (2024-07-25)
* Improve printing of custom `.f` argument in `read_sharepoint()`. (2024-10-10)
* Alert users if input `data` is empty for `create_sp_list_items()`, `update_sp_list_items()` and error if input `item_id` is length 0 for `delete_sp_list_items()`. (2026-01-06)

# sharepointr 0.1.0

* Initial version.
