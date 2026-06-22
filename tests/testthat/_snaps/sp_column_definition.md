# create_text_column works

    Code
      create_text_column("TextColumn")
    Output
      $name
      [1] "TextColumn"
      
      $hidden
      [1] FALSE
      
      $text
      $text$textType
      [1] "plain"
      
      

---

    Code
      create_text_column("TextColumn", multiple_lines = TRUE, append_changes = TRUE,
        lines = 6L, max_length = 500L, text_type = "richText")
    Output
      $name
      [1] "TextColumn"
      
      $hidden
      [1] FALSE
      
      $text
      $text$allowMultipleLines
      [1] TRUE
      
      $text$appendChangesToExistingText
      [1] TRUE
      
      $text$linesForEditing
      [1] 6
      
      $text$maxLength
      [1] 500
      
      $text$textType
      [1] "richText"
      
      

---

    Code
      create_text_column("TextColumn", required = TRUE, hidden = FALSE, description = "A text column")
    Output
      $name
      [1] "TextColumn"
      
      $hidden
      [1] FALSE
      
      $required
      [1] TRUE
      
      $description
      [1] "A text column"
      
      $text
      $text$textType
      [1] "plain"
      
      

# create_number_column works

    Code
      create_number_column("NumberColumn")
    Output
      $name
      [1] "NumberColumn"
      
      $hidden
      [1] FALSE
      
      $number
      $number$decimalPlaces
      [1] "automatic"
      
      

---

    Code
      create_number_column("NumberColumn", decimals = "two")
    Output
      $name
      [1] "NumberColumn"
      
      $hidden
      [1] FALSE
      
      $number
      $number$decimalPlaces
      [1] "two"
      
      

---

    Code
      create_number_column("NumberColumn", decimals = 3)
    Output
      $name
      [1] "NumberColumn"
      
      $hidden
      [1] FALSE
      
      $number
      $number$decimalPlaces
      [1] "three"
      
      

---

    Code
      create_number_column("NumberColumn", display_as = "percentage", min = 0, max = 100)
    Output
      $name
      [1] "NumberColumn"
      
      $hidden
      [1] FALSE
      
      $number
      $number$decimalPlaces
      [1] "automatic"
      
      $number$displayAs
      [1] "percentage"
      
      $number$maximum
      [1] 100
      
      $number$minimum
      [1] 0
      
      

# create_choice_column works

    Code
      create_choice_column("ChoiceColumn", fruit)
    Output
      $name
      [1] "ChoiceColumn"
      
      $hidden
      [1] FALSE
      
      $choice
      $choice$allowTextEntry
      [1] TRUE
      
      $choice$choices
      [1] "apple"     "banana"    "pear"      "pineapple"
      
      $choice$displayAs
      [1] "dropDownMenu"
      
      

---

    Code
      create_choice_column("ChoiceColumn", fruit, allow_text = FALSE, display_as = "checkBoxes")
    Output
      $name
      [1] "ChoiceColumn"
      
      $hidden
      [1] FALSE
      
      $choice
      $choice$allowTextEntry
      [1] FALSE
      
      $choice$choices
      [1] "apple"     "banana"    "pear"      "pineapple"
      
      $choice$displayAs
      [1] "checkBoxes"
      
      

---

    Code
      create_choice_column("ChoiceColumn", "apple|banana|pear", split = "|")
    Output
      $name
      [1] "ChoiceColumn"
      
      $hidden
      [1] FALSE
      
      $choice
      $choice$allowTextEntry
      [1] TRUE
      
      $choice$choices
      [1] "apple"  "banana" "pear"  
      
      $choice$displayAs
      [1] "dropDownMenu"
      
      

# create_datetime_column works

    Code
      create_datetime_column("DatetimeColumn")
    Output
      $name
      [1] "DatetimeColumn"
      
      $hidden
      [1] FALSE
      
      $dateTime
      $dateTime$format
      [1] "dateOnly"
      
      $dateTime$displayAs
      [1] "default"
      
      

---

    Code
      create_datetime_column("DatetimeColumn", display_as = "friendly", format = "dateTime")
    Output
      $name
      [1] "DatetimeColumn"
      
      $hidden
      [1] FALSE
      
      $dateTime
      $dateTime$format
      [1] "dateTime"
      
      $dateTime$displayAs
      [1] "friendly"
      
      

