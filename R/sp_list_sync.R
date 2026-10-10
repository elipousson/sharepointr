#' Compare or sync a list definition with an existing SharePoint list
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' [compare_sp_list()] compares a list definition (e.g. from a YAML file read
#' with [read_sp_list_yaml()]) with an existing SharePoint list and returns the
#' list settings, columns, and views to add, update, or delete.
#'
#' [sync_sp_list()] applies those changes. By default, it only prints the
#' planned changes (`dry_run = TRUE`) and doesn't delete columns or views
#' (`delete = FALSE`).
#'
#' @details Comparing columns
#'
#' Columns are matched by internal name (`name`). Only the properties included
#' in a definition are compared, so a definition with `text: {}` matches any
#' text column. A property missing from a definition isn't changed.
#'
#' SharePoint internal columns and the `Title` column are excluded unless
#' `Title` is included in the definitions. Columns in the list that aren't in
#' the definitions are returned with `action = "delete"`.
#'
#' Each change has one of these actions:
#'
#' - `"add"`: the column or view isn't in the list.
#' - `"update"`: a property is different.
#' - `"delete"`: the column or view isn't in the definitions.
#' - `"blocked"`: the change can't be made. This includes changing the column
#'   type (e.g. text to number), changing a lookup column's source list,
#'   adding a column type the Graph API can't create, adding a list column
#'   with a name longer than 32 characters (which SharePoint would cut),
#'   changing the list template, and removing the default view without
#'   setting another default view.
#' - `"unverified"`: the current value can't be read with the Graph API. This
#'   includes `validation` (which [sync_sp_list()] applies every time) and
#'   columns where the Graph API doesn't return the column type (hyperlink,
#'   picture, thumbnail, and term columns).
#'
#' A column's internal name can't be changed. A renamed column is returned as
#' a column to add and a column to delete.
#'
#' If `sp_list` is a `ms_list` object and `definitions` is a list definition,
#' the list `displayName`, `description`, and `list` settings (`hidden` and
#' `contentTypesEnabled`) are also compared. A different `template` is blocked
#' since the template can't be changed after a list is created.
#'
#' @details Comparing views
#'
#' Views are only compared if the definition has a `views` element and `views
#' = TRUE`. A definition without views never adds, changes, or deletes views.
#'
#' Views are matched by `Id` (if included in the definition) or `Title`, so a
#' view with an `Id` can be renamed. Only the properties included in a view
#' definition are compared. Hidden and personal views are excluded, and views
#' in the list that aren't in the definition are returned with `action =
#' "delete"`.
#'
#' Setting `DefaultView: true` makes a view the default view (and the current
#' default view is no longer the default). The current default view can't be
#' removed from the default or deleted unless another view is set as the
#' default view. Changes are applied in this order: new views, updated views,
#' the default view, and then deleted views.
#'
#' Views are read and changed with the SharePoint REST API. Use `views =
#' FALSE` to skip views (e.g. if the SharePoint REST API isn't available).
#'
#' @details Changes that use the SharePoint REST API
#'
#' SharePoint stores single and multiple lines of text and single and multiple
#' choice columns as different field types, and the Graph API can't change
#' them. These changes use the SharePoint REST API (`method = "rest"`):
#'
#' - `text.allowMultipleLines`: switching to multiple lines keeps existing
#'   values. Switching to a single line truncates values longer than 255
#'   characters, so it is skipped unless `allow_data_loss = TRUE`.
#' - `choice.displayAs` to or from `"checkBoxes"`: switching to multiple
#'   choice keeps existing values. Switching to a single choice may drop
#'   values from items with more than one choice, so it is skipped unless
#'   `allow_data_loss = TRUE`.
#' - `validation`: the Graph API can't create or update column validation.
#' - All view changes.
#'
#' The SharePoint REST API requires a delegated (user) login with a refresh
#' token, such as the default Microsoft365R login.
#'
#' @param definitions A list definition: a `sp_list_definition` object (see
#'   [read_sp_list_yaml()]), a path to a YAML file, or a list of column
#'   definitions created with [create_column_definition()] or
#'   [create_column_definition_list()].
#' @param sp_list A `ms_list` object. If `NULL`, the list is retrieved with
#'   [get_sp_list()] using the definition `id` (with the site from
#'   `parentReference.siteId` or from additional arguments passed to `...`)
#'   or, if the definition has no `id`, the definition `displayName` and any
#'   additional arguments passed to `...`. If the definition has an `id`, it
#'   must match the `id` of `sp_list`. For [compare_sp_list()], `sp_list` can
#'   also be a list of column metadata from
#'   `get_sp_list_metadata(as_data_frame = FALSE)` (only columns are
#'   compared).
#' @param ... Additional parameters passed to [get_sp_list()] if `sp_list` is
#'   `NULL`.
#' @param views If `TRUE` (default), compare views if the definition has a
#'   `views` element. If `FALSE`, views are skipped.
#' @inheritParams rlang::args_error_context
#' @returns [compare_sp_list()] returns a data frame with one row per added or
#'   deleted column or view and one row per changed property, with columns:
#'
#'   - `object`: `"list"`, `"column"`, or `"view"`.
#'   - `name`: list display name, internal column name, or view title.
#'   - `id`: column or view ID for existing columns and views.
#'   - `action`: one of `"add"`, `"update"`, `"delete"`, `"blocked"`, or
#'     `"unverified"`.
#'   - `property`: changed property, e.g. `"displayName"`,
#'     `"text.allowMultipleLines"`, `"list.hidden"`, or `"RowLimit"`.
#'   - `current`, `proposed`: list columns with the current and proposed
#'     values.
#'   - `method`: `"graph"` or `"rest"` for changes that can be applied.
#'   - `data_loss`: `TRUE` if the change may cause data loss.
#'   - `note`: explanation for blocked, unverified, or data loss changes.
#'
#'   [sync_sp_list()] invisibly returns the same data frame with a `status`
#'   column: `"planned"` (for a dry run), `"applied"`, `"skipped"`,
#'   `"blocked"`, or `"failed"`.
#' @keywords lists
#' @examples
#' \dontrun{
#' definition <- read_sp_list_yaml("list-fields/capital-project.yaml")
#'
#' compare_sp_list(definition, site_url = "<SharePoint site url>")
#'
#' # Print planned changes
#' sync_sp_list(definition, site_url = "<SharePoint site url>")
#'
#' # Apply changes
#' sync_sp_list(
#'   definition,
#'   site_url = "<SharePoint site url>",
#'   dry_run = FALSE
#' )
#' }
#' @export
compare_sp_list <- function(
  definitions,
  sp_list = NULL,
  ...,
  views = TRUE,
  call = caller_env()
) {
  check_bool(views, call = call)
  definitions <- as_sync_definitions(definitions, call = call)
  columns <- definitions[["columns"]]
  declared <- purrr::map_chr(columns, "name")

  exclude <- c(
    "id",
    sp_list_internal_colnames,
    if (!"Title" %in% declared) "Title"
  )

  if (is.list(sp_list) && !inherits(sp_list, "ms_list")) {
    if (is.data.frame(sp_list)) {
      cli_abort(
        "{.arg sp_list} must be a {.cls ms_list} object or a list of column
        metadata from {.code get_sp_list_metadata(as_data_frame = FALSE)}.",
        call = call
      )
    }
    meta <- sp_list
  } else {
    sp_list <- get_definition_sp_list(definitions, sp_list, ..., call = call)
    meta <- get_sp_list_metadata(
      sp_list = sp_list,
      as_data_frame = FALSE,
      call = call
    )
  }

  # Used to check the names of columns to add
  template <- if (inherits(sp_list, "ms_list")) {
    sp_list[["properties"]][["list"]][["template"]]
  } else {
    definitions[["list"]][["template"]]
  }

  meta <- purrr::keep(meta, \(col) !col[["name"]] %in% exclude)
  live_ids <- set_names(
    purrr::map_chr(meta, \(col) col[["id"]] %||% NA_character_),
    purrr::map_chr(meta, "name")
  )
  live <- set_names(
    as_live_columns(meta, keep_defaults = TRUE, exclude = exclude),
    names(live_ids)
  )

  rows <- purrr::map(
    columns,
    \(col) {
      name <- col[["name"]]

      if (!name %in% names(live)) {
        return(column_add_row(col, template = template))
      }

      column_change_rows(
        col,
        live[[name]],
        column_id = live_ids[[name]]
      )
    }
  )

  # Compare list settings if the list properties are available
  list_rows <- if (inherits(sp_list, "ms_list")) {
    list_change_rows(definitions, sp_list[["properties"]])
  }

  rows <- c(list(list_rows), rows)

  delete_names <- setdiff(names(live), declared)

  rows <- c(
    rows,
    purrr::map(
      delete_names,
      \(name) {
        new_change_row(
          object = "column",
          name = name,
          id = live_ids[[name]],
          action = "delete",
          current = column_type_key(live[[name]])
        )
      }
    )
  )

  # Compare views only if the definition has views
  if (views && !is.null(definitions[["views"]]) && inherits(sp_list, "ms_list")) {
    rows <- c(
      rows,
      list(view_change_rows(
        definitions[["views"]],
        get_sync_live_views(sp_list, call = call)
      ))
    )
  }

  bind_change_rows(rows) %||% new_change_row()
}

