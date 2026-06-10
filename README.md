# scen <img src="man/figures/logo.svg" align="right" height="170" alt="scen hex logo" />

An R client for the **Tourism Statistics Database of the Taiwan Tourism
Administration** (交通部觀光署觀光統計資料庫, <https://stat.taiwan.net.tw>).

The site is a JavaScript single-page app with no public API and a signed,
rate-limited backend. `scen` reproduces the request-signing scheme and gives
you tidy `tibble`s straight from R.

* **Main purpose** — download visitor counts for the major scenic /
  recreational spots (觀光遊憩據點).
* Plus inbound arrivals (來臺), outbound departures (出國) and cruise visitors
  (郵輪), **down to the finest cross-tabulations** the site exposes
  (e.g. age × gender × purpose), all configurable through arguments.

## Installation

```r
# install.packages("pak")
pak::pak("httr2"); pak::pak("jsonlite"); pak::pak("tibble"); pak::pak("rlang"); pak::pak("cli")

# from this folder:
remotes::install_github("yyliou/scen")
```

`devtools::load_all()` works for development without building docs first.

## Scenic / recreational spots (main function)

```r
library(scen)

# Every spot, latest available month (auto-batched to the 40-code limit):
spots <- scen_scenic_spots()

# A date range for selected spots. Gregorian years are accepted and converted
# to ROC (民國) automatically: c(2025, 1) == c(114, 1).
scen_scenic_spots(
  start = c(2025, 1), end = c(2025, 12),
  codes = c("0840", "1090")
)

# Look-ups (codes, names, the city/category hierarchy, the available months):
scen_scenic_spot_list()
scen_scenic_params()
```

Returned columns include `year`, `month`, `count`, `city`, `cityName`,
`type`, `typeName`, `code`, `name`, `nameEn`. Years are ROC years; use
`roc_to_ad()` to convert.

## Inbound / outbound / cruise (cross-tabulations)

Each family has a `*_params()` helper that lists the valid dimension codes,
and a worker where `by` selects the endpoint and named `...` arguments become
the query dimensions.

```r
# Discover dimensions & codes:
scen_inbound_params()    # ages, age2s, categories, genders, idles, jobs,
                         # modeAndPort, purposes, countries, countryLimit

# Japan arrivals, latest month:
scen_inbound("residence", countries = "11010")

# Finest inbound cross: age × gender × purpose for all of 2025
scen_inbound("agp", start = c(2025, 1), end = c(2025, 12),
             ages = "A", gender = "M", purposes = "B")

# Every country, auto-batched to respect the 40-code limit:
p <- scen_inbound_params()
scen_inbound("country", countries = p$countries$code)

# Outbound: age × gender × destination
scen_outbound("agd", ages = "A", gender = "M", countries = "31026")

# Cruise: by gender, and discover keys:
scen_cruise("gender", genders = c("M", "F"))
scen_cruise_params()
```

### Endpoints (`by` values)

| Family   | Single dimensions                                              | Combined crosses                          |
|----------|---------------------------------------------------------------|-------------------------------------------|
| inbound  | `residence`, `country`, `gender`, `age`, `category`, `idle`, `job`, `purpose`, `map` | `agp`, `agc`, `pgc`, `aap`, `jap` |
| outbound | `destination`, `gender`, `age`, `idle`, `map`                 | `agd`                                     |
| cruise   | `cruise`, `gender`, `port`                                    | `rg`, `rp`, `gp`, `rgp`                    |

Dimension keys come from the matching `*_params()` payload and are passed
through verbatim, so any endpoint is reachable even if it is not wrapped
explicitly. The combined-cross endpoints use the **singular** key `gender`
(matching the website); single-dimension endpoints use the plural `genders`.
For anything exotic, call [`scen_api()`] directly.

## How it works / caveats

* **Signing.** Every `/data/api/*` request needs an `Authorization` header of
  the form `base64("<ms-timestamp>::<6-digit-code>")`, where the code is
  derived from the timestamp and a key baked into the site. `scen_token()`
  reproduces this exactly (verified against captured tokens in the tests) and a
  fresh token is generated for every request.
* **Rate limiting.** The backend (an F5 BIG-IP WAF) blocks bursts with a
  "Request Rejected" page. `scen` throttles requests (`options(scen.delay=)`,
  default 1.5s) and retries with exponential back-off
  (`options(scen.max_tries=)`). If you still get blocked, slow down or wait a
  minute.
* **Caching.** Successful responses are cached on disk
  (`scen_cache_dir()`), controlled by `options(scen.cache=, scen.cache_ttl=)`.
  Clear it with `scen_cache_clear()`.
* **Years** are Republic-of-China (民國) years throughout; helpers
  `roc_to_ad()` / `ad_to_roc()` convert.

## Note on `全台觀光遊憩據點座標.csv`

That file in this folder is a separate earlier deliverable (all 417 scenic
spots with coordinates) and is excluded from the package build via
`.Rbuildignore`.

## Disclaimer

This package accesses a public government website by reproducing the requests
its own front-end makes. Please use it responsibly, keep the default
throttling on, and respect the source. Data © 交通部觀光署.