# create_boolean_column works

    Code
      create_boolean_column("BooleanColumn")
    Output
      $name
      [1] "BooleanColumn"
      
      $hidden
      [1] FALSE
      
      $boolean
      named list()
      

# create_currency_column works

    Code
      create_currency_column("CurrencyColumn")
    Output
      $name
      [1] "CurrencyColumn"
      
      $hidden
      [1] FALSE
      
      $currency
      $currency$locale
      [1] "en-us"
      
      

---

    Code
      create_currency_column("CurrencyColumn", locale = "en-gb")
    Output
      $name
      [1] "CurrencyColumn"
      
      $hidden
      [1] FALSE
      
      $currency
      $currency$locale
      [1] "en-gb"
      
      

# create_calculated_column works

    Code
      create_calculated_column(name = "FormulaColumn", formula = "=[Text Column]")
    Output
      $name
      [1] "FormulaColumn"
      
      $hidden
      [1] FALSE
      
      $calculated
      $calculated$formula
      =[Text Column]
      
      $calculated$outputType
      [1] "text"
      
      

---

    Code
      create_calculated_column(name = "FormulaColumn", formula = "[Text Column]")
    Output
      $name
      [1] "FormulaColumn"
      
      $hidden
      [1] FALSE
      
      $calculated
      $calculated$formula
      =[Text Column]
      
      $calculated$outputType
      [1] "text"
      
      

---

    Code
      create_calculated_column(name = "DateFormulaColumn", formula = "=[StartDate]+7",
        output_type = "dateTime", format = "dateOnly")
    Output
      $name
      [1] "DateFormulaColumn"
      
      $hidden
      [1] FALSE
      
      $calculated
      $calculated$format
      [1] "dateOnly"
      
      $calculated$formula
      =[StartDate]+7
      
      $calculated$outputType
      [1] "dateTime"
      
      

# create_lookup_column works

    Code
      create_lookup_column(name = "LookupColumn", lookup_list_column = "Title",
        lookup_list_id = "abc-123")
    Output
      $name
      [1] "LookupColumn"
      
      $hidden
      [1] FALSE
      
      $lookup
      $lookup$listId
      [1] "abc-123"
      
      $lookup$columnName
      [1] "Title"
      
      

---

    Code
      create_lookup_column(name = "LookupColumn", lookup_list_column = "Title",
        lookup_list_id = "abc-123", allow_multiple = TRUE, allow_unlimited_length = TRUE)
    Output
      $name
      [1] "LookupColumn"
      
      $hidden
      [1] FALSE
      
      $lookup
      $lookup$allowMultipleValues
      [1] TRUE
      
      $lookup$allowUnlimitedLength
      [1] TRUE
      
      $lookup$listId
      [1] "abc-123"
      
      $lookup$columnName
      [1] "Title"
      
      

# create_person_column works

    Code
      create_person_column("PersonColumn")
    Output
      $name
      [1] "PersonColumn"
      
      $hidden
      [1] FALSE
      
      $personOrGroup
      $personOrGroup$chooseFromType
      [1] "peopleOnly"
      
      

# create_group_column works

    Code
      create_group_column("GroupColumn")
    Output
      $name
      [1] "GroupColumn"
      
      $hidden
      [1] FALSE
      
      $personOrGroup
      $personOrGroup$chooseFromType
      [1] "peopleAndGroups"
      
      

# create_hyperlink_column works

    Code
      create_hyperlink_column("HyperlinkColumn")
    Output
      $name
      [1] "HyperlinkColumn"
      
      $hidden
      [1] FALSE
      
      $hyperlinkOrPicture
      $hyperlinkOrPicture$isPicture
      [1] FALSE
      
      

# create_picture_column works

    Code
      create_picture_column("PictureColumn")
    Output
      $name
      [1] "PictureColumn"
      
      $hidden
      [1] FALSE
      
      $hyperlinkOrPicture
      $hyperlinkOrPicture$isPicture
      [1] TRUE
      
      

# create_thumbnail_column works

    Code
      create_thumbnail_column("ThumbnailColumn")
    Output
      $name
      [1] "ThumbnailColumn"
      
      $hidden
      [1] FALSE
      
      $thumbnail
      named list()
      