#' Get the list described by a definition
#'
#' Uses the definition `id` (with additional arguments passed to `...` or the
#' `parentReference.siteId` to get the site) or the `displayName` to get the
#' list if `sp_list` is `NULL`. Errors if the list `id` doesn't match the
#' definition `id`.
#' @noRd
get_definition_sp_list <- function(
  definitions,
  sp_list = NULL,
  ...,
  call = caller_env()
) {
  list_id <- definitions[["id"]]

  if (is.null(sp_list)) {
    site_id <- definitions[["parentReference"]][["siteId"]]

    sp_list <- if (!is.null(list_id) && ...length() == 0 && !is.null(site_id)) {
      get_sp_list(
        list_id = list_id,
        site = get_sp_site(site_id = site_id, call = call),
        metadata = FALSE,
        as_data_frame = FALSE,
        call = call
      )
    } else if (!is.null(list_id)) {
      get_sp_list(
        list_id = list_id,
        ...,
        metadata = FALSE,
        as_data_frame = FALSE,
        call = call
      )
    } else {
      get_sp_list(
        list_name = definitions[["displayName"]],
        ...,
        metadata = FALSE,
        as_data_frame = FALSE,
        call = call
      )
    }
  }

  check_ms_obj(sp_list, "ms_list", call = call)

  if (!is.null(list_id) && !identical(sp_list[["properties"]][["id"]], list_id)) {
    cli_abort(
      c(
        "The list doesn't match the definition {.field id}.",
        "i" = "Definition {.field id}: {.val {list_id}}.",
        "i" = "List {.val {sp_list[['properties']][['displayName']]}}
        {.field id}: {.val {sp_list[['properties']][['id']]}}.",
        "i" = "Remove {.field id} from a definition copied from another
        list."
      ),
      call = call
    )
  }

  sp_list
}

