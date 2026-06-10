# Request-signing scheme used by stat.taiwan.net.tw.
#
# Every call to /data/api/* must carry an `Authorization` header. The site's
# Angular app builds it with an HTTP interceptor (reverse-engineered from the
# bundle, module 6232 / 92340). The algorithm is:
#
#   ts  = Date.now()                         # milliseconds since epoch
#   key = "8LfAfRQUAATEDGApQ_Xpg7cueSHFtz-kTOnNP452h"   # baked-in OTP key
#   t   = charCodeAt() of every key character
#   n   = 15 & t[last]                        # 0-based offset into the key (= 8)
#   o   = 0
#   for i in 0..2:  o = (o << 8) | (255 & (t[n+i] ^ ts))
#   x   = (0x7FFFFF & o) %% 1e6               # zero-padded to 6 digits
#   token = base64("<ts>::<x>")
#
# Because `& 255` is applied, only the low byte of `ts` matters, i.e.
# `t[n+i] ^ (ts %% 256)`. The server validates that `x` matches `ts` *and*
# that `ts` is fresh, so the token must be generated per request.

.scen_otp_key <- "8LfAfRQUAATEDGApQ_Xpg7cueSHFtz-kTOnNP452h"

#' Generate an API authorisation token
#'
#' Reproduces the `Authorization` header expected by the statistics database.
#' You normally do not need to call this directly; [scen_api()] adds a fresh
#' token to every request.
#'
#' @param ts Milliseconds since the Unix epoch. Defaults to the current time.
#'   Supplying a value is mainly useful for testing.
#' @return A base64 string suitable for the `Authorization` header.
#' @examples
#' # Deterministic test vector captured from the live site:
#' identical(scen_token(1781056649404), "MTc4MTA1NjY0OTQwNDo6MjU3MDAw")
#' @export
scen_token <- function(ts = NULL) {
  if (is.null(ts)) ts <- floor(as.numeric(Sys.time()) * 1000)
  ts_chr <- format(ts, scientific = FALSE, trim = TRUE)
  ts_num <- as.numeric(ts_chr)

  key <- utf8ToInt(.scen_otp_key)
  n0  <- bitwAnd(15L, key[length(key)])      # 0-based offset
  low <- as.integer(ts_num %% 256)

  o <- 0L
  for (i in 0:2) {
    b <- bitwXor(key[n0 + i + 1L], low)      # +1: R is 1-indexed
    o <- bitwOr(bitwShiftL(o, 8L), b)
  }
  x <- bitwAnd(8388607L, o) %% 1000000L

  payload <- paste0(ts_chr, "::", sprintf("%06d", x))
  jsonlite::base64_enc(charToRaw(payload))
}
