#' Get drive or site for list
#'
#' @noRd
get_ms_list_obj <- function(
  list_name = NULL,
  list_id = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  get_sp_drive_obj <- any(c(
    !is.null(drive),
    !is.null(drive_name) && !identical(drive_name, "Lists"),
    !is.null(drive_id)
  ))

  if (get_sp_drive_obj) {
    drive <- drive %||%
      get_sp_drive(
        drive_name = drive_name,
        drive_id = drive_id,
        ...,
        properties = FALSE,
        site = site,
        site_url = site_url,
        call = call
      )

    check_ms_drive(drive, call = call)

    return(drive)
  }

  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

  check_ms_site(site, call = call)

  site
}

#' Get a SharePoint list or a list of SharePoint lists
#'
#' [get_sp_list()] is a wrapper for the `get_list` and `list_items` methods.
#' This function is still under development and does not support the URL parsing
#' used by [get_sp_item()]. [list_sp_lists()] returns all lists for a SharePoint
#' site or drive as a list or data frame. Note, when using `filter` with
#' [get_sp_list()], names used in the expression must be prefixed with "fields/"
#' to distinguish them from item metadata.
#'
#' @inheritParams get_sp_drive
#' @inheritParams get_sp_item
#' @inheritDotParams get_sp_drive -drive_name -drive_id -properties
#' @seealso
#' - [Microsoft365R::ms_list]
#' - [Microsoft365R::ms_list_item]
#' - [create_sp_list()]; [delete_sp_list()]
#' @name sp_list
NULL

