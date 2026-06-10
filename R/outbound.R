# --- 出國旅客 / Outbound traveller departures --------------------------------

#' Query parameters for the outbound data set
#'
#' Returns the lookup payload for outbound traveller departures: available
#' year-months and the code tables for the dimensions you can cross by
#' (`ages`, `genders`, `idles`, `modeAndPort`, `countries` (destinations)).
#'
#' @return A named list of lookup tables.
#' @export
scen_outbound_params <- function() {
  scen_api("outbound/queryParams")
}

#' Download outbound traveller departures (with cross-tabulations)
#'
#' @param by Endpoint suffix. Single dimensions: `"destination"`, `"gender"`,
#'   `"age"`, `"idle"` (nights), `"map"` (transport x port). Combined cross:
#'   `"agd"` (age x gender x destination).
#' @param start,end Period as `c(year, month)` (Gregorian or ROC). Defaults to
#'   the latest available month.
#' @param ... Named dimension vectors placed into the query. Use the keys from
#'   [scen_outbound_params()], e.g. `countries = "31026"` for a destination,
#'   `ages = "A"`, `gender = "M"`.
#' @return A [tibble][tibble::tibble] of counts.
#' @examples
#' \dontrun{
#' scen_outbound("destination", countries = "31026")
#' scen_outbound("agd", ages = "A", gender = "M", countries = "31026")
#' }
#' @export
scen_outbound <- function(by = "destination", start = NULL, end = NULL, ...) {
  dims <- list(...)
  if (identical(by, "destination") &&
      is.null(dims$destination) && !is.null(dims$countries)) {
    dims$destination <- dims$countries
  }
  scen_cross_search("outbound", by, start, end, dims, scen_outbound_params)
}
