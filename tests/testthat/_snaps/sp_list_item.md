# match_sp_list_field_names() matches names to list fields

    Code
      match_sp_list_field_names(c("Title", "Other", "ContentType"), values)
    Message
      ! All column names in `data` must match field names in the supplied list.
      i Columns "Other" and "ContentType" dropped from `data`
    Output
      [1]  TRUE FALSE FALSE
    Code
      match_sp_list_field_names(c("Title", "Other"), values, what = "field")
    Message
      ! All field names in `data` must match field names in the supplied list.
      i Field "Other" dropped from `data`
    Output
      [1]  TRUE FALSE

---

    Code
      match_sp_list_field_names("Other", values, what = "field")
    Condition
      Error:
      ! At least one field in `data` must match field names in the supplied list.
      i Field names from list are "Title" and "Status"

---

    Code
      match_sp_list_field_names(c("Title", "Other"), values, strict = TRUE)
    Condition
      Error:
      ! All column names in `data` must match field names in the supplied list.
      i Field names from list are "Title" and "Status"

