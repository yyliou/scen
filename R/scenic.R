# --- 觀光遊憩據點 / Scenic spots (the package's main purpose) ----------------

#' Query parameters for the scenic-spot data set
#'
#' Returns the raw lookup payload the site uses to populate its scenic-spot
#' search form: available year-months, the region/city hierarchy, the spot
#' categories, the full list of spots (with codes), and the per-request code
#' limit (`scenicSpotLimit`, currently 40).
#'
#' @return A list with elements `yearMonths`, `locations`, `types`,
#'   `scenicSpots` and `scenicSpotLimit`.
#' @seealso [scen_scenic_spot_list()], [scen_scenic_spots()]
#' @export
scen_scenic_params <- function() {
  scen_api("scenic/spot/queryParams")
}

#' List every scenic / recreational spot
#'
#' A tidy table of the spots tracked by the database.
#'
#' @return A [tibble][tibble::tibble] with columns `code`, `name`, `eName`,
#'   `location` (city code) and `type` (category code).
#' @export
scen_scenic_spot_list <- function() {
  tibble::as_tibble(scen_scenic_params()$scenicSpots)
}

#' Download visitor counts for scenic / recreational spots
#'
#' This is the package's primary function. It fetches monthly visitor counts
#' for the major scenic spots. By default it downloads **all** spots for the
#' latest available month, automatically batching the request to respect the
#' server's per-call code limit.
#'
#' @param start,end Period as `c(year, month)` (or `list(year=, month=)`).
#'   Years above 1911 are treated as Gregorian and converted to ROC
#'   automatically (e.g. `c(2026, 3)` == `c(115, 3)`). Defaults to the latest
#'   available month.
#' @param codes Character vector of spot codes (see [scen_scenic_spot_list()]).
#'   `NULL` (default) means every spot.
#' @param batch Maximum number of codes per request. Defaults to the limit
#'   advertised by the server.
#' @return A [tibble][tibble::tibble], one row per spot per month, with columns
#'   such as `year`, `month`, `count`, `city`, `cityName`, `type`, `typeName`,
#'   `code`, `name`, `nameEn`.
#' @examples
#' \dontrun{
#' # All spots, latest month:
#' scen_scenic_spots()
#'
#' # A date range for two named spots (Gregorian years accepted):
#' scen_scenic_spots(
#'   start = c(2025, 1), end = c(2025, 12),
#'   codes = c("0840", "1090")
#' )
#' }
#' @export
scen_scenic_spots <- function(start = NULL, end = NULL,
                              codes = NULL, batch = NULL) {
  params <- scen_scenic_params()
  if (is.null(start)) start <- scen_latest_period(params)
  if (is.null(end))   end   <- start
  if (is.null(codes)) codes <- params$scenicSpots$code
  if (is.null(batch)) batch <- params$scenicSpotLimit %||% 40L
  codes <- as.character(codes)

  sp <- scen_period(start)
  ep <- scen_period(end)

  pieces <- lapply(scen_chunk(codes, batch), function(cs) {
    out <- scen_api(
      "scenic/spot/search/ss",
      list(start = sp, end = ep, codes = scen_arr(cs))
    )
    if (length(out) == 0L || (is.data.frame(out) && nrow(out) == 0L)) {
      return(NULL)
    }
    out
  })
  pieces <- Filter(Negate(is.null), pieces)
  if (length(pieces) == 0L) {
    return(tibble::tibble())
  }
  tibble::as_tibble(do.call(rbind, pieces))
}
