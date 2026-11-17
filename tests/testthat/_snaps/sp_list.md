# pull_sp_list_cols matches column type properties

    Code
      pull_sp_list_cols(sp_list_meta_df, "boolean")
    Condition
      Error in `pull_sp_list_cols()`:
      ! Can't identify "boolean" columns from a data frame of list metadata.
      i The boolean property has no values so it is dropped when the API response is simplified to a data frame.
      i Use `as_data_frame = FALSE` with `get_sp_list_metadata()` instead.

# pull_sp_list_cols validates inputs

    Code
      pull_sp_list_cols("Title", "hidden")
    Condition
      Error in `pull_sp_list_cols()`:
      ! `sp_list_meta` must be a data frame or list, not the string "Title".
    Code
      pull_sp_list_cols(sp_list_meta_df, "notAType")
    Condition
      Error in `pull_sp_list_cols()`:
      ! `col_type` must be one of "required", "hidden", "indexed", "readOnly", "boolean", "calculated", "choice", "contentApprovalStatus", "currency", "dateTime", "geolocation", "hyperlinkOrPicture", "lookup", "number", "personOrGroup", "term", "text", "thumbnail", "all", "editable", or "external", not "notAType".
    Code
      pull_sp_list_cols(sp_list_meta_df, "hidden", names_from = "id")
    Condition
      Error in `pull_sp_list_cols()`:
      ! `names_from` must be one of "name" or "displayName", not "id".

# match_sp_list_name() matches internal then display names

    Code
      idx <- match_sp_list_name("demo-2026", nm, display)
    Message
      i Matched "demo-2026" to the list display name. The internal list
      name is "demo2026".

