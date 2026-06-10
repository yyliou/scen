# --- 郵輪來臺旅客 / Cruise visitor arrivals ----------------------------------

#' Query parameters for the cruise data set
#'
#' Returns the lookup payload for cruise visitor arrivals (year-months and the
#' code tables for the dimensions you can cross by, e.g. cruises, ports,
#' regions and genders). A second endpoint, `cruise/visitor/queryParams/cruise`,
#' is reachable via [scen_api()] if you need the cruise-line list specifically.
#'
#' @return A named list of lookup tables.
#' @export
scen_cruise_params <- function() {
  scen_api("cruise/visitor/queryParams")
}

#' Download cruise visitor arrivals (with cross-tabulations)
#'
#' @param by Endpoint suffix. Single dimensions: `"cruise"` (by cruise line),
#'   `"gender"`, `"port"`. Combined crosses: `"rg"` (region x gender),
#'   `"rp"` (region x port), `"gp"` (gender x port),
#'   `"rgp"` (region x gender x port).
#' @param start,end Period as `c(year, month)` (Gregorian or ROC). Defaults to
#'   the latest available month.
#' @param ... Named dimension vectors placed into the query. Inspect
#'   [scen_cruise_params()] for the available keys and codes (e.g. `genders`,
#'   `ports`, `regions`, `cruises`).
#' @return A [tibble][tibble::tibble] of counts.
#' @examples
#' \dontrun{
#' scen_cruise("gender", genders = c("M", "F"))
#' scen_cruise_params() # discover the valid dimension keys / codes
#' }
#' @export
scen_cruise <- function(by = "cruise", start = NULL, end = NULL, ...) {
  dims <- list(...)
  scen_cross_search("cruise/visitor", by, start, end, dims, scen_cruise_params)
}
