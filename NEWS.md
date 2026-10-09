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
* Add `pull_sp_list_cols()` (internal) to get a named index of list columns from `get_sp_list_metadata()` output matching a column type (e.g. "lookup" or "choice"), a column property (e.g. "required" or "hidden"), or a `keep` value ("all", "editable", or "external"). Supports both data frame and list metadata; `get_sp_list_metadata()` now uses it to filter columns. (2026-09-24)
* Add support for updating list fields with multi-choice (checkbox) values — `update_sp_list_item()`/`create_sp_list_item()` now append @odata.type Collection hints so the Graph API accepts multi-value fields.
* Allow `delete_sp_list_item()`/`delete_sp_list_items()` to accept a data frame for `item_id` (uses its id column).
* Allow `update_sp_list_items()` to accept an unnamed list of named lists (one record per item, each with an `.id` element) as well as a data frame. Fields missing from a record are left unchanged. (2026-10-01)
* Allow `delete_sp_list_items()` to accept an unnamed list of named lists (one record per item) for `item_id`. Add a `.id` argument to `delete_sp_list_item()` and `delete_sp_list_items()` to set the id column or element name. (2026-10-01)
* Add `update_sp_list_person_items()` for updating person or group columns (matched by email address using the site "User Information List") and `fmt_sp_list_lookup_items()` for formatting lookup or person columns as "{column_name}LookupId" values. These replace `sp_user_id_as_lookup_id()` and `fmt_person_lookup_id_values()`. (2026-10-01)
* Add `create_sp_list_person_column()` (experimental) for creating person or group columns. (2026-10-01)
* Export `create_sp_list_lookup_column()`, `update_sp_list_lookup_items()`, `update_sp_list_person_items()`, `fmt_sp_list_lookup_items()`, and `list_sp_site_user_info()` as experimental functions (no longer internal). `create_sp_list_lookup_column()` and the update functions now use a consistent argument order (`data` first for update functions and `sp_list` first for create functions), `lookup_list` can be a `ms_list` object, list name, or list URL (and must be in the same site as `sp_list`), and the `sp_lookup_list` argument is removed. `update_sp_list_lookup_items()` and `fmt_sp_list_lookup_items()` accept a data frame or list of records, support a different join column name for the lookup list (`lookup_join_column`) and case-insensitive matching (`ignore_case`), and list any values that can't be matched. (2026-10-01)
* Add `user_type` and `filter` arguments to `list_sp_site_user_info()`. Use `user_type = "visible"` to exclude hidden users. (2026-10-01)
* Add a YAML format for SharePoint list definitions that uses Microsoft Graph list and columnDefinition property names (`displayName`, `description`, `list` for listInfo settings like `template`, and `columns`), with `custom` metadata (at the list or column level) passed through without validation. Read-only list properties (e.g. `id`, `webUrl`, `createdDateTime`, and `parentReference`) and column ids can be included as a reference to an existing list; they are never sent to SharePoint. `get_sp_list_definition()` and `write_sp_list_yaml()` include the stable read-only properties and column ids by default (`read_only = "stable"`). Add `read_sp_list_yaml()`, `write_sp_list_yaml()`, `get_sp_list_definition()`, `as_sp_list_definition()`, and `sp_list_definition_table()` (also used by an `as.data.frame()` method) as experimental functions. `write_sp_list_yaml()` keeps the comment header, `custom` metadata, and column order from an existing file. Requires `{yaml12}` (added to Suggests). (2026-10-09)
* Add `compare_sp_list_columns()` and `sync_sp_list_columns()` (experimental) to compare column definitions with an existing list and apply the changes. Only changed properties are sent. Changes the Graph API can't make (switching between single and multiple lines of text or single and multiple choice, and column validation) use the SharePoint REST API. Changes that may cause data loss are skipped unless `allow_data_loss = TRUE`, and changes that can't be made (e.g. changing the column type) are reported as blocked. (2026-10-09)
* Add `list_sp_list_views()`, `get_sp_list_view()`, `create_sp_list_view()`, `update_sp_list_view()`, and `delete_sp_list_view()` (experimental) for SharePoint list views. The Graph API doesn't support views, so these functions use the SharePoint REST API (with a delegated login) and the SP.View property names (e.g. `ViewFields`, `ViewQuery`, `RowLimit`). `update_sp_list_view()` only changes properties that differ from the existing view, and the default view can't be deleted. Add `{jsonlite}` to Imports for view formatting (`custom_formatter`). (2026-10-09)
* List definitions support an optional `views` key with SP.View properties. `create_sp_list(definition = )` creates the views (a view titled "All Items" updates the default view), and `get_sp_list_definition()` and `write_sp_list_yaml()` include views if `include_views = TRUE` (default `FALSE`). View formatting is written as a YAML mapping. Views aren't compared or synced by `compare_sp_list_columns()` or `sync_sp_list_columns()`. (2026-10-09)
* Add `as_column_definition()` to validate a column definition using Graph property names and `column_validation()` to create a column validation definition. (2026-10-09)
* `create_column_definition()` and the `create_*_column()` helpers now accept Graph property names passed to `...` (e.g. `allowMultipleLines = TRUE`) and validate all properties. Unknown properties are now an error instead of being added to the definition. (2026-10-09)
* Add a `definition` argument to `create_sp_list()` to create a list (name, description, template and other listInfo settings, and columns) from a definition or YAML file. A `Title` column updates the default title column, calculated columns are added after the list is created, and column validation is applied with the SharePoint REST API. `list_name` is now optional when `definition` is supplied. `create_sp_list_column()` also accepts definitions from `read_sp_list_yaml()`. (2026-10-09)
* `compare_sp_list_columns()` and `sync_sp_list_columns()` use a definition `id` and `parentReference.siteId` to get the list if `sp_list` isn't supplied, and error if the list `id` doesn't match the definition. They also compare and update the list `displayName`, `description`, `hidden`, and `contentTypesEnabled` settings. Formulas are compared after normalizing the changes SharePoint makes when saving a formula. (2026-10-09)

