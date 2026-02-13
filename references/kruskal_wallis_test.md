# kruskal_wallis_test

## Purpose

Kruskal–Wallis k-sample rank test.

## Inputs

- y_list: DOUBLE[]
- x_list: VARCHAR[] (group labels), same length as y_list

## Output columns

- statistic: DOUBLE (H statistic with tie correction)
- df: INTEGER (k - 1)
- p_value: DOUBLE (right tail via `chi2_cdf_approx`)
- n_groups: BIGINT (distinct groups)
- n_total: BIGINT (valid observations)
- tie_correction_factor: DOUBLE
- effect_size_epsilon_squared: DOUBLE
- excluded_records: BIGINT (removed during validation)
- group_sizes: MAP(VARCHAR, BIGINT)
- rank_sums: MAP(VARCHAR, DOUBLE)

## Notes

- Invalid or blank labels and non-finite values are excluded.
- Tie correction safeguards zero denominators.

## Example

```sql
SELECT *
FROM kruskal_wallis_test(
  (SELECT LIST(revenue) FROM customer),
  (SELECT LIST(first_landing_page) FROM customer)
);
```
