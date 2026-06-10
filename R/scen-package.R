#' scen: Client for the Taiwan Tourism Administration Statistics Database
#'
#' The package talks to the Tourism Statistics Database at
#' <https://stat.taiwan.net.tw> ("交通部觀光署觀光統計資料庫").
#'
#' Its main purpose is to download visitor counts for the major scenic /
#' recreational spots ("觀光遊憩據點") via [scen_scenic_spots()]. It also
#' exposes the inbound ("來臺"), outbound ("出國") and cruise ("郵輪") data
#' sets, including the finest cross-tabulations the site provides, through
#' [scen_inbound()], [scen_outbound()] and [scen_cruise()].
#'
#' @section Options:
#' * `scen.cache` (default `TRUE`): cache successful responses on disk.
#' * `scen.cache_ttl` (default `86400` seconds): cache time-to-live.
#' * `scen.cache_dir`: override the cache directory.
#' * `scen.delay` (default `1.5` seconds): minimum delay between requests
#'   (the server rate-limits aggressively).
#' * `scen.max_tries` (default `6`): attempts per request before giving up.
#' * `scen.user_agent`: User-Agent header sent with every request.
#'
#' @keywords internal
"_PACKAGE"

# Quiet R CMD check for the rlang import used in NAMESPACE.
#' @importFrom rlang %||%
NULL
