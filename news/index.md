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

## sharepointr 0.1.0

- Initial version.