#' Create change rows for list settings
#'
#' Compares `displayName`, `description`, and `list` (listInfo) properties of
#' a definition with the properties of a `ms_list` object.
#' @noRd
list_change_rows <- function(definitions, properties) {
  list_name <- properties[["displayName"]] %||% NA_character_
  info <- definitions[["list"]]
  info_props <- paste0("list.", names(info))

  proposed <- c(
    purrr::compact(list(
      displayName = definitions[["displayName"]],
      description = definitions[["description"]]
    )),
    set_names(as.list(info), info_props)
  )

  current <- c(
    list(
      displayName = properties[["displayName"]],
      description = properties[["description"]] %||% ""
    ),
    set_names(
      purrr::map(
        names(info),
        \(prop) properties[["list"]][[prop]] %||% if (prop != "template") FALSE
      ),
      info_props
    )
  )

  rows <- purrr::imap(
    proposed,
    \(value, property) {
      if (identical(value, current[[property]])) {
        return(NULL)
      }

      blocked <- property == "list.template"

      new_change_row(
        object = "list",
        name = list_name,
        action = if (blocked) "blocked" else "update",
        property = property,
        current = current[[property]],
        proposed = value,
        method = if (blocked) NA_character_ else "graph",
        note = if (blocked) {
          "A list's template can't be changed."
        } else {
          NA_character_
        }
      )
    }
  )

  bind_change_rows(rows)
}

#' Convert definitions input for compare and sync
#' @noRd
as_sync_definitions <- function(definitions, call = caller_env()) {
  if (is_string(definitions)) {
    return(read_sp_list_yaml(definitions, call = call))
  }

  if (inherits(definitions, "sp_list_definition")) {
    return(definitions)
  }

  # A single column definition
  if (is.list(definitions) && is_named(definitions)) {
    if (has_name(definitions, "columns")) {
      return(as_sp_list_definition(definitions, call = call))
    }

    definitions <- list(definitions)
  }

  columns <- definitions

  for (i in seq_along(columns)) {
    columns[[i]] <- validate_column_definition(
      columns[[i]],
      allow_read_only = TRUE,
      allow_custom = TRUE,
      require_type = FALSE,
      label = columns[[i]][["name"]] %||% paste0("definitions[[", i, "]]"),
      call = call
    )
  }

  new_sp_list_definition(display_name = NULL, columns = columns)
}

#' Create a data frame with one row for a list, column, or view change
#' @noRd
new_change_row <- function(
  object = "column",
  name = character(),
  id = NA_character_,
  action = character(),
  property = NA_character_,
  current = NULL,
  proposed = NULL,
  method = NA_character_,
  data_loss = FALSE,
  note = NA_character_
) {
  if (length(name) == 0) {
    return(
      vctrs::data_frame(
        object = character(),
        name = character(),
        id = character(),
        action = character(),
        property = character(),
        current = list(),
        proposed = list(),
        method = character(),
        data_loss = logical(),
        note = character()
      )
    )
  }

  vctrs::data_frame(
    object = object,
    name = name,
    id = id,
    action = action,
    property = property,
    current = list(current),
    proposed = list(proposed),
    method = method,
    data_loss = data_loss,
    note = note
  )
}

#' Combine change rows, dropping `NULL` rows
#' @returns A data frame or `NULL` if there are no rows.
#' @noRd
bind_change_rows <- function(rows) {
  rows <- purrr::compact(rows)

  if (length(rows) == 0) {
    return(NULL)
  }

  vctrs::vec_rbind(!!!rows)
}

#' @noRd
column_add_row <- function(col, template = NULL) {
  type <- column_type_key(col)

  # Column definitions supplied as a list (not a list definition) don't
  # require a column type
  if (is.null(type)) {
    return(new_change_row(
      name = col[["name"]],
      action = "blocked",
      note = "A column type is required to add a column."
    ))
  }

  if (type %in% sp_column_types_create_unsupported) {
    return(new_change_row(
      name = col[["name"]],
      action = "blocked",
      proposed = type,
      note = "The Graph API can't create this column type."
    ))
  }

  if (is_column_name_too_long(col[["name"]], template)) {
    return(new_change_row(
      name = col[["name"]],
      action = "blocked",
      proposed = type,
      note = paste0(
        "The name is longer than ", sp_column_name_max, " characters ",
        "(counting each space or special character as 7), so SharePoint ",
        "would cut it. Use a shorter name."
      )
    ))
  }

  new_change_row(
    name = col[["name"]],
    action = "add",
    proposed = type,
    method = "graph",
    note = if (has_name(col, "validation")) {
      "Validation is applied with the SharePoint REST API."
    } else {
      NA_character_
    }
  )
}