#' @rdname sp_list
#' @name get_sp_list
#' @param list_name,list_id SharePoint List name or ID string.
#' @param as_data_frame If `TRUE`, return a data frame with a "ms_list" column.
#'   [get_sp_list()] returns a 1 row data frame and [list_sp_lists()] returns a
#'   data frame with n rows or all lists available for the SharePoint site or
#'   drive. Defaults to `FALSE`. Ignored is `metadata = TRUE` as list metadata
#'   is always returned as a data frame.
#' @param metadata If `TRUE`, [get_sp_list()] applies the `get_column_info`
#'   method to the returned SharePoint list and returns a data frame with column
#'   metadata for the list.
#' @returns A data frame `as_data_frame = TRUE` or a `ms_list` object (or list
#'   of `ms_list` objects) if `FALSE`.
#' @keywords lists
#' @export
get_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  metadata = FALSE,
  as_data_frame = FALSE,
  call = caller_env()
) {
  # FIXME: URL parsing is not set up for links to SharePoint lists
  if (is_url(list_name)) {
    url <- list_name
    list_name <- NULL

    check_sp_list_url(url, call = call)

    sp_url_parts <- sp_url_parse(
      url = url,
      call = call
    )

    # FIXME: Parsing the drive_name for lists does not typically work
    drive_name <- drive_name %||% sp_url_parts[["drive_name"]]

    if (is_null(list_id) && is_null(sp_url_parts[["item_id"]])) {
      list_name <- sp_url_parts[["list_name"]] %||% sp_url_parts[["file"]]
    }

    list_id <- list_id %||% sp_url_parts[["item_id"]]
    site_url <- site_url %||% sp_url_parts[["site_url"]]
  }

  ms_list_obj <- get_ms_list_obj(
    list_name = list_name,
    list_id = list_id,
    ...,
    site_url = site_url,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  check_exclusive_strings(list_name, list_id, call = call)

  hidden_lists <- c("User Information List")

  if (!is.null(list_name) && !(list_name %in% hidden_lists)) {
    # FIXME: This is a work around to handle lists that have been renamed

    if (is_ms_site(ms_list_obj)) {
      sp_lists <- list_sp_lists(
        site = ms_list_obj,
        as_data_frame = FALSE,
        call = call
      )
    } else if (is_ms_drive(ms_list_obj)) {
      sp_lists <- list_sp_lists(
        drive = ms_list_obj,
        as_data_frame = FALSE,
        call = call
      )
    } else {
      # TODO: Add handling for displayName validation
      sp_lists <- list_sp_lists(
        ...,
        site_url = site_url,
        site = site,
        drive_name = drive_name,
        drive_id = drive_id,
        as_data_frame = FALSE,
        drive = drive,
        call = call
      )
    }

    sp_list_id_pairs <- purrr::map(
      sp_lists,
      \(x) {
        list(
          name = x$properties$name,
          id = x$properties$id
        )
      }
    )

    nm_values <- purrr::map_chr(
      sp_list_id_pairs,
      \(x) {
        x[["name"]]
      }
    )

    list_name <- arg_match(list_name, values = nm_values, error_call = call)

    list_ids <- purrr::map_chr(
      sp_list_id_pairs,
      \(x) {
        x[["id"]]
      }
    )

    list_id <- list_ids[nm_values == list_name]
    list_name <- NULL
  }

  cli::cli_progress_step(
    "Getting list from SharePoint"
  )

  sp_list <- ms_list_obj$get_list(
    list_name = list_name,
    list_id = list_id
  )

  # TODO: Consider removing the metadata argument
  if (metadata) {
    if (!as_data_frame) {
      cli_warn(
        c(
          "{.code metadata = TRUE} always returns a data frame.",
          "i" = "Ignoring {.code as_data_frame = FALSE} parameter."
        )
      )
    }

    return(sp_list$get_column_info())
  }

  if (!as_data_frame) {
    return(sp_list)
  }

  ms_obj_as_data_frame(
    sp_list,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
  )
}

#' @rdname sp_list
#' @name list_sp_lists
#' @inheritParams ms_graph_arg_terms
#' @export
list_sp_lists <- function(
  site_url = NULL,
  filter = NULL,
  n = Inf,
  ...,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  as_data_frame = TRUE,
  call = caller_env()
) {
  ms_list_obj <- get_ms_list_obj(
    site_url = site_url,
    ...,
    site = site,
    drive_name = drive_name,
    drive_id = drive_id,
    drive = drive,
    call = call
  )

  sp_lists <- ms_list_obj$get_lists(filter = filter, n = n)

  if (!as_data_frame) {
    return(sp_lists)
  }

  ms_obj_list_as_data_frame(
    sp_lists,
    obj_col = "ms_list",
    keep_list_cols = c("createdBy", "lastModifiedBy"),
    .error_call = call
  )
}

#' @rdname sp_list
#' @name get_sp_list_metadata
#' @inheritParams ms_graph_obj_terms
#' @param keep One of "all" (default), "editable", "external" (non-internal
#' fields). Argument determines if the returned list metadata includes read
#' only columns or hidden columns.
#' @param sync_fields If `TRUE`, use the `sync_fields` method to sync the fields
#'   of the local `ms_list` object with the fields of the SharePoint List source
#'   before retrieving list metadata.
#' @export
get_sp_list_metadata <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  ...,
  keep = c("all", "editable", "external"),
  sync_fields = FALSE,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  if (is.null(sp_list)) {
    sp_list_meta <- get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      metadata = TRUE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )
  } else {
    check_ms_obj(sp_list, "ms_list", call = call)

    if (sync_fields) {
      sp_list <- sp_list$sync_fields()
    }

    sp_list_meta <- sp_list$get_column_info()
  }

  keep <- arg_match(keep, error_call = call)

  if (keep == "editable") {
    sp_list_meta <- sp_list_meta[!sp_list_meta[["readOnly"]], ]
  } else if (keep == "external") {
    sp_list_meta <- sp_list_meta[
      !(sp_list_meta[["name"]] %in% sp_list_internal_colnames),
    ]
  }

  sp_list_meta
}

