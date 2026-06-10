# Deterministic vectors captured from the live site. These verify that the
# reverse-engineered signing algorithm is reproduced exactly, without network.

test_that("scen_token matches captured site tokens", {
  expect_identical(scen_token(1781056649404), "MTc4MTA1NjY0OTQwNDo6MjU3MDAw")
  expect_identical(scen_token(1781056811955), "MTc4MTA1NjgxMTk1NTo6NTMzMjg3")
})

test_that("scen_token round-trips to '<ts>::<6-digit>'", {
  tok <- scen_token(1781056649404)
  raw <- rawToChar(jsonlite::base64_dec(tok))
  expect_match(raw, "^[0-9]+::[0-9]{6}$")
  expect_identical(raw, "1781056649404::257000")
})

test_that("scen_token uses the current time by default", {
  before <- floor(as.numeric(Sys.time()) * 1000)
  tok <- scen_token()
  ts <- as.numeric(sub("::.*$", "", rawToChar(jsonlite::base64_dec(tok))))
  expect_gte(ts, before - 5000)
})