# create_geolocation_column works

    Code
      create_geolocation_column("GeolocationColumn")
    Output
      $name
      [1] "GeolocationColumn"
      
      $hidden
      [1] FALSE
      
      $geolocation
      named list()
      

# create_term_column works

    Code
      create_term_column("TermColumn")
    Output
      $name
      [1] "TermColumn"
      
      $hidden
      [1] FALSE
      
      $term
      $term$allowMultipleValues
      [1] TRUE
      
      

# create_column_definition works with shared options

    Code
      create_column_definition("MyColumn", .col_type = "text", required = TRUE,
        hidden = TRUE, enforce_unique = TRUE, indexed = TRUE, description = "A column",
        displayname = "My Column")
    Output
      $name
      [1] "MyColumn"
      
      $enforceUniqueValues
      [1] TRUE
      
      $hidden
      [1] TRUE
      
      $indexed
      [1] TRUE
      
      $required
      [1] TRUE
      
      $description
      [1] "A column"
      
      $displayName
      [1] "My Column"
      
      $text
      named list()
      

---

    Code
      create_column_definition("MyColumn", .col_type = "text", default = get_column_default(
        "Default text"))
    Output
      $name
      [1] "MyColumn"
      
      $hidden
      [1] FALSE
      
      $defaultValue
      $defaultValue$value
      [1] "Default text"
      
      
      $text
      named list()
      

# get_column_default works

    Code
      get_column_default()

---

    Code
      get_column_default("Missing")
    Output
      $value
      [1] "Missing"
      

---

    Code
      get_column_default(formula = "=[Title]")
    Output
      $formula
      =[Title]
      

# create_column_definition_list works

    Code
      create_column_definition_list(definition_df)
    Output
      [[1]]
      [[1]]$name
      [1] "FirstColumn"
      
      [[1]]$hidden
      [1] FALSE
      
      [[1]]$text
      [[1]]$text$allowMultipleLines
      [1] TRUE
      
      [[1]]$text$textType
      [1] "plain"
      
      
      
      [[2]]
      [[2]]$name
      [1] "SecondColumn"
      
      [[2]]$hidden
      [1] FALSE
      
      [[2]]$number
      [[2]]$number$decimalPlaces
      [1] "none"
      
      
      

# data_as_column_definition_list works

    Code
      data_as_column_definition_list(simple_df)
    Output
      [[1]]
      [[1]]$name
      [1] "text_col"
      
      [[1]]$hidden
      [1] FALSE
      
      [[1]]$text
      [[1]]$text$textType
      [1] "plain"
      
      
      
      [[2]]
      [[2]]$name
      [1] "num_col"
      
      [[2]]$hidden
      [1] FALSE
      
      [[2]]$number
      [[2]]$number$decimalPlaces
      [1] "automatic"
      
      
      
      [[3]]
      [[3]]$name
      [1] "int_col"
      
      [[3]]$hidden
      [1] FALSE
      
      [[3]]$number
      [[3]]$number$decimalPlaces
      [1] "none"
      
      
      
      [[4]]
      [[4]]$name
      [1] "lgl_col"
      
      [[4]]$hidden
      [1] FALSE
      
      [[4]]$boolean
      named list()
      
      
      [[5]]
      [[5]]$name
      [1] "fct_col"
      
      [[5]]$hidden
      [1] FALSE
      
      [[5]]$choice
      [[5]]$choice$allowTextEntry
      [1] TRUE
      
      [[5]]$choice$choices
      [1] "x" "y"
      
      [[5]]$choice$displayAs
      [1] "dropDownMenu"
      
      
      
      [[6]]
      [[6]]$name
      [1] "date_col"
      
      [[6]]$hidden
      [1] FALSE
      
      [[6]]$dateTime
      [[6]]$dateTime$format
      [1] "dateOnly"
      
      [[6]]$dateTime$displayAs
      [1] "default"
      
      
      

---

    Code
      data_as_column_definition_list(simple_df, definitions_as = "table")
    Output
            name    type decimals choices split
      1 text_col    text     <NA>    <NA>  <NA>
      2  num_col  number     <NA>    <NA>  <NA>
      3  int_col  number     none    <NA>  <NA>
      4  lgl_col boolean     <NA>    <NA>  <NA>
      5  fct_col  choice     <NA>     x|y     |
      6 date_col    date     <NA>    <NA>  <NA>