#' Create change rows for an existing column
#' @noRd
column_change_rows <- function(col, current, column_id = NA_character_) {
  diffs <- column_property_diffs(col, current)

  if (length(diffs) == 0) {
    return(NULL)
  }

  rows <- purrr::map(
    diffs,
    \(diff) {
      change <- classify_column_change(diff)
      new_change_row(
        name = col[["name"]],
        id = column_id,
        action = change[["action"]],
        property = diff[["property"]],
        current = diff[["current"]],
        proposed = diff[["proposed"]],
        method = change[["method"]],
        data_loss = change[["data_loss"]],
        note = change[["note"]]
      )
    }
  )

  bind_change_rows(rows)
}

#' Get the views of a list for compare and sync
#'
#' Excludes hidden and personal views. Adds a hint to use `views = FALSE` if
#' the SharePoint REST API isn't available.
#' @noRd
get_sync_live_views <- function(sp_list, call = caller_env()) {
  views <- try_fetch(
    list_sp_list_views(sp_list, as_data_frame = FALSE, call = call),
    error = function(cnd) {
      cli_abort(
        c(
          "Can't read the list views to compare them with the definition.",
          "i" = "Use {.code views = FALSE} to skip views."
        ),
        parent = cnd,
        call = call
      )
    }
  )

  purrr::discard(views, \(view) isTRUE(view[["PersonalView"]]))
}

#' Create change rows for views
#'
#' Views are matched by `Id` (if included in the definition) or `Title`.
#'
#' @param views View definitions from a list definition.
#' @param live Views from `list_sp_list_views(as_data_frame = FALSE)`.
#' @noRd
view_change_rows <- function(views, live) {
  live_ids <- purrr::map_chr(live, \(view) view[["Id"]] %||% NA_character_)
  live_titles <- purrr::map_chr(live, "Title")

  matches <- purrr::map_int(
    views,
    \(view) {
      if (!is.null(view[["Id"]])) {
        match(view[["Id"]], live_ids)
      } else {
        match(view[["Title"]], live_titles)
      }
    }
  )

  # The current default view is replaced if another view (including a new
  # view) is set as the default view
  new_default <- purrr::detect_index(views, \(view) isTRUE(view[["DefaultView"]]))
  current_default <- purrr::detect_index(live, \(view) isTRUE(view[["DefaultView"]]))
  replaces_default <- new_default > 0 &&
    current_default > 0 &&
    !identical(matches[[new_default]], current_default)

  rows <- purrr::map2(
    views,
    matches,
    \(view, idx) {
      if (is.na(idx)) {
        return(view_add_row(view))
      }

      view_update_rows(view, live[[idx]], replaces_default = replaces_default)
    }
  )

  unmatched <- live[setdiff(seq_along(live), matches)]

  bind_change_rows(c(
    rows,
    purrr::map(unmatched, \(view) view_delete_row(view, replaces_default))
  ))
}

#' @noRd
view_add_row <- function(view) {
  new_change_row(
    object = "view",
    name = view[["Title"]],
    action = "add",
    proposed = "view",
    method = "rest",
    note = if (!is.null(view[["Id"]])) {
      "The view Id isn't in the list, so a new view is created."
    } else {
      NA_character_
    }
  )
}

#' Create change rows for an existing view
#'
#' Only properties included in the view definition are compared.
#' @noRd
view_update_rows <- function(view, current, replaces_default = FALSE) {
  props <- intersect(names(view), names(sp_view_props))

  rows <- purrr::map(
    props,
    \(prop) {
      proposed <- view[[prop]]
      value <- current[[prop]]

      compare_value <- if (prop == "CustomFormatter" && is.list(proposed)) {
        as_view_json(proposed)
      } else {
        proposed
      }

      if (same_view_value(compare_value, value, prop)) {
        return(NULL)
      }

      removes_default <- prop == "DefaultView" && isFALSE(proposed)

      # Another view becoming the default view replaces this one
      if (removes_default && replaces_default) {
        return(NULL)
      }

      new_change_row(
        object = "view",
        name = current[["Title"]],
        id = current[["Id"]],
        action = if (removes_default) "blocked" else "update",
        property = prop,
        current = value,
        proposed = proposed,
        method = if (removes_default) NA_character_ else "rest",
        note = if (removes_default) {
          "Set another view as the default view instead."
        } else {
          NA_character_
        }
      )
    }
  )

  bind_change_rows(rows)
}

#' @noRd
view_delete_row <- function(view, replaces_default = FALSE) {
  blocked <- isTRUE(view[["DefaultView"]]) && !replaces_default

  new_change_row(
    object = "view",
    name = view[["Title"]],
    id = view[["Id"]],
    action = if (blocked) "blocked" else "delete",
    current = "view",
    method = if (blocked) NA_character_ else "rest",
    note = if (blocked) {
      "The default view can't be deleted unless another view is set as the default view."
    } else {
      NA_character_
    }
  )
}

