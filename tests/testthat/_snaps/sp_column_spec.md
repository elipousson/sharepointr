# as_column_definition errors for invalid definitions

    Code
      as_column_definition(list(displayName = "No name", text = list()))
    Condition
      Error:
      ! `column.name` must be a valid name, not `NULL`.
    Code
      as_column_definition(list(name = "NoType"))
    Condition
      Error:
      ! NoType must have a column type key.
      i Use one of boolean, calculated, choice, contentApprovalStatus, currency, dateTime, geolocation, hyperlinkOrPicture, lookup, number, personOrGroup, term, text, or thumbnail, e.g. `text: {}`.
    Code
      as_column_definition(list(name = "TwoTypes", text = list(), number = list()))
    Condition
      Error:
      ! TwoTypes must have one column type key, not 2: text and number.
    Code
      as_column_definition(list(name = "Label", label = "Label", text = list()))
    Condition
      Error:
      ! Label has unknown property: label.
      i Use displayName in place of label.
    Code
      as_column_definition(list(name = "ReadOnly", type = "text", text = list()))
    Condition
      Error:
      ! ReadOnly has unknown property: type.
      i type is read-only.
      i Use a column type key, e.g. `text: {}` in place of type.
    Code
      as_column_definition(list(name = "Lines", text = list(multiple_lines = TRUE)))
    Condition
      Error:
      ! Lines.text has unknown property: multiple_lines.
      i Use allowMultipleLines in place of multiple_lines.
      i Allowed properties: allowMultipleLines, appendChangesToExistingText, linesForEditing, maxLength, and textType.
    Code
      as_column_definition(list(name = "Display", choice = list(displayAs = "list")))
    Condition
      Error:
      ! `Display.choice.displayAs` must be one of "checkBoxes", "dropDownMenu", or "radioButtons", not "list".
    Code
      as_column_definition(list(name = "Bool", text = list(allowMultipleLines = "yes")))
    Condition
      Error:
      ! `Bool.text.allowMultipleLines` must be `TRUE` or `FALSE`, not the string "yes".
    Code
      as_column_definition(list(name = "Calc", calculated = list(formula = "=1")))
    Condition
      Error:
      ! Calc.calculated must have formula and outputType.
    Code
      as_column_definition(list(name = "Calc", calculated = list(formula = "=1",
        outputType = "text", format = "dateOnly")))
    Condition
      Error:
      ! Calc.calculated.format can only be used when outputType is "dateTime".
    Code
      as_column_definition(list(name = "Lookup", lookup = list(columnName = "Title")))
    Condition
      Error:
      ! Lookup.lookup must have listId and columnName.
    Code
      as_column_definition(list(name = "Default", defaultValue = list(), text = list()))
    Condition
      Error:
      ! `Default.defaultValue` must have either a value or formula element.
    Code
      as_column_definition(list(name = "Custom", custom = list("a"), text = list()))
    Condition
      Error:
      ! Custom.custom must be a named list (a YAML mapping).
    Code
      as_column_definition(list(name = "NoCustom", custom = list(), text = list()),
      allow_custom = FALSE)
    Condition
      Error:
      ! NoCustom has unknown property: custom.

# as_column_definition warns for cell reference names and unknown person display values

    Code
      def <- as_column_definition(list(name = "V4", text = list()))
    Condition
      Warning:
      Column name "V4" looks like a spreadsheet cell reference.
      i SharePoint encodes names like this (e.g. "V4" is stored as "_x0056_4").
    Code
      def <- as_column_definition(list(name = "Person", personOrGroup = list(
        displayAs = "nickname")))
    Condition
      Warning:
      `Person.personOrGroup.displayAs` value "nickname" isn't a documented value.

# create_*_column helpers error for conflicting or unknown properties

    Code
      create_text_column("Notes", multiple_lines = TRUE, allowMultipleLines = FALSE)
    Condition
      Error in `create_text_column()`:
      ! allowMultipleLines can't be supplied more than once. Use an argument or the Graph property name, not both.
    Code
      create_column_definition("Notes", display_name = "A", displayName = "B")
    Condition
      Error in `create_column_definition()`:
      ! displayName can't be supplied as both an argument and a Graph property name.
    Code
      create_text_column("Notes", label = "Notes")
    Condition
      Error in `create_text_column()`:
      ! Notes.text has unknown property: label.
      i Use displayName in place of label.
      i Allowed properties: allowMultipleLines, appendChangesToExistingText, linesForEditing, maxLength, and textType.
    Code
      create_calculated_column("Calc", formula = "=1", format = "dateOnly")
    Condition
      Error in `create_calculated_column()`:
      ! Calc.calculated.format can only be used when outputType is "dateTime".

# deprecated arguments still work

    Code
      create_column_definition("A", displayname = "B")
    Condition
      Warning:
      The `displayname` argument of `create_column_definition()` is deprecated as of sharepointr 0.2.0.
      i Please use the `display_name` argument instead.
    Output
      $name
      [1] "A"
      
      $displayName
      [1] "B"
      
      $text
      named list()
      
    Code
      create_number_column("A", decimals = 2)
    Condition
      Warning:
      The `decimals` argument of `create_number_column()` is deprecated as of sharepointr 0.2.0.
      i Please use the `decimal_places` argument instead.
    Output
      $name
      [1] "A"
      
      $number
      $number$decimalPlaces
      [1] "two"
      
      
    Code
      create_lookup_column("A", lookup_list_column = "Title", lookup_list_id = "abc",
        allow_multiple = TRUE)
    Condition
      Warning:
      The `allow_multiple` argument of `create_lookup_column()` is deprecated as of sharepointr 0.2.0.
      i Please use the `allow_multiple_values` argument instead.
    Output
      $name
      [1] "A"
      
      $lookup
      $lookup$allowMultipleValues
      [1] TRUE
      
      $lookup$listId
      [1] "abc"
      
      $lookup$columnName
      [1] "Title"
      
      
    Code
      create_person_column("A", allow_multiple = TRUE)
    Condition
      Warning:
      The `allow_multiple` argument of `create_person_column()` is deprecated as of sharepointr 0.2.0.
      i Please use the `allow_multiple_selection` argument instead.
    Output
      $name
      [1] "A"
      
      $personOrGroup
      $personOrGroup$allowMultipleSelection
      [1] TRUE
      
      $personOrGroup$chooseFromType
      [1] "peopleOnly"
      
      
    Code
      create_term_column("A", allow_multiple = TRUE)
    Condition
      Warning:
      The `allow_multiple` argument of `create_term_column()` is deprecated as of sharepointr 0.2.0.
      i Please use the `allow_multiple_values` argument instead.
    Output
      $name
      [1] "A"
      
      $term
      $term$allowMultipleValues
      [1] TRUE
      
      

# create_column_definition_list accepts Graph names and type keys

    Code
      create_column_definition_list(data.frame(name = "A", type = "unknown"))
    Condition
      Error in `purrr::pmap()`:
      i In index: 1.
      Caused by error in `.f()`:
      ! Column A has an unknown column type: "unknown".

