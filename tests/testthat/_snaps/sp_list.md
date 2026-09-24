# pull_sp_list_cols matches column type properties

    Code
      pull_sp_list_cols(sp_list_meta_df, "boolean")
    Condition
      Error:
      ! Can't identify "boolean" columns from a data frame of list metadata.
      i The boolean property has no values so it is dropped when the API response is simplified to a data frame.
      i Use `as_data_frame = FALSE` with `get_sp_list_metadata()` instead.

# pull_sp_list_cols validates inputs

    Code
      pull_sp_list_cols("Title", "hidden")
    Condition
      Error:
      ! `sp_list_meta` must be a data frame or list, not the string "Title".
    Code
      pull_sp_list_cols(sp_list_meta_df, "notAType")
    Condition
      Error:
      ! `col_type` must be one of "required", "hidden", "indexed", "readOnly", "boolean", "calculated", "choice", "contentApprovalStatus", "currency", "dateTime", "geolocation", "hyperlinkOrPicture", "lookup", "number", "personOrGroup", "term", "text", "thumbnail", "all", "editable", or "external", not "notAType".
    Code
      pull_sp_list_cols(sp_list_meta_df, "hidden", names_from = "id")
    Condition
      Error:
      ! `names_from` must be one of "name" or "displayName", not "id".