#' Find properties that differ between a proposed and current definition
#'
#' Only properties included in `proposed` are compared.
#'
#' @param proposed A column definition.
#' @param current A column definition from `clean_live_column()`.
#' @returns A list of differences, each a list with `property`, `current`,
#'   `proposed`, and `kind` (`"update"`, `"type"`, or `"unverified"`).
#' @noRd
column_property_diffs <- function(proposed, current) {
  type <- column_type_key(proposed)
  current_type <- column_type_key(current)
  diffs <- list()

  props <- setdiff(
    names(proposed),
    c("name", "custom", "id", names(sp_column_type_props))
  )

  for (prop in props) {
    if (prop == "validation") {
      diffs <- c(
        diffs,
        list(list(
          property = prop,
          current = NULL,
          proposed = proposed[[prop]],
          kind = "unverified"
        ))
      )
      next
    }

    if (!same_column_value(proposed[[prop]], current[[prop]], prop, "column")) {
      diffs <- c(
        diffs,
        list(list(
          property = prop,
          current = current[[prop]],
          proposed = proposed[[prop]],
          kind = "update"
        ))
      )
    }
  }

  if (is.null(type)) {
    return(diffs)
  }

  if (is.null(current_type) || type != current_type) {
    return(c(
      diffs,
      list(list(
        property = "type",
        current = current_type,
        proposed = type,
        kind = if (is.null(current_type)) "unverified" else "type"
      ))
    ))
  }

  current_props <- current[[type]]

  for (prop in names(proposed[[type]])) {
    value <- proposed[[type]][[prop]]

    if (!same_column_value(value, current_props[[prop]], prop, type, current_props)) {
      diffs <- c(
        diffs,
        list(list(
          property = paste0(type, ".", prop),
          current = current_props[[prop]],
          proposed = value,
          kind = "update"
        ))
      )
    }
  }

  diffs
}

#' Are a proposed and current property value the same?
#'
#' A missing current value matches a proposed default value.
#' @noRd
same_column_value <- function(
  proposed,
  current,
  prop,
  type,
  current_props = list()
) {
  if (is.null(current)) {
    return(is_default_value(proposed, prop, type, current_props))
  }

  if (prop == "formula" && is_string(proposed) && is_string(current)) {
    return(identical(
      normalize_sp_formula(proposed),
      normalize_sp_formula(current)
    ))
  }

  if (prop == "defaultValue" && is_string(proposed[["formula"]])) {
    proposed[["formula"]] <- normalize_sp_formula(proposed[["formula"]])
    current[["formula"]] <- normalize_sp_formula(current[["formula"]] %||% "")
  }

  if (is.list(proposed) || is.list(current)) {
    proposed <- purrr::compact(proposed)
    current <- purrr::compact(current)

    if (is_named(proposed) && is_named(current)) {
      return(identical(
        purrr::map(proposed[sort(names(proposed))], unlist),
        purrr::map(current[sort(names(current))], unlist)
      ))
    }

    return(identical(unlist(proposed), unlist(current)))
  }

  if (is.numeric(proposed) && is.numeric(current)) {
    return(isTRUE(all.equal(as.numeric(proposed), as.numeric(current))))
  }

  identical(proposed, current)
}

#' Normalize a SharePoint formula for comparison
#'
#' SharePoint rewrites formulas when they are saved: it removes whitespace,
#' removes square brackets around column names without spaces, and uppercases
#' function names. String literals are unchanged. This function applies the
#' same changes (and uppercases column names) so formulas can be compared.
#' @noRd
normalize_sp_formula <- function(formula) {
  tokens <- regmatches(
    formula,
    gregexpr('"(?:[^"]|"")*"|\\[[^\\]]*\\]|[^"\\[]+', formula, perl = TRUE)
  )[[1]]

  normalized <- vapply(
    tokens,
    \(token) {
      if (startsWith(token, '"')) {
        return(token)
      }

      if (startsWith(token, "[")) {
        inner <- substr(token, 2, nchar(token) - 1)
        if (grepl("^[A-Za-z_][A-Za-z0-9_]*$", inner)) {
          return(toupper(inner))
        }
        return(toupper(token))
      }

      toupper(gsub("\\s+", "", token))
    },
    character(1)
  )

  paste0(normalized, collapse = "")
}

