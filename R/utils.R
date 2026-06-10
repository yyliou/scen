#' Convert between Republic-of-China (Minguo) and Gregorian years
#'
#' The statistics database expresses every year as a Republic-of-China
#' (Minguo / 民國) year, where ROC year `y` equals Gregorian year `y + 1911`.
#'
#' @param year Integer vector of years.
#' @return Integer vector of converted years.
#' @examples
#' roc_to_ad(115) # 2026
#' ad_to_roc(2026) # 115
#' @export
roc_to_ad <- function(year) as.integer(year) + 1911L

#' @rdname roc_to_ad
#' @export
ad_to_roc <- function(year) as.integer(year) - 1911L

# Coerce a user-supplied period into the API's {year, month} (ROC) shape.
#
# Accepts:
#   * a length-2 numeric vector c(year, month)
#   * a list(year = , month = )
#   * a one-row data.frame with columns year, month
# Years greater than 1911 are treated as Gregorian and converted to ROC.
scen_period <- function(x) {
  if (is.data.frame(x)) x <- as.list(x[1, , drop = TRUE])
  if (is.list(x)) {
    y <- x$year %||% x[[1]]
    m <- x$month %||% x[[2]]
  } else {
    x <- as.numeric(x)
    if (length(x) != 2L) {
      cli::cli_abort("A period must be {.code c(year, month)} or {.code list(year=, month=)}.")
    }
    y <- x[[1]]
    m <- x[[2]]
  }
  y <- as.integer(y)
  if (y > 1911L) y <- ad_to_roc(y)
  list(year = y, month = as.integer(m))
}

# Ensure a value serialises to a JSON array (even when length 1).
scen_arr <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.list(x)) return(x)
  as.list(x)
}

# Split a vector into chunks of at most `size`.
scen_chunk <- function(x, size) {
  if (length(x) <= size) return(list(x))
  unname(split(x, ceiling(seq_along(x) / size)))
}

`%||%` <- rlang::`%||%`
