# --- 來臺旅客 / Inbound visitor arrivals -------------------------------------

#' Query parameters for the inbound data set
#'
#' Returns the lookup payload for inbound visitor arrivals: available
#' year-months and the code tables for every dimension you can cross by
#' (`ages`, `age2s`, `categories`, `genders`, `idles` (nights of stay),
#' `jobs`, `modeAndPort` (transport x port), `purposes`, `countries`, plus
#' `countryLimit`).
#'
#' @return A named list of lookup tables.
#' @export
scen_inbound_params <- function() {
  scen_api("inbound/queryParams")
}

#' Download inbound visitor arrivals (with cross-tabulations)
#'
#' Fetches inbound visitor counts at any granularity the site offers. The
#' `by` argument chooses the endpoint, and the named dimension arguments in
#' `...` are inserted into the request, so you can reach the finest crosses.
#'
#' @param by Endpoint suffix. Single dimensions:
#'   `"residence"`, `"country"`, `"gender"`, `"age"`, `"category"`, `"idle"`,
#'   `"job"`, `"purpose"`, `"map"` (transport x port). Combined crosses:
#'   `"agp"` (age x gender x purpose), `"agc"` (age x gender x country),
#'   `"pgc"` (purpose x gender x country), `"aap"`, `"jap"`.
#' @param start,end Period as `c(year, month)` (Gregorian or ROC; see
#'   [scen_scenic_spots()]). Defaults to the latest available month.
#' @param ... Named dimension vectors placed into the query. Use the plural
#'   keys from [scen_inbound_params()], e.g. `countries = c("11010", "13110")`,
#'   `ages = "A"`, `purposes = "B"`. Note that the combined-cross endpoints use
#'   the singular key `gender` (e.g. `gender = "M"`), matching the website.
#'   If `by = "residence"` and `residence` is not supplied it is mirrored from
#'   `countries`.
#' @return A [tibble][tibble::tibble] of counts.
#' @examples
#' \dontrun{
#' # Japan arrivals, latest month:
#' scen_inbound("residence", countries = "11010")
#'
#' # Age x gender x purpose for a whole year:
#' scen_inbound("agp", start = c(2025, 1), end = c(2025, 12),
#'              ages = "A", gender = "M", purposes = "B")
#'
#' # Every country (auto-batched to respect the 40-code limit):
#' p <- scen_inbound_params()
#' scen_inbound("country", countries = p$countries$code)
#' }
#' @export
scen_inbound <- function(by = "residence", start = NULL, end = NULL, ...) {
  dims <- list(...)
  if (identical(by, "residence") &&
      is.null(dims$residence) && !is.null(dims$countries)) {
    dims$residence <- dims$countries
  }
  scen_cross_search("inbound", by, start, end, dims, scen_inbound_params)
}
