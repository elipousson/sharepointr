# compare_sp_list_columns finds added, updated, deleted, and blocked columns

    Code
      print(changes[c("name", "action", "property", "method", "data_loss", "note")])
    Output
                 name     action                property method data_loss
      1         Notes     update             displayName  graph     FALSE
      2         Notes     update text.allowMultipleLines   rest     FALSE
      3        Status     update          choice.choices  graph     FALSE
      4        Status     update        choice.displayAs   rest     FALSE
      5        Amount    blocked                    type   <NA>     FALSE
      6          Link unverified                    type   <NA>     FALSE
      7       NewFlag        add                    <NA>  graph     FALSE
      8     Validated        add                    <NA>  graph     FALSE
      9  NewThumbnail    blocked                    <NA>   <NA>     FALSE
      10    OldColumn     delete                    <NA>   <NA>     FALSE
                                                          note
      1                                                   <NA>
      2                                                   <NA>
      3                                                   <NA>
      4                                                   <NA>
      5                      The column type can't be changed.
      6  The Graph API doesn't return the current column type.
      7                                                   <NA>
      8    Validation is applied with the SharePoint REST API.
      9           The Graph API can't create this column type.
      10                                                  <NA>

# compare_sp_list_columns errors for data frame metadata

    Code
      compare_sp_list_columns(list(create_text_column("A")), sp_list = data.frame(
        name = "A"))
    Condition
      Error:
      ! `sp_list` must be a <ms_list> object or a list of column metadata from `get_sp_list_metadata(as_data_frame = FALSE)`.

# print_column_changes summarizes planned changes

    Code
      print_column_changes(changes, list_name = "Test")
    Message
      Planned changes for list "Test":
      * update Notes text.allowMultipleLines: FALSE -> TRUE [REST]
      x blocked Amount type: "number" -> "text" (The column type can't be changed.)
      * add NewFlag (boolean)
      ! delete Status
      ! delete Link
      ! delete OldColumn
      Set `delete = TRUE` to delete columns.
      Dry run: no changes made. Set `dry_run = FALSE` to apply.

# get_definition_sp_list uses and checks the definition id

    Code
      get_definition_sp_list(definition, sp_list = new_ms_list("list-2", "Other"))
    Condition
      Error:
      ! The list doesn't match the definition id.
      i Definition id: "list-1".
      i List "Other" id: "list-2".
      i Remove id from a definition copied from another list.