#' Classify a column property difference
#' @noRd
classify_column_change <- function(diff) {
  property <- diff[["property"]]
  current <- diff[["current"]]
  proposed <- diff[["proposed"]]

  change <- list(
    action = "update",
    method = "graph",
    data_loss = FALSE,
    note = NA_character_
  )

  if (diff[["kind"]] == "type") {
    return(utils::modifyList(change, list(
      action = "blocked",
      method = NA_character_,
      note = "The column type can't be changed."
    )))
  }

  if (property == "type") {
    return(utils::modifyList(change, list(
      action = "unverified",
      method = NA_character_,
      note = "The Graph API doesn't return the current column type."
    )))
  }

  if (property == "validation") {
    return(utils::modifyList(change, list(
      action = "unverified",
      method = "rest",
      note = "The Graph API doesn't return validation, so it is reapplied."
    )))
  }

  if (property == "text.allowMultipleLines") {
    data_loss <- isFALSE(proposed)
    return(utils::modifyList(change, list(
      method = "rest",
      data_loss = data_loss,
      note = if (data_loss) {
        "Values longer than 255 characters are truncated."
      } else {
        NA_character_
      }
    )))
  }

  if (
    property == "choice.displayAs" &&
      xor(identical(current, "checkBoxes"), identical(proposed, "checkBoxes"))
  ) {
    data_loss <- identical(current, "checkBoxes")
    return(utils::modifyList(change, list(
      method = "rest",
      data_loss = data_loss,
      note = if (data_loss) {
        "Items with more than one choice may lose values."
      } else {
        NA_character_
      }
    )))
  }

  if (property == "lookup.listId") {
    return(utils::modifyList(change, list(
      action = "blocked",
      method = NA_character_,
      note = "A lookup column's source list can't be changed."
    )))
  }

  change
}

#' @rdname compare_sp_list
#' @param dry_run If `TRUE` (default), print the planned changes without
#'   changing the list.
#' @param delete If `TRUE`, delete columns and views that aren't in the
#'   definitions. Defaults to `FALSE`.
#' @param allow_data_loss If `TRUE`, apply changes that may cause data loss
#'   (see details). Defaults to `FALSE`.
#' @export
sync_sp_list <- function(
  definitions,
  sp_list = NULL,
  ...,
  dry_run = TRUE,
  delete = FALSE,
  allow_data_loss = FALSE,
  views = TRUE,
  call = caller_env()
) {
  check_bool(dry_run, call = call)
  check_bool(delete, call = call)
  check_bool(allow_data_loss, call = call)

  definitions <- as_sync_definitions(definitions, call = call)

  sp_list <- get_definition_sp_list(definitions, sp_list, ..., call = call)

  changes <- compare_sp_list(
    definitions,
    sp_list = sp_list,
    views = views,
    call = call
  )
  changes[["status"]] <- plan_change_status(
    changes,
    delete = delete,
    allow_data_loss = allow_data_loss
  )

  list_name <- sp_list[["properties"]][["displayName"]]
  print_changes(changes, list_name = list_name, dry_run = dry_run)

  if (dry_run || !any(changes[["status"]] == "planned")) {
    return(invisible(changes))
  }

  columns <- set_names(
    definitions[["columns"]],
    purrr::map_chr(definitions[["columns"]], "name")
  )

  changes <- apply_list_changes(changes, sp_list)
  changes <- apply_column_changes(changes, columns, sp_list, call = call)
  changes <- apply_view_changes(
    changes,
    views = definitions[["views"]],
    sp_list = sp_list,
    call = call
  )

  failed <- changes[["status"]] == "failed"

  if (any(failed)) {
    cli_warn(
      c(
        "{sum(failed)} change{?s} failed:",
        set_names(
          paste0(
            changes[["object"]][failed],
            " ",
            changes[["name"]][failed],
            ": ",
            changes[["note"]][failed]
          ),
          rep("x", sum(failed))
        )
      ),
      call = call
    )
  }

  applied <- changes[changes[["status"]] == "applied", ]
  n_columns <- length(unique(applied[["name"]][applied[["object"]] == "column"]))
  n_views <- length(unique(applied[["name"]][applied[["object"]] == "view"]))

  cli_inform(
    c(
      "v" = "Updated {.val {list_name}}: {n_columns} column{?s} and
      {n_views} view{?s}{if (any(applied[['object']] == 'list')) ' and list settings' else ''}."
    )
  )

  invisible(changes)
}

#' @noRd
plan_change_status <- function(changes, delete, allow_data_loss) {
  status <- rep("planned", nrow(changes))
  status[changes[["action"]] == "blocked"] <- "blocked"
  status[
    changes[["action"]] == "unverified" & is.na(changes[["method"]])
  ] <- "skipped"
  status[changes[["action"]] == "delete" & !delete] <- "skipped"
  status[changes[["data_loss"]] & !allow_data_loss] <- "skipped"
  status
}

#' Print planned or skipped changes
#' @noRd
print_changes <- function(changes, list_name, dry_run = TRUE) {
  if (nrow(changes) == 0) {
    cli_inform(c("v" = "List {.val {list_name}} matches the definitions."))
    return(invisible(NULL))
  }

  lines <- purrr::map_chr(
    vctrs::vec_chop(changes),
    format_change
  )

  bullets <- match_value(
    changes[["status"]],
    c(planned = "*", skipped = "!", blocked = "x"),
    default = "*"
  )

  cli::cli_text(
    "{if (dry_run) 'Planned changes' else 'Changes'} for list
    {.val {list_name}}:"
  )
  cli::cli_bullets(set_names(lines, bullets))

  skipped <- changes[["status"]] == "skipped"

  if (any(skipped & changes[["action"]] == "delete")) {
    cli::cli_text("Set {.code delete = TRUE} to delete columns and views.")
  }

  if (any(skipped & changes[["data_loss"]])) {
    cli::cli_text(
      "Set {.code allow_data_loss = TRUE} to apply changes that may cause
      data loss."
    )
  }

  if (dry_run) {
    cli::cli_text("Dry run: no changes made. Set {.code dry_run = FALSE} to apply.")
  }

  invisible(NULL)
}

