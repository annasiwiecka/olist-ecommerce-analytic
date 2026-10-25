# Data Quality Findings

## Summary

All 6 simulated issues were detected. Where a count differs from the answer
key, the difference comes from problems already present in the original data.
The checks also found 11 anomalies that were not simulated.

Measured by revenue, the largest issue is missing product categories:
11.5% of revenue is absent from the category ranking. Duplicated orders
(+0.9% revenue) and orphan order items (R$ 29,844, about 0.2%) have a much
smaller effect on totals.

## Method

The original dataset was deliberately damaged with `src/break_data.py`
(seed 42). The damage is logged in `docs/_answer_key.json`.

The damaged files were loaded as plain text into the `raw` schema
(`src/load_raw.py`) and checked with seven groups of SQL checks in
`sql/quality_checks/`. The checks were written without looking at the
answer key and compared against it afterwards.

| File | What it checks | How |
|---|---|---|
| `01_row_counts.sql` | Rows per table | Manual |
| `02_missing_values.sql` | NULLs in every column | Generated from `information_schema` |
| `03_duplicate_keys.sql` | Repeated primary keys | Manual, keys from the ERD |
| `04_orphans.sql` | Child rows without a parent | Manual, relations from the ERD |
| `05_formats.sql` | Values that cannot be cast to the `clean` type | Generated from the `clean` schema |
| `06_value_ranges.sql` | Business rules (prices, scores, order timeline) | Manual |
| `07_text_consistency.sql` | Letter case, accents, whitespace | Manual and generated |

## Business impact

Ordered by impact on reporting. Total item revenue is about R$ 13.56 M.

| Finding | Business impact | Priority | Decision |
|---|---|---|---|
| Products without category (3,854) | 11.5% of revenue is missing from the category ranking. | High | Label as `unknown` so the sales stay visible. |
| Purchase dates in DD/MM/YYYY (10,023) | On a server with month-first date settings, 3,958 orders would land in the wrong month without any error. | High | Parse with an explicit format. |
| Inconsistent customer city names (9,944) | 6,168 spellings map to 4,119 cities, so regional charts would show 2,049 duplicate city names. | High | Normalize names (`LOWER`, `btrim`, `unaccent`). |
| Duplicated orders (992) | Joining items to orders without deduplication overstates revenue by R$ 122,989 (0.9%). | Medium | Keep one row per `order_id`. |
| Orphan order items (228) | R$ 29,844 of sales (about 0.2%) have no customer, date or status. They also violate the foreign keys in `clean`. | Medium | Move to `rejected` with the reason. |
| Negative prices (20) | Revenue understated by R$ 3,549 (0.03%). | Low | Move to `rejected`; the correct value cannot be confirmed. |

## Simulated damage vs. detection

| Damage (answer key) | Expected | Detected by | Result | Note |
|---|---|---|---|---|
| Missing product categories | 3,295 | `02_missing_values.sql` | 3,854 | 610 products had no category in the original; 51 overlap with the simulated ones. |
| City letter case changed | 9,944 | `07_text_consistency.sql` | 9,944 | |
| Deleted orders | 200 | `04_orphans.sql` | 228 orphan items | Deleted orders had several items or none, so the item count differs from 200. |
| Duplicated orders | 992 | `03_duplicate_keys.sql` | 992 | |
| Purchase dates in DD/MM/YYYY | 10,023 | `05_formats.sql` | 10,023 | |
| Negative prices | 20 | `06_value_ranges.sql` | 20 | A valid number with a wrong value: caught by the range check, not the format check. |

## Anomalies in the original data

Not simulated; present in the Kaggle dataset.

| Issue | Rows | Check | Decision for `clean` |
|---|---|---|---|
| City names with accents in `geolocation` (`são paulo` vs `sao paulo`) | 73,442 | 07 | Remove accents; join locations by zip code, not city name. |
| Same `review_id` on different orders | 789 | 03 | Primary key becomes `(review_id, order_id)`. |
| Products without category, name and description | 610 | 02 | Category `unknown`; other fields stay NULL. |
| Orders sent to carrier before purchase | 167 | 06 | Keep and flag; does not affect delivery time to the customer. |
| Payments with value 0 | 9 | 06 | Keep; check `payment_type` during cleaning. |
| Delivery date but status not `delivered` | 6 | 06 | Keep and flag; exclude from delivery analysis. |
| Products with weight 0 | 4 | 06 | Set weight to NULL. |
| Payments with 0 installments | 2 | 06 | Set to 1. |
| City with a trailing space (`salvador `) | 1 | 07 | Trim. |
| Untrimmed review comments and titles | 8,120 / 1,998 | 07 | Trim; free text, not an error. |
| Missing delivery and approval dates | 2,986 / 1,796 / 161 | 02 | Likely cancelled or undelivered orders; columns stay nullable. |

## Technical findings

- Date parsing depends on server settings. On this server, all 10,023 dates
  in DD/MM/YYYY were accepted as valid timestamps; only the ISO pattern check
  flagged them. A server with different settings could read the same text
  differently, so dates are parsed with an explicit format
  (`to_timestamp(..., 'DD/MM/YYYY HH24:MI')`).
- Duplicates are removed by key, not by full row. Some duplicated orders also
  received a changed date format, so the full rows are not identical.
- `geolocation` is joined by zip code without a foreign key, because zip
  codes repeat in that table and city names differ between tables.
- Checks for missing values, formats and whitespace are generated from
  `information_schema`, so new columns are covered automatically. The format
  check takes target types from the `clean` schema, which is generated from
  the DBML model.
- The first version of the format check generator joined `raw` and `clean`
  columns by table name only (`c.column_name = c.column_name` instead of
  `c.column_name = r.column_name`), so each column was tested against the
  types of every other column. SQL raised no error; the bug showed up only
  as 259 result rows instead of 35. Row counts of check results are now
  verified before the results are interpreted.
- Excel displayed the ISO timestamps as DD/MM/YYYY; the raw CSV files use
  ISO 8601. Source files are inspected in a text editor, not in Excel.

## Recommendations for upstream systems

- Prevent deleting orders that still have items, payments or reviews.
- Export all timestamps in ISO 8601 format.
- Store city names in one normalized form, or rely on zip codes only.
- Require a product category when a product is created.

## Decisions

Decided:

- The primary key of `order_reviews` is `(review_id, order_id)`. 789
  `review_id` values repeat with different orders, but the pair is unique,
  so the data model changes instead of rows being deleted.
- Issues are prioritized by their effect on revenue, not by technical
  severity.

To resolve during cleaning:

- [ ] Update the DBML model and regenerate the `clean` schema with the new
      `order_reviews` key.
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