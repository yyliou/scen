# Shared cross-tabulation search used by inbound / outbound / cruise.
#
# `group`  : API group prefix, e.g. "inbound", "outbound", "cruise/visitor".
# `by`     : endpoint suffix below ".../search/", e.g. "residence", "agp".
# `dims`   : named list of dimension vectors placed into the query JSON.
# If exactly one dimension is longer than the per-request limit it is fetched
# in batches and the results are row-bound.
scen_cross_search <- function(group, by, start, end, dims,
                              params_fun, limit = 40L) {
  if (is.null(start) || is.null(end)) {
    p <- params_fun()
    latest <- scen_latest_period(p)
    if (is.null(start)) start <- latest
    if (is.null(end))   end   <- start
  }
  dims <- Filter(Negate(is.null), dims)
  path <- paste0(group, "/search/", by)

  big <- names(dims)[vapply(dims, function(v) length(v) > limit, logical(1))]
  if (length(big) == 0L) {
    out <- scen_api(path, scen_build_query(start, end, dims))
    return(tibble::as_tibble(out))
  }
  if (length(big) > 1L) {
    cli::cli_abort(c(
      "Dimensions {.val {big}} each exceed the per-request limit ({limit}).",
      i = "Split the call so that at most one dimension is over the limit."
    ))
  }
  bn <- big[[1]]
  pieces <- lapply(scen_chunk(dims[[bn]], limit), function(chunk) {
    d <- dims
    d[[bn]] <- chunk
    out <- scen_api(path, scen_build_query(start, end, d))
    if (length(out) == 0L || (is.data.frame(out) && nrow(out) == 0L)) NULL else out
  })
  pieces <- Filter(Negate(is.null), pieces)
  if (length(pieces) == 0L) return(tibble::tibble())
  tibble::as_tibble(do.call(rbind, pieces))
}
