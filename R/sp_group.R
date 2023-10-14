#' Get SharePoint group for a site
#'
#' [get_sp_group()] gets the group associated with an individual site using
#' the `get_group` method.
#'
#' @inheritParams ms_graph_obj_terms
#' @inheritParams get_sp_site
#' @aliases get_sp_site_group
#' @export
get_sp_group <- function(site_url = NULL,
                         site_name = NULL,
                         site_id = NULL,
                         ...,
                         site = NULL,
                         call = caller_env()) {
  if (is_url(site)) {
    site_url <- site
    site <- NULL
  }

  site <- site %||% get_sp_site(
    site_url = site_url,
    site_name = site_name,
    site_id = site_id,
    ...,
    call = call
  )

  check_ms_site(site, call = call)

  site$get_group()
}

#
# list_sp_members <- function(site = NULL,
#                             site_url = NULL,
#                             ...) {
#   get_sp_group()
# }
#
#
# ms_obj_as_data_frame(
#   members[[28]],
#   "az_user", #
#   keep_list_cols = c(
#     "proxyAddresses",
#     "otherMails",
#     "infoCatalogs",
#     "businessPhones",
#     "assignedPlans",
#     "identities",
#     "assignedLicenses",
#     "authorizationInfo",
#     "deviceKeys",
#     "cloudRealtimeCommunicationInfo",
#     "imAddresses",
#     "onPremisesExtensionAttributes",
#     "onPremisesProvisioningErrors",
#     "onPremisesSipInfo",
#     "provisionedPlans",
#     "serviceProvisioningErrors",
#     "passwordProfile"
#   )
# )
