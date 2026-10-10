# read_sp_list_yaml reads and validates a list definition

    Code
      print(definition)
    Message
      <sp_list_definition> Example Projects (genericList)
      Example list of projects.
      9 columns: boolean (1), calculated (1), choice (1), currency (1), dateTime (1),
      number (1), text (3)

# read_sp_list_yaml errors for invalid files

    Code
      read_sp_list_yaml("missing-file.yaml")
    Condition
      Error:
      ! 'missing-file.yaml' doesn't exist.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "fields: []")))
    Condition
      Error:
      ! A list definition has unknown key: fields.
      i Allowed keys: format_version, displayName, description, list, custom, columns, and views. Use custom for other metadata.
      i Read-only list properties (e.g. id or webUrl) are also allowed.
    Code
      read_sp_list_yaml(local_yaml(c("columns: []")))
    Condition
      Error:
      ! `displayName` must be a single string, not `NULL`.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "format_version: 2",
        "columns: []")))
    Condition
      Error:
      ! format_version 2 isn't supported.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "columns:", "  - name: A",
        "    label: A", "    sp_col_type: text")))
    Condition
      Error:
      ! A has unknown property: label and sp_col_type.
      i Use displayName in place of label.
      i Use a column type key, e.g. `text: {}` in place of sp_col_type.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "columns:", "  - name: A",
        "    text: {}", "  - name: A", "    number: {}")))
    Condition
      Error:
      ! Column names must be unique. Duplicated: A.

# read_sp_list_yaml validates the list name and settings

    Code
      read_sp_list_yaml(local_yaml(c("name: Test", "columns: []")))
    Condition
      Error:
      ! A list definition must have a displayName.
      i name is the read-only list name set by SharePoint (used in the list URL). Use displayName for the list display name.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "list:",
        "  baseTemplate: 100", "columns: []")))
    Condition
      Error:
      ! list has unknown property: baseTemplate.
      i Allowed properties: template, hidden, and contentTypesEnabled.
    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "list:", "  hidden: maybe",
        "columns: []")))
    Condition
      Error:
      ! `list.hidden` must be `TRUE` or `FALSE`, not the string "maybe".

# read_sp_list_yaml allows read-only list properties and column ids

    Code
      read_sp_list_yaml(local_yaml(c("displayName: Test", "parentReference: site-1",
        "columns: []")))
    Condition
      Error:
      ! parentReference must be a named list (a YAML mapping).

# resolve_read_only_props resolves read_only values

    Code
      resolve_read_only_props("owner")
    Condition
      Error:
      ! `read_only` must be "stable", "all", "none", or read-only list property names.
      x Unknown property: "owner".

# read_sp_list_yaml reads and validates views

    Code
      print(definition)
    Message
      <sp_list_definition> Test
      1 column: text (1)
      2 views: "Active" and "All Items"

# read_sp_list_yaml errors and warns for invalid views

    Code
      read_sp_list_yaml(local_yaml(c(base, "  - Title: A", "  - Title: A")))
    Condition
      Error:
      ! View titles must be unique. Duplicated: "A".
    Code
      read_sp_list_yaml(local_yaml(c(base, "  - Title: A", "    DefaultView: true",
        "  - Title: B", "    DefaultView: true")))
    Condition
      Error:
      ! Only one view can be the default view, not "A" and "B".
    Code
      read_sp_list_yaml(local_yaml(c(base, "  - Title: A", "    row_limit: 10")))
    Condition
      Error:
      ! A has unknown view property: row_limit.
      i Use RowLimit in place of row_limit.
      i Allowed properties: Title, ViewFields, ViewQuery, RowLimit, Paged, DefaultView, Hidden, Scope, CustomFormatter, MobileView, and MobileDefaultView.
    Code
      read_sp_list_yaml(local_yaml(c(base, "  - RowLimit: 10")))
    Condition
      Error:
      ! `views[[1]].Title` must be a single string, not `NULL`.

---

    Code
      definition <- read_sp_list_yaml(local_yaml(c(base, "  - Title: A",
        "    ViewFields: [LinkTitle, Status, Missing, Modified]")))
    Condition
      Warning:
      Views show fields that aren't columns in the definition:
      * "A": Missing

# read_sp_list_yaml warns for duplicate display names

    Code
      definition <- read_sp_list_yaml(path)
    Condition
      Warning:
      Duplicated column display name: "Same".
      i Formulas reference columns by display name.

# write_sp_list_yaml round trips a definition

    Code
      written <- write_sp_list_yaml(definition, path)
    Message
      v Wrote 9 columns to <path>.

---

    Code
      cat(readLines(path), sep = "\n")
    Output
      format_version: 1
      displayName: Example Projects
      description: Example list of projects.
      list:
        template: genericList
      custom:
        owner: Planning
      columns:
        - name: Title
          displayName: Project Name
          required: true
          text: {}
        - name: ProjectID
          displayName: Project ID
          description: Project reference ID
          enforceUniqueValues: true
          indexed: true
          required: true
          text:
            maxLength: 20
          custom:
            form_order: 1
            section: Summary
        - name: ProjectNotes
          displayName: Project Notes
          text:
            allowMultipleLines: true
          custom:
            form_order: 2
            section: Summary
        - name: ProjectStatus
          displayName: Status
          choice:
            choices:
              - Planning
              - Active
              - Closed
            displayAs: radioButtons
          custom:
            form_order: 3
        - name: StartDate
          displayName: Start Date
          dateTime:
            format: dateOnly
        - name: Budget
          displayName: Budget
          currency:
            locale: en-us
          custom:
            decimals: none
        - name: Phases
          displayName: Number of Phases
          number:
            decimalPlaces: none
            minimum: 0
        - name: IsActive
          displayName: Active
          boolean: {}
        - name: BudgetText
          displayName: Budget ($)
          calculated:
            formula: "=IF(ISBLANK([Budget]),\"\",USDOLLAR([Budget],0))"
            outputType: text

# write_sp_list_yaml keeps the header and custom metadata from an existing file

    Code
      written <- write_sp_list_yaml(live, path)
    Condition
      Warning:
      <path> has comments after the header.
      ! Only the comments before the first key (or before a `---` document start marker) are kept.
    Message
      ! Dropping 1 column not found in the list: Removed.
      v Wrote 3 columns to <path>.

# sp_list_definition_table errors for custom keys that match properties

    Code
      sp_list_definition_table(definition)
    Condition
      Error in `sp_list_definition_table()`:
      ! displayName in the custom metadata for column A can't use the name of a column property.
      i Use `custom_prefix` to add a prefix to the names of custom metadata.

