# jonckheere_terpstra_test

## Purpose

Jonckheere–Terpstra ordered alternative test.

## Inputs

- y_list: DOUBLE[]
- x_list: VARCHAR[] (ordered labels), same length as y_list
- alternative: 'two.sided' | 'greater' | 'less'

## Output columns

- u_statistic: DOUBLE (U statistic)
- variance: DOUBLE (variance after tie adjustment)
- statistic: DOUBLE (z statistic)
- p_value: DOUBLE (tail selected by `alternative`)
- n_total: BIGINT (valid observations)
- expected_u: DOUBLE (expected U under H0)
- alternative: VARCHAR (echoed input)
- n_groups: BIGINT (distinct ordered labels)
- tie_correction_term: DOUBLE (tie adjustment term T)

## Notes

- Requires at least two groups, N ≥ 2, and positive variance.
- NULLs are excluded pairwise.

## Example

```sql
SELECT *
FROM jonckheere_terpstra_test(
  (SELECT LIST(revenue) FROM customer),
  (SELECT LIST(LPAD(pageviews_detail::varchar, 3, '0')) FROM customer),
  'greater'
);
```
