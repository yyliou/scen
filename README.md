# scen 

## 1. Overview <img src="man/figures/logo.svg" align="right" height="170" alt="scen hex logo" />

`scen` is an R client for the **Tourism Statistics Database of the Taiwan Tourism
Administration** (交通部觀光署觀光統計資料庫, <https://stat.taiwan.net.tw>). The
site is a JavaScript single-page app with no public API and a signed,
rate-limited backend; `scen` reproduces the request-signing scheme and returns
tidy `tibble`s straight from R.

Its **main purpose** is to download monthly visitor counts for the major scenic /
recreational spots (觀光遊憩據點). It also exposes inbound arrivals (來臺),
outbound departures (出國), and cruise visitors (郵輪), down to the finest
cross-tabulations the site provides (e.g. age × gender × purpose), all
configurable through arguments.

```r
# install.packages("pak")
pak::pak(c("httr2", "jsonlite", "tibble", "rlang", "cli"))
# from this folder:
devtools::document(); devtools::install()
```

## 2. Functions

| Function | Purpose |
|---|---|
| `scen_scenic_spots()` | Main function: monthly visitor counts for scenic/recreational spots. |
| `scen_scenic_spot_list()` / `scen_scenic_params()` | Spot lookup table / raw query-parameter payload. |
| `scen_inbound()` / `scen_inbound_params()` | Inbound arrivals (with cross-tabs) / its dimension codes. |
| `scen_outbound()` / `scen_outbound_params()` | Outbound departures (with cross-tabs) / its dimension codes. |
| `scen_cruise()` / `scen_cruise_params()` | Cruise arrivals (with cross-tabs) / its dimension codes. |
| `scen_api()` | Low-level authenticated GET for endpoints the wrappers do not cover. |
| `scen_token()` | Reproduce the `Authorization` header (mainly for testing). |
| `scen_cache_dir()` / `scen_cache_clear()` | Cache location / clear the response cache. |
| `roc_to_ad()` / `ad_to_roc()` | Convert between Republic-of-China and Gregorian years. |

## 3. Arguments

**`scen_scenic_spots(start, end, codes, batch)`**

| Argument | Description | Default |
|---|---|---|
| `start`, `end` | Period as `c(year, month)`. Years above 1911 are treated as Gregorian and converted to ROC automatically (`c(2026,3)` == `c(115,3)`). | latest month |
| `codes` | Spot codes (see `scen_scenic_spot_list()`); `NULL` means every spot. | `NULL` |
| `batch` | Max codes per request. | server limit (40) |

**`scen_inbound(by, start, end, ...)`** (and `scen_outbound()`, `scen_cruise()`,
same shape). `by` selects the endpoint; named `...` dimension vectors are
inserted into the query, using the keys from the matching `*_params()` payload
(e.g. `countries = c("11010","13110")`, `ages = "A"`, `purposes = "B"`).
Combined-cross endpoints use the **singular** key `gender`; single-dimension
endpoints use the plural `genders`. `start`/`end` accept the same ROC/Gregorian
`c(year, month)` form.

### Endpoints (`by` values)

| Family | Single dimensions | Combined crosses |
|---|---|---|
| inbound | `residence`, `country`, `gender`, `age`, `category`, `idle`, `job`, `purpose`, `map` | `agp`, `agc`, `pgc`, `aap`, `jap` |
| outbound | `destination`, `gender`, `age`, `idle`, `map` | `agd` |
| cruise | `cruise`, `gender`, `port` | `rg`, `rp`, `gp`, `rgp` |

Dimension keys come from the matching `*_params()` payload and are passed
verbatim, so any endpoint is reachable even if not wrapped explicitly. For
anything exotic, call `scen_api()` directly.

**Options** (set via `options()`): `scen.cache` (default `TRUE`),
`scen.cache_ttl` (`86400` s), `scen.cache_dir`, `scen.delay` (`1.5` s minimum
between requests), `scen.max_tries` (`6`), `scen.user_agent`.

## 4. Output codebook

`scen_scenic_spots()` returns one row per spot per month, with columns including
`year`, `month`, `count`, `city`, `cityName`, `type`, `typeName`, `code`,
`name`, `nameEn`. **Years are ROC years** throughout; use `roc_to_ad()` to
convert.

`scen_inbound()` / `scen_outbound()` / `scen_cruise()` return tibbles of counts
whose columns depend on the chosen `by` (the selected dimensions plus the count).
`scen_scenic_spot_list()` returns `code`, `name`, `eName`, `location` (city
code), `type` (category code). The `*_params()` helpers return named lists of
lookup tables (available year-months and the code table for each dimension).

## 5. Examples

```r
library(scen)

# Every spot, latest available month (auto-batched to the 40-code limit):
scen_scenic_spots()

# A date range for selected spots (Gregorian years accepted):
scen_scenic_spots(start = c(2025, 1), end = c(2025, 12),
                  codes = c("0840", "1090"))

# Discover dimensions, then fetch Japan arrivals for the latest month:
scen_inbound_params()
scen_inbound("residence", countries = "11010")

# Finest inbound cross: age x gender x purpose for all of 2025:
scen_inbound("agp", start = c(2025, 1), end = c(2025, 12),
             ages = "A", gender = "M", purposes = "B")

# Every country, auto-batched to respect the 40-code limit:
p <- scen_inbound_params()
scen_inbound("country", countries = p$countries$code)

# Outbound (age x gender x destination) and cruise (by gender):
scen_outbound("agd", ages = "A", gender = "M", countries = "31026")
scen_cruise("gender", genders = c("M", "F"))
```

## 6.
