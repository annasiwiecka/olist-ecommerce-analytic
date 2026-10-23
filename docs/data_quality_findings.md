# Data Quality Findings

## Summary

All 6 simulated issues were detected, and every result is explained against the answer key.
The checks also found 11 real anomalies in the original Olist data.

The biggest business impact does not come from the issues that look most
serious technically. Missing product categories hide **11.5% of revenue**
from the category ranking, while orphan sales (R$ 29,844) and duplicated
orders (+0.9% revenue) have a much smaller effect on totals.

## How the checks were done

The original dataset was deliberately damaged with `src/break_data.py`
(seed 42) to simulate real-world data problems. The damage is logged in
`docs/_answer_key.json`.

The damaged files were loaded as plain text into the `raw` schema
(`src/load_raw.py`) and checked with seven groups of SQL checks in
`sql/quality_checks/`. The checks were written without looking at the
answer key and compared against it afterwards.

| File | What it checks | How |
|---|---|---|
| `01_row_counts.sql` | Rows per table | Manual |
| `02_missing_values.sql` | NULLs in every column | Generated from the database catalog |
| `03_duplicate_keys.sql` | Repeated primary keys | Manual, keys from the ERD |
| `04_orphans.sql` | Child rows without a parent | Manual, relations from the ERD |
| `05_formats.sql` | Values that cannot be cast to the `clean` type | Generated from the `clean` schema |
| `06_value_ranges.sql` | Business rules (prices, scores, order timeline) | Manual |
| `07_text_consistency.sql` | Letter case, accents, whitespace | Manual + generated |

## Business impact

Ordered by impact on reporting. Total item revenue is about R$ 13.56 M.

| Finding | Business impact | Priority | Decision |
|---|---|---|---|
| Products without category (3,854) | 11.5% of revenue is missing from the category ranking. | High | Label as `unknown` so the sales stay visible. |
| Purchase dates in DD/MM/YYYY (10,023) | On a server with month-first date settings, 3,958 orders would silently land in the wrong month, with no error. | High | Parse with an explicit format, never rely on server settings. |
| Inconsistent customer city names (9,944) | 6,168 city spellings collapse into 4,119 real cities; regional charts would show 2,049 duplicate city names. | High | Normalize names (`LOWER`, `btrim`, `unaccent`). |
| Duplicated orders (992) | Joining items to orders without deduplication would overstate revenue by R$ 122,989 (0.9%). | Medium | Keep one row per `order_id`. |
| Orphan order items (228) | R$ 29,844 of sales (about 0.2%) have no order, so no customer, date or status. They also block loading into `clean` because of foreign keys. | Medium | Move to `rejected` with the reason. |
| Negative prices (20) | Revenue understated by R$ 3,549 (0.03%). | Low | Move to `rejected`; the correct value cannot be confirmed. |

## Simulated damage vs. detection

| Damage (answer key) | Expected | Detected by | Result | Note |
|---|---|---|---|---|
| Missing product categories | 3,295 | `02_missing_values.sql` | 3,854 | 610 products had no category in the original; 51 overlap with the simulated ones. |
| City letter case changed | 9,944 | `07_text_consistency.sql` | 9,944 | |
| Deleted orders | 200 | `04_orphans.sql` | 228 orphan items | Deleted orders had several items or none, so the item count differs from 200. |
| Duplicated orders | 992 | `03_duplicate_keys.sql` | 992 | |
| Purchase date in DD/MM/YYYY | 10,023 | `05_formats.sql` | 10,023 | |
| Negative prices | 20 | `06_value_ranges.sql` | 20 | A valid number with a wrong value: caught by ranges, not by formats. |

## Anomalies in the original data

These were not simulated; they exist in the Kaggle dataset.

| Issue | Rows | Check | Decision for `clean` |
|---|---|---|---|
| Cities with accents in `geolocation` (`são paulo` vs `sao paulo`) | 73,442 | 07 | Remove accents; join locations by zip code, not city name. |
| Repeated `review_id` (same review ID on different orders) | 789 | 03 | Primary key becomes `(review_id, order_id)`. |
| Products without category and description | 610 | 02 | Category `unknown`; other fields stay NULL. |
| Orders sent to carrier before purchase | 167 | 06 | Keep and flag; does not affect delivery time to the customer. |
| Payments with value 0 | 9 | 06 | Keep; check `payment_type` during cleaning. |
| Delivery date but status not `delivered` | 6 | 06 | Keep and flag; exclude from delivery analysis. |
| Products with weight 0 | 4 | 06 | Set weight to NULL. |
| Payments with 0 installments | 2 | 06 | Set to 1. |
| City with a trailing space (`salvador `) | 1 | 07 | Trim. |
| Untrimmed review comments and titles | 8,120 / 1,998 | 07 | Trim; free text, not an error. |
| Missing delivery and approval dates | 2,986 / 1,796 / 161 | 02 | Likely cancelled or undelivered orders; columns stay nullable. |

## Technical findings

- **Date parsing depends on server settings.** On this server, all 10,023
  dates in DD/MM/YYYY passed as valid timestamps, but only the ISO pattern
  check flagged them. A server with different date settings would read the
  same text differently. Dates are therefore parsed with an explicit format
  (`to_timestamp(..., 'DD/MM/YYYY HH24:MI')`).
- **Duplicates are removed by key, not by full row.** Some duplicated orders
  also received a changed date format, so full rows are not identical.
- **Geolocation is joined by zip code.** City names differ between tables
  (accents), and zip codes repeat in `geolocation`, so the relation is not a
  foreign key.
- **Checks are generated from metadata where possible.** Missing values,
  formats and whitespace are generated from `information_schema`, so a new
  column is checked automatically. Format checks use the target types from
  the `clean` schema, which is generated from the DBML model.
- **Viewing data in Excel is misleading.** Excel displayed ISO dates as
  DD/MM/YYYY; the raw CSV files use ISO 8601.

## Recommendations for upstream systems

- Prevent deleting orders that still have items, payments or reviews.
- Export all timestamps in ISO 8601 format.
- Store city names in one normalized form, or rely on zip codes only.
- Require a product category when a product is created.

## Key decisions

**Decided**

- **Review primary key is `(review_id, order_id)`.** 789 `review_id` values
  repeat in the original data with different orders. The pair is unique, so
  the data model changes instead of deleting rows.
- **Revenue issues are measured before they are fixed.** Priorities follow
  the financial impact, not the technical severity: missing categories
  (11.5% of revenue) rank above orphans (0.2%) and negative prices (0.03%).

**To resolve during cleaning**

- [ ] Update the DBML model and regenerate the `clean` schema with the
      `(review_id, order_id)` key.
- [ ] Check categories without an English translation; then add translations
      or drop the foreign key.
- [ ] Add an `unknown` row to `product_category_name_translation` so the
      foreign key accepts products without a category.

## Next steps

1. Resolve the remaining decisions above.
2. Write `sql/cleaning/` scripts that load `raw` into `clean`: deduplicate
   orders, parse dates with an explicit format, normalize text, fix or reject
   invalid values.
3. Move rows that cannot be fixed to a `rejected` table with the reason.
4. Re-run the quality checks against `clean` and confirm the issues are resolved.
5. Wrap the steps in `run_pipeline.py` and add unit tests.