#' Create, update, or delete a SharePoint List
#'
#' @description
#' [create_sp_list()] allows the creation of a SharePoint list for a site. See:
#' <https://learn.microsoft.com/en-us/graph/api/list-create?view=graph-rest-1.0&tabs=http>
#'
#' [update_sp_list()] allows the modification of the list display name and
#' description.
#'
#' [delete_sp_list()] deletes an existing list and requires user confirmation by
#' default.
#'
#' Notes on creating a SharePoint list:
#'
#' - Dashes (`"-"``) in list names are removed from the list name but retained
#'   in the list display name.
#' - If your definition includes calculated columns, these columns may need to
#'   be added after the list is initially created using
#'   [create_sp_list_column()].
#'
#' Notes on updating a SharePoint list:
#'
#' - The `"Title"` column type is always a "text" type column and can't be
#'   changed.
#'
#' @param list_name Required. List name used as `displayName` property.
#' @param description Optional description.
#' @param columns Optional. Use [create_column_definition()] to create a single
#' column definition or use [create_column_definition_list()] to create a list
#' of column definitions.
#' @inheritParams create_list_info
#' @param title_definition Named list used to update the column definition of
#' the default `"Title"` column created when using the `"genericList"` template.
#' By default, makes Title column optional.
#' @inheritParams get_sp_site
#' @keywords lists
#' @export
create_sp_list <- function(
  list_name,
  ...,
  description = NULL,
  columns = NULL,
  template = "genericList",
  content_types = NULL,
  hidden = NULL,
  title_definition = list(
    required = FALSE
  ),
  site_url = NULL,
  site = NULL,
  call = caller_env()
) {
  site <- site %||%
    get_sp_site(
      site_url = site_url,
      ...,
      call = call
    )

  body <- purrr::compact(
    list(
      displayName = list_name,
      description = description,
      columns = columns,
      list = create_list_info(
        hidden = hidden,
        content_types = content_types,
        template = template,
        call = call
      )
    )
  )

  cli_progress_step(
    "Creating list {.str {list_name}} with {length(columns)} column{?s}."
  )

  resp <- site$do_operation(
    op = "lists",
    body = body,
    encode = "json",
    http_verb = "POST"
  )

  cli_progress_step(
    "List created at {.url {resp[['webUrl']]}}."
  )

  sp_list <- suppressMessages(
    get_sp_list(
      list_id = resp[["id"]],
      site = site
    )
  )

  if (template != "genericList" || is.null(title_definition)) {
    return(invisible(sp_list))
  }

  # Update default Title column definition
  # Title is set up as required when using `"genericList"` template
  title_col <- get_sp_list_column(
    sp_list = sp_list,
    column_name = "Title"
  )

  title_col_definition <- title_col[
    intersect(
      c(
        # TODO: Expand list of supported title_definition parameters
        "name",
        "displayName",
        "hidden",
        "required",
        "text"
      ),
      names(title_definition)
    )
  ]

  title_col_definition[names(title_definition)] <- title_definition

  update_sp_list_column(
    sp_list = sp_list,
    column_id = title_col[["id"]],
    column_definition = title_col_definition
  )

  invisible(sp_list)
}

#' @rdname create_sp_list
#' @name update_sp_list
#' @param list_id List ID for list to update or delete.
#' @param display_name Display name to replace existing display name. Used by
#' [update_sp_list()].
#' @inheritParams get_sp_list
#' @export
update_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  display_name = NULL,
  description = NULL,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  list_properties <- purrr::compact(
    list(
      displayName = display_name,
      description = description
    )
  )

  inject(sp_list$update(!!!list_properties))
}

#' @rdname create_sp_list
#' @name delete_sp_list
#' @param sp_list A `Microsoft365R::ms_list` object.
#' @inheritParams get_sp_drive
#' @param confirm If `TRUE`, confirm deletion of list before proceeding.
#' @export
delete_sp_list <- function(
  list_name = NULL,
  list_id = NULL,
  sp_list = NULL,
  confirm = TRUE,
  ...,
  site_url = NULL,
  site = NULL,
  drive_name = NULL,
  drive_id = NULL,
  drive = NULL,
  call = caller_env()
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      list_id = list_id,
      ...,
      as_data_frame = FALSE,
      site_url = site_url,
      site = site,
      drive_name = drive_name,
      drive_id = drive_id,
      drive = drive,
      call = call
    )

  cli_progress_step("Deleting SharePoint list")

  check_ms_obj(sp_list, "ms_list", call = call)

  sp_list$delete(confirm = confirm)
}

