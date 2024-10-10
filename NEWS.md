# sharepointr (development version)

## Added

* Add `upload_sp_items()` function (2024-06-24).
* Add vignette for reading and writing items from SharePoint (#9; 2024-07-25).
* Add `update_sp_list_items()` function and refactor `update_sp_list_item()` to use `rlang::list2()` and `rlang::inject()` which adds support for data frame inputs. (2024-08-10)
* Add `display_nm` argument to `list_sp_list_items()` allowing use of list display names as labels or replacements for field names in results. (2024-08-10)
* Add `download_sp_list()` (2024-10-10).

## Fixes

* Fix bug where `get_sp_list_item()` only returned item ID, not the `Microsoft365R::ms_list_item` object (2024-08-10)
* Fix bug where `read_sharepoint()` used `readr::read_lines()` for PowerPoint files. (2024-10-10)

## Changes

* Revise `read_sharepoint()` to support zipped shapefiles. (2024-07-25)
* Improve printing of custom `.f` argument in `read_sharepoint()`. (2024-10-10)

# sharepointr 0.1.0

* Initial version.
