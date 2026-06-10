scen_base_url <- function() {
  getOption("scen.base_url", "https://stat.taiwan.net.tw/data/api")
}

scen_user_agent <- function() {
  getOption(
    "scen.user_agent",
    paste0("Mozilla/5.0 (compatible; scen R package; +https://stat.taiwan.net.tw)")
  )
}

#' Low-level authenticated GET against the statistics API
#'
#' Performs a single `GET` to `<base>/<path>`, attaching a fresh
#' [scen_token()] and the mandatory `query=` parameter (a JSON document).
#' The function throttles requests, retries with exponential back-off when the
#' WAF returns its "Request Rejected" page, regenerates the token on every
#' attempt, and caches successful results on disk.
#'
#' Most users should prefer the higher-level helpers ([scen_scenic_spots()],
#' [scen_inbound()], ...). Use `scen_api()` to reach endpoints the wrappers do
#' not cover.
#'
#' @param path API path below `/data/api/`, e.g. `"scenic/spot/queryParams"`.
#' @param query A list serialised to the `query=` JSON parameter, or `NULL`.
#' @param max_tries Maximum attempts before erroring. Defaults to option
#'   `scen.max_tries` (6).
#' @return The parsed JSON response (typically a `data.frame` or list).
#' @examples
#' \dontrun{
#' scen_api("scenic/spot/queryParams")
#' }
#' @export
scen_api <- function(path, query = NULL,
                     max_tries = getOption("scen.max_tries", 6L)) {
  cached <- scen_cache_get(path, query)
  if (!is.null(cached)) return(cached)

  delay <- getOption("scen.delay", 1.5)
  last_msg <- "unknown error"

  for (try in seq_len(max_tries)) {
    Sys.sleep(if (try == 1L) delay else delay * (2^(try - 1L)))

    req <- httr2::request(paste0(scen_base_url(), "/", path))
    req <- httr2::req_headers(
      req,
      Authorization = scen_token(),
      Accept = "application/json, text/plain, */*"
    )
    req <- httr2::req_user_agent(req, scen_user_agent())
    if (!is.null(query)) {
      req <- httr2::req_url_query(
        req,
        query = jsonlite::toJSON(query, auto_unbox = TRUE, null = "null")
      )
    }
    # We classify outcomes ourselves (the WAF answers 200 with an HTML page).
    req <- httr2::req_error(req, is_error = function(resp) FALSE)

    resp <- tryCatch(httr2::req_perform(req),
                     error = function(e) {
                       last_msg <<- conditionMessage(e)
                       NULL
                     })
    if (is.null(resp)) next

    body <- tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    if (grepl("Request Rejected", body, fixed = TRUE)) {
      last_msg <- "WAF rejected the request (rate limited)"
      next
    }

    status <- httr2::resp_status(resp)
    trimmed <- trimws(body)
    looks_json <- startsWith(trimmed, "[") || startsWith(trimmed, "{")
    if (status >= 200 && status < 300 && looks_json) {
      parsed <- jsonlite::fromJSON(body, simplifyVector = TRUE)
      scen_cache_set(path, query, parsed)
      return(parsed)
    }
    last_msg <- sprintf("HTTP %s with unexpected body", status)
  }

  cli::cli_abort(c(
    "Request to {.field {path}} failed after {max_tries} attempt{?s}.",
    i = "Last error: {last_msg}.",
    i = "The server rate-limits aggressively; try increasing
         {.code options(scen.delay=)} or waiting a minute."
  ))
}

# Build the standard query list: start/end periods plus arbitrary dimension
# vectors (each forced to a JSON array).
scen_build_query <- function(start, end, dims = list()) {
  q <- list(start = scen_period(start), end = scen_period(end))
  for (nm in names(dims)) {
    if (!is.null(dims[[nm]])) q[[nm]] <- scen_arr(dims[[nm]])
  }
  q
}

# Resolve a default period (latest available month) from a *_params payload.
scen_latest_period <- function(params) {
  ym <- params$yearMonths
  ym[nrow(ym), c("year", "month")]
}