#' Create listinfo object
#'
#' Helper function to create a listInfo object for use internally by
#' [create_sp_list()]. See:
#' <https://learn.microsoft.com/en-us/graph/api/resources/listinfo?view=graph-rest-1.0>
#'
#' @param template Type of template to use in creating the list.
#' @param content_types Optional. Set `TRUE` for `contentTypesEnabled` to be
#' enabled.
#' @param hidden Optional. Set `TRUE` for list to be hidden.
#' @keywords internal lists
#' @export
create_list_info <- function(
  template = c(
    "documentLibrary",
    "genericList",
    "task",
    "survey",
    "announcements",
    "contacts"
  ),
  content_types = NULL,
  hidden = NULL,
  call = caller_env()
) {
  # Validate listinfo properties
  template <- arg_match(template, error_call = call)

  check_bool(content_types, allow_null = TRUE, call = call)
  check_bool(hidden, allow_null = TRUE, call = call)

  purrr::compact(
    list(
      hidden = hidden,
      contentTypesEnabled = content_types,
      template = template
    )
  )
}

#' Get SharePoint list column definition
#'
#' [get_sp_list_column()] get a list column definition.
#'
#' See Graph API documentation
#' <https://learn.microsoft.com/en-us/graph/api/columndefinition-get?view=graph-rest-1.0&tabs=http>
#'
#' @inheritParams get_sp_list
#' @inheritDotParams get_sp_list -as_data_frame
#' @param column_name,column_id Column name or ID to get a definition for.
#' @param column_name_type "name" or "displayName". Used to match column ID so
#' column_name must be unique if `column_name_type = "displayName"`.
#' @export
get_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  column_name_type = "name"
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      ...,
      as_data_frame = FALSE
    )

  if (!is.null(column_name) && is.null(column_id)) {
    column_id <- sp_list_column_as_id(
      column_name = column_name,
      sp_list = sp_list,
      column_name_type = column_name_type
    )
  }

  sp_list$do_operation(
    paste0(
      "columns/",
      column_id
    ),
    encode = "json",
    http_verb = "GET"
  )
}

#' Create, update, and delete SharePoint list columns
#'
#' [create_sp_list_column()] adds a column to a SharePoint list and
#' [delete_sp_list_column()] removes a column to a SharePoint list.
#' [update_sp_list_column()] updates a column definition for an existing column
#' in a SharePoint list (but is not yet implemented).
#'
#' See documentation:
#' <https://learn.microsoft.com/en-us/graph/api/list-post-columns?view=graph-rest-1.0&tabs=http>
#'
#' @inheritParams get_sp_list
#' @inheritDotParams create_column_definition
#' @param column_definition List with column definition created with
#' [create_column_definition()] or a related function. Optional if `column_name`
#' and any required additional parameters are provided.
#' @param list_name List name. Required if `sp_list` is `NULL`.
#' @export
create_sp_list_column <- function(
  sp_list = NULL,
  ...,
  column_name = NULL,
  column_definition = NULL,
  list_name = NULL,
  site = NULL,
  site_url = NULL
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      site = site,
      site_url = site_url,
      as_data_frame = FALSE
    )

  # TODO: Add check for mismatch between `column_name` and
  # column_definition[["column_name"]]

  sp_list$do_operation(
    op = "columns",
    body = column_definition %||%
      create_column_definition(
        name = column_name,
        ...
      ),
    encode = "json",
    http_verb = "POST"
  )
}