#' Match values to a lookup vector with a default
#' @noRd
match_value <- function(x, values, default) {
  out <- unname(values[x])
  out[is.na(out)] <- default
  out
}

#' Format a single change for printing
#' @noRd
format_change <- function(change) {
  name <- switch(
    change[["object"]],
    list = "list",
    view = paste0("view ", cli::format_inline("{.val {change[['name']]}}")),
    cli::format_inline("{.field {change[['name']]}}")
  )
  action <- change[["action"]]
  property <- change[["property"]]
  note <- change[["note"]]

  text <- switch(
    action,
    add = if (change[["object"]] == "view") {
      paste0("add ", name)
    } else {
      paste0("add ", name, " (", change[["proposed"]][[1]], ")")
    },
    delete = paste0("delete ", name),
    paste0(
      action,
      " ",
      name,
      if (!is.na(property)) paste0(" ", property),
      if (!is.na(property)) {
        paste0(
          ": ",
          format_change_value(change[["current"]][[1]]),
          " -> ",
          format_change_value(change[["proposed"]][[1]])
        )
      }
    )
  )

  if (identical(change[["method"]], "rest") && change[["object"]] != "view") {
    text <- paste0(text, " [REST]")
  }

  if (!is.na(note)) {
    text <- paste0(text, " (", note, ")")
  }

  # Escape braces so cli doesn't interpolate values
  gsub("\\}", "}}", gsub("\\{", "{{", text))
}

#' @noRd
format_change_value <- function(x) {
  if (is.null(x)) {
    return("unset")
  }

  if (is.list(x)) {
    x <- unlist(x)
  }

  value <- paste0(
    if (is.character(x)) paste0('"', x, '"') else as.character(x),
    collapse = ", "
  )

  if (nchar(value) > 60) {
    value <- paste0(substr(value, 1, 57), "...")
  }

  value
}

#' Apply planned list setting changes in one request
#' @noRd
apply_list_changes <- function(changes, sp_list) {
  list_rows <- which(
    changes[["status"]] == "planned" &
      changes[["object"]] == "list" &
      changes[["action"]] == "update"
  )

  if (length(list_rows) == 0) {
    return(changes)
  }

  body <- list()

  for (idx in list_rows) {
    property <- changes[["property"]][[idx]]
    proposed <- changes[["proposed"]][[idx]]

    if (startsWith(property, "list.")) {
      body[["list"]][[sub("^list\\.", "", property)]] <- proposed
    } else {
      body[[property]] <- proposed
    }
  }

  try_change(
    changes,
    list_rows,
    sp_list$do_operation(body = body, encode = "json", http_verb = "PATCH")
  )
}

#' Apply planned column changes
#' @noRd
apply_column_changes <- function(changes, columns, sp_list, call = caller_env()) {
  planned <- changes[["status"]] == "planned" & changes[["object"]] == "column"

  # Add columns (calculated columns last since formulas may reference them)
  add_names <- changes[["name"]][planned & changes[["action"]] == "add"]
  is_calculated <- purrr::map_lgl(
    columns[add_names],
    \(col) identical(column_type_key(col), "calculated")
  )
  add_names <- c(add_names[!is_calculated], add_names[is_calculated])

  for (name in add_names) {
    idx <- which(changes[["name"]] == name & changes[["action"]] == "add")
    changes <- try_change(
      changes,
      idx,
      create_sp_list_column(
        sp_list = sp_list,
        column_definition = columns[[name]],
        call = call
      )
    )
  }

  # Update existing columns
  update_rows <- planned & changes[["action"]] %in% c("update", "unverified")

  for (name in unique(changes[["name"]][update_rows])) {
    idx <- which(update_rows & changes[["name"]] %in% name)
    changes <- try_change(
      changes,
      idx,
      apply_column_updates(
        changes[idx, ],
        column = columns[[name]],
        sp_list = sp_list,
        call = call
      )
    )
  }

  # Delete columns
  delete_rows <- which(planned & changes[["action"]] == "delete")

  for (idx in delete_rows) {
    changes <- try_change(
      changes,
      idx,
      delete_sp_list_column(
        sp_list = sp_list,
        column_id = changes[["id"]][[idx]],
        call = call
      )
    )
  }

  changes
}

