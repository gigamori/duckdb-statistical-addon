# chi2_test

## Purpose

Pearson χ² test of independence for binary outcomes.

## Inputs

- y_list: HUGEINT[] (0/1 responses)
- x_list: VARCHAR[] (categories), same length as y_list

## Output columns

- statistic: DOUBLE (Pearson χ² statistic)
- df: INTEGER (#categories - 1)
- p_value: DOUBLE (right tail via `chi2_cdf_approx`)
- n_total: BIGINT (valid observations)
- n_groups: BIGINT (distinct categories)

## Notes

- Non 0/1 values are dropped during aggregation.
- Expected counts use the pooled success rate.

## Example

```sql
SELECT *
FROM chi2_test(
  (SELECT LIST(subscribed) FROM customer),
  (SELECT LIST(first_landing_page) FROM customer)
);
```
