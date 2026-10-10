# get_sp_item() falls back to the parsed URL if the shares API fails

    Code
      get_sp_item(
        "https://contoso.sharepoint.com/sites/Team/Shared%20Documents/A.png")
    Condition
      Error:
      ! Can't get a SharePoint item from <https://contoso.sharepoint.com/sites/Team/Shared%20Documents/A.png>.
      Caused by error in `sp_shares_get_item()`:
      ! Forbidden (HTTP 403).