#' Apply planned view changes
#'
#' Applies new views, updated views, the default view, and then deleted views.
#' @noRd
apply_view_changes <- function(changes, views, sp_list, call = caller_env()) {
  planned <- changes[["status"]] == "planned" & changes[["object"]] == "view"

  if (!any(planned)) {
    return(changes)
  }

  views <- set_names(views, purrr::map_chr(views, "Title"))
  default_view <- purrr::detect(views, \(view) isTRUE(view[["DefaultView"]]))

  # Add views (without setting the default view)
  for (idx in which(planned & changes[["action"]] == "add")) {
    view <- as_view_to_create(views[[changes[["name"]][[idx]]]])

    changes <- try_change(
      changes,
      idx,
      create_sp_list_view(sp_list, view_definition = view, call = call)
    )
  }

  # Update views (without setting the default view)
  update_rows <- planned &
    changes[["action"]] %in% "update" &
    !changes[["property"]] %in% "DefaultView"

  for (view_id in unique(changes[["id"]][update_rows])) {
    idx <- which(update_rows & changes[["id"]] %in% view_id)
    props <- set_names(changes[["proposed"]][idx], changes[["property"]][idx])

    changes <- try_change(
      changes,
      idx,
      update_sp_list_view(
        sp_list,
        view_id = view_id,
        view_definition = props,
        call = call
      )
    )
  }

  # Set the default view after all views exist. Only one view can be the
  # default view, so this is an update row for an existing view or an add row
  # for a new view.
  default_idx <- which(
    planned &
      (changes[["action"]] == "update" & changes[["property"]] %in% "DefaultView" |
        changes[["action"]] == "add" & changes[["name"]] %in% default_view[["Title"]])
  )

  if (length(default_idx) > 0 && all(changes[["status"]][default_idx] != "failed")) {
    # Use the Id of an existing view in case it was renamed
    view_id <- changes[["id"]][[default_idx[[1]]]]

    changes <- try_change(
      changes,
      default_idx,
      update_sp_list_view(
        sp_list,
        view_title = if (is.na(view_id)) default_view[["Title"]],
        view_id = if (!is.na(view_id)) view_id,
        default_view = TRUE,
        call = call
      )
    )
  }

  # Delete views
  for (idx in which(planned & changes[["action"]] == "delete")) {
    changes <- try_change(
      changes,
      idx,
      delete_sp_list_view(
        sp_list,
        view_id = changes[["id"]][[idx]],
        confirm = FALSE,
        call = call
      )
    )
  }

  changes
}

#' Evaluate a change and record the status
#' @noRd
try_change <- function(changes, idx, expr) {
  result <- tryCatch(
    {
      force(expr)
      NULL
    },
    error = function(cnd) cnd
  )

  if (is.null(result)) {
    changes[["status"]][idx] <- "applied"
  } else {
    changes[["status"]][idx] <- "failed"
    changes[["note"]][idx] <- cli::ansi_strip(conditionMessage(result))
  }

  changes
}

#' Apply property updates for a single column
#'
#' REST changes are applied first since they change the field type, then the
#' remaining properties are sent in one Graph PATCH request.
#' @noRd
apply_column_updates <- function(rows, column, sp_list, call = caller_env()) {
  name <- column[["name"]]
  column_id <- rows[["id"]][[1]]
  type <- column_type_key(column)
  rest_fields <- list()
  graph_body <- list()

  for (i in seq_len(nrow(rows))) {
    property <- rows[["property"]][[i]]
    proposed <- rows[["proposed"]][[i]]

    if (identical(rows[["method"]][[i]], "rest")) {
      if (property == "text.allowMultipleLines") {
        rest_fields[["FieldTypeKind"]] <- if (isTRUE(proposed)) {
          sp_field_type_kind[["Note"]]
        } else {
          sp_field_type_kind[["Text"]]
        }
      } else if (property == "choice.displayAs") {
        if (identical(proposed, "checkBoxes")) {
          rest_fields[["FieldTypeKind"]] <- sp_field_type_kind[["MultiChoice"]]
        } else {
          rest_fields[["FieldTypeKind"]] <- sp_field_type_kind[["Choice"]]
          # A single choice field defaults to a drop down menu
          if (!identical(proposed, "dropDownMenu")) {
            graph_body[[type]][["displayAs"]] <- proposed
          }
        }
      } else if (property == "validation") {
        rest_fields <- c(rest_fields, sp_validation_as_rest_fields(proposed))
      }
      next
    }

    if (grepl(".", property, fixed = TRUE)) {
      prop <- sub("^[^.]+\\.", "", property)
      graph_body[[type]][[prop]] <- proposed
    } else {
      graph_body[[property]] <- proposed
    }
  }

  if (length(rest_fields) > 0) {
    update_sp_list_field_rest(
      sp_list,
      column_name = name,
      fields = rest_fields,
      call = call
    )
  }

  if (length(graph_body) > 0) {
    sp_list$do_operation(
      paste0("columns/", column_id),
      body = graph_body,
      encode = "json",
      http_verb = "PATCH"
    )
  }

  invisible(sp_list)
}

#' Get the properties of a proposed definition that differ from the current
#' definition
#'
#' Used by `update_sp_list_column()` to send only changed properties.
#' @returns A named list of changed properties (possibly empty).
#' @noRd
diff_column_definition <- function(proposed, current) {
  current <- clean_live_column(current, keep_defaults = TRUE)
  type <- column_type_key(proposed)
  diffs <- column_property_diffs(proposed, current)
  body <- list()

  for (diff in diffs) {
    property <- diff[["property"]]

    if (property == "type") {
      body[[type]] <- proposed[[type]]
    } else if (startsWith(property, paste0(type, "."))) {
      body[[type]][[sub("^[^.]+\\.", "", property)]] <- diff[["proposed"]]
    } else {
      body[[property]] <- diff[["proposed"]]
    }
  }

  body
}