# <https://learn.microsoft.com/en-us/graph/api/columndefinition-update?view=graph-rest-1.0&tabs=http>
#' @rdname create_sp_list_column
#' @param column_name,column_id Column ID for column to delete.
#' @param column_name_type "name" or "displayName". Used to match column ID so
#' column_name must be unique if `column_name_type = "displayName"`.
#' @export
update_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  ...,
  list_name = NULL,
  column_definition = NULL,
  column_name_type = "name"
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      as_data_frame = FALSE
    )

  if (is.null(column_name) && !is.null(column_definition[[column_name_type]])) {
    column_name <- column_definition[[column_name_type]]
  }

  if (!is.null(column_name) && is.null(column_id)) {
    column_id <- sp_list_column_as_id(
      column_name = column_name,
      sp_list = sp_list,
      column_name_type = column_name_type
    )
  }

  existing_column <- get_sp_list_column(
    sp_list = sp_list,
    column_id = column_id
  )

  column_definition <- column_definition %||%
    create_column_definition(
      name = column_name,
      ...
    )

  # TODO: Compare existing definition and proposed definition to use only
  # different elements

  sp_list$do_operation(
    op = paste0(
      "columns/",
      column_id
    ),
    body = column_definition,
    encode = "json",
    http_verb = "PATCH"
  )

  invisible(sp_list)
}

# <https://learn.microsoft.com/en-us/graph/api/columndefinition-delete?view=graph-rest-1.0&tabs=http>
#' @rdname create_sp_list_column
#' @export
delete_sp_list_column <- function(
  sp_list = NULL,
  column_name = NULL,
  column_id = NULL,
  list_name = NULL,
  column_name_type = "name"
) {
  sp_list <- sp_list %||%
    get_sp_list(
      list_name = list_name,
      as_data_frame = FALSE
    )

  if (!is.null(column_name) && is.null(column_id)) {
    column_id <- sp_list_column_as_id(
      column_name = column_name,
      sp_list = sp_list,
      column_name_type = column_name_type
    )
  }

  sp_list$do_operation(
    paste0(
      "columns/",
      column_id
    ),
    encode = "json",
    http_verb = "DELETE"
  )
}

#' @noRd
sp_list_column_as_id <- function(
  column_name,
  sp_list = NULL,
  column_name_type = "name"
) {
  column_name_type <- arg_match0(column_name_type, c("name", "displayName"))
  column_info <- sp_list$get_column_info()
  column_info[["id"]][
    match(column_name, column_info[[column_name_type]])
  ]
}

#' Create SharePoint list lookup column
#'
#' [create_sp_list_lookup_column()] is a wrapper for [create_lookup_column()]
#' and [create_sp_list_column()] that allows for the creation of a column in one
#' list (the "lookup" list) and then create a lookup column in a second list.
#'
#' @param sp_list A `ms_list` object. If supplied, `list_name`, `site`, and
#' `site_url` are all ignored.
#' @inheritParams create_sp_list_column
#' @inheritParams create_lookup_column
#' @inheritDotParams create_lookup_column -name -lookup_list_id
#' @keywords internal
#' @export
create_sp_list_lookup_column <- function(
  column_name,
  sp_list = NULL,
  sp_lookup_list,
  lookup_list_column = column_name,
  list_name = NULL,
  site = NULL,
  site_url = NULL,
  ...
) {
  lookup_column_definition <- create_lookup_column(
    name = column_name,
    lookup_list_column = lookup_list_column,
    lookup_list = sp_lookup_list,
    ...
  )

  create_sp_list_column(
    sp_list = sp_list,
    column_definition = lookup_column_definition,
    list_name = list_name,
    site = site,
    site_url = site_url
  )
}

#' Internal SharePoint list column names
#'
#' Vector of internal field or column names for SharePoint lists.
#' Note: Not all internal columns are read-only, _ColorTag
#' ComplianceAssetId, ContentType, and Attachments are all editable.
#'
#' @noRd
sp_list_internal_colnames <- c(
  "_ColorTag",
  "ComplianceAssetId",
  "Attachments",
  "Modified",
  "ID",
  "ContentType",
  "Created",
  "Author",
  "Editor",
  "_UIVersionString",
  "Attachments",
  "Edit",
  "LinkTitleNoMenu",
  "LinkTitle",
  "DocIcon",
  "ItemChildCount",
  "FolderChildCount",
  "_ComplianceFlags",
  "_ComplianceTag",
  "_ComplianceTagWrittenTime",
  "_ComplianceTagUserId",
  "_IsRecord",
  "AppAuthor",
  "AppEditor"
)
