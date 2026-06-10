test_that("ROC / Gregorian conversion", {
  expect_identical(roc_to_ad(115), 2026L)
  expect_identical(ad_to_roc(2026), 115L)
})

test_that("scen_period accepts several shapes and converts Gregorian years", {
  expect_identical(scen_period(c(115, 3)), list(year = 115L, month = 3L))
  expect_identical(scen_period(c(2026, 3)), list(year = 115L, month = 3L))
  expect_identical(scen_period(list(year = 2025, month = 12)),
                   list(year = 114L, month = 12L))
})

test_that("scen_arr always yields a list (JSON array)", {
  expect_identical(scen_arr("A"), list("A"))
  expect_length(scen_arr(c("A", "B")), 2L)
  expect_null(scen_arr(NULL))
})

test_that("scen_chunk splits by size", {
  expect_length(scen_chunk(1:10, 4), 3L)
  expect_identical(scen_chunk(1:3, 40), list(1:3))
})

test_that("query serialises dimensions as JSON arrays", {
  q <- scen_build_query(c(115, 3), c(115, 3), list(codes = c("1090", "0840")))
  js <- jsonlite::toJSON(q, auto_unbox = TRUE)
  expect_match(js, '"codes":\\["1090","0840"\\]')
  expect_match(js, '"start":\\{"year":115,"month":3\\}')
})
