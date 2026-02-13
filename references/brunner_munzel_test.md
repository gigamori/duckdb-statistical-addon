# brunner_munzel_test

## Purpose

Brunner–Munzel test for two independent samples.

## Inputs

- y_list: DOUBLE[] (sample 1 values)
- x_list: DOUBLE[] (sample 2 values)
- alternative: 'two.sided' | 'greater' | 'less'

## Output columns

- statistic: DOUBLE (t statistic)
- p_value: DOUBLE (p-value based on t or normal CDF)
- df: DOUBLE (Welch–Satterthwaite degrees of freedom)
- estimate: DOUBLE (p_hat, stochastic superiority of y over x)
- n_y: BIGINT (sample size of y)
- n_x: BIGINT (sample size of x)
- mean_rank_y: DOUBLE
- mean_rank_x: DOUBLE
- variance_y: DOUBLE
- variance_x: DOUBLE
- alternative: VARCHAR (echoed input)

## Notes

- More powerful than Mann–Whitney U test when variances differ.
- NULLs are excluded pairwise.

## Example

```sql
SELECT *
FROM brunner_munzel_test(
  (SELECT LIST(value) FROM group_a),
  (SELECT LIST(value) FROM group_b),
  'two.sided'
);
```
