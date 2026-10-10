# sp_url_parse errors if a URL has no site name

    Code
      sp_url_parse(
        "https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents/file.csv")
    Condition
      Error:
      ! Can't find a SharePoint site in <https://bmore.sharepoint.com/sites/DOP-CPR/Shared%20Documents/file.csv>.
      i Use a site URL, a link from "Copy link" in SharePoint, or a list or document library URL.
    Code
      sp_url_parse("https://contoso.sharepoint.us/sites/Team/Lists/Tasks")
    Condition
      Error:
      ! Can't find a SharePoint site in <https://contoso.sharepoint.us/sites/Team/Lists/Tasks>.
      i Use a site URL, a link from "Copy link" in SharePoint, or a list or document library URL.