## Fixes

* Fix `update_sp_list_column()` sending the whole column definition: only properties that differ from the existing column are sent. (2026-10-09)
* Fix `create_number_column()` rejecting decimal `max` and `min` values. (2026-10-09)
* Fix `update_sp_list_items()` and `delete_sp_list_items()` handling of named lists: a single named list record (with an `.id` element) or a named list of records is now supported. Previously, `update_sp_list_items()` only sent the first field from a named list, and `delete_sp_list_items()` used every element of a named list as an item id. Other named lists now error. (2026-10-06)
* Fix `list_sp_list_items()` returning no items for a filtered query on a list with more than 5,000 items when the first page of results is empty. The Graph API evaluates these queries in batches, and an empty first page caused all later items to be dropped. (2026-10-05)
* Fix updates to multi-value lookup and person or group columns: `"{name}LookupId"` values are now sent as a `Collection(Edm.Int32)` (lookup ID values are often returned as strings). (2026-10-01)
* Fix `delete_sp_list_item()` erroring with a data frame `item_id` (the id value is now pulled from the data frame before checking arguments and getting the list item). (2026-10-01)
* Fix `update_sp_list_items()` validating fields again for every item: fields are now validated once per call, so `check_fields = FALSE` is respected, and list column metadata is requested once per call (and shared for field validation and identifying multi-value fields) instead of for each item. `create_sp_list_items()` also shares a single list column metadata request for field validation and identifying multi-value fields. (2026-10-01)
* Fix multi-select (multi-value) fields when creating or updating list items from a data frame with list-columns: `create_sp_list_items()`/`update_sp_list_items()` now unwrap list-column values, use list column definitions to send single or empty selections for multi-value columns as a Collection, and convert `sfc` columns to WKT for updates as well as creates. `na_fields = "drop"` now also drops empty values (e.g. `character(0)`) so existing values are left in place. (2026-10-01)
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
* Remove `{dplyr}` and `{tidyselect}` from Suggests by using `{vctrs}` to match items in `update_sp_list_lookup_items()`. (2026-10-01)
* The `create_*_column()` helpers no longer send default values for properties that aren't supplied, so SharePoint uses its own defaults. This changes the defaults for `hidden` (was `FALSE`), `text_type` (was `"plain"`), `allow_text` (was `TRUE`; SharePoint defaults to `FALSE`), `display_as` for choice (was `"dropDownMenu"`) and date columns (was `"default"`), `decimal_places` (was `"automatic"`), `format` for date columns (was `"dateOnly"`; `create_column_definition_list()` still uses `"dateOnly"` for a `"date"` type), `locale` (was `"en-us"`), and `allow_multiple_values` for term columns (was `TRUE`). (2026-10-09)
* Deprecate arguments to align with Graph property names: `displayname` (use `display_name`), `decimals` (use `decimal_places`), and `allow_multiple` (use `allow_multiple_values` for lookup and term columns or `allow_multiple_selection` for person or group columns). (2026-10-09)
* `create_calculated_column()` errors if `format` is supplied when `output_type` isn't `"dateTime"` (previously ignored) and returns the formula as a string. (2026-10-09)
* Document that the Graph API can't create hyperlink, picture, thumbnail, geolocation, or term columns on a list. (2026-10-09)

# sharepointr 0.1.0

* Initial version.
