# Lightweight on-disk cache for successful responses. Only parsed JSON results
# are stored; the server's "Request Rejected" HTML pages are never cached.

#' Cache directory used by scen
#'
#' @return Path to the directory where responses are cached.
#' @export
scen_cache_dir <- function() {
  d <- getOption("scen.cache_dir", tools::R_user_dir("scen", "cache"))
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  d
}

scen_cache_key <- function(path, query) {
  rlang::hash(list(path = path, query = query))
}

scen_cache_get <- function(path, query) {
  if (!isTRUE(getOption("scen.cache", TRUE))) return(NULL)
  f <- file.path(scen_cache_dir(), paste0(scen_cache_key(path, query), ".rds"))
  if (!file.exists(f)) return(NULL)
  ttl <- getOption("scen.cache_ttl", 86400)
  if (as.numeric(difftime(Sys.time(), file.mtime(f), units = "secs")) > ttl) {
    return(NULL)
  }
  tryCatch(readRDS(f), error = function(e) NULL)
}

scen_cache_set <- function(path, query, value) {
  if (!isTRUE(getOption("scen.cache", TRUE))) return(invisible())
  f <- file.path(scen_cache_dir(), paste0(scen_cache_key(path, query), ".rds"))
  tryCatch(saveRDS(value, f), error = function(e) NULL)
  invisible()
}

#' Clear the scen response cache
#'
#' @return Invisibly, the number of files removed.
#' @export
scen_cache_clear <- function() {
  files <- list.files(scen_cache_dir(), pattern = "\\.rds$", full.names = TRUE)
  unlink(files)
  invisible(length(files))
}
