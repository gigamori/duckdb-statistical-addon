# generalized_cochran_mantel_haenszel_ordinal_test

## Purpose

Generalized Cochran–Mantel–Haenszel correlation test with stratification.

## Inputs

- y_score_list: DOUBLE[] (ordinal outcome scores)
- x_list: VARCHAR[] (exposure labels), same length as y_score_list
- z_list: VARCHAR[] (strata identifiers), same length as y_score_list

## Output columns

- statistic: DOUBLE (χ² statistic for correlation)
- p_value: DOUBLE (right tail via `chi2_cdf_approx`)
- df: INTEGER (degrees of freedom, always 1)
- correlation_sum: DOUBLE (Σ C_k across strata)
- variance_sum: DOUBLE (Σ Var[C_k] across strata)
- n_strata: BIGINT (count of strata contributing to the test)
- n_y_levels: BIGINT (distinct outcome levels)
- n_x_levels: BIGINT (distinct exposure levels)
- n_z_levels: BIGINT (distinct strata levels)
- n_total: BIGINT (valid paired observations)

## Notes

- NULLs are excluded pairwise.
- Strata with fewer than two observations are ignored.
- Exposure labels are ranked in ascending order for scoring.
- Ordinal scores allow extension beyond 0/1 outcomes; bin continuous values (e.g., median per bin) before passing them into `y_score_list`.
- Keep binning and strata reasonably balanced so CMH variance estimates remain stable.

## Example

```sql
SELECT *
FROM generalized_cochran_mantel_haenszel_ordinal_test(
  (SELECT LIST(score) FROM survey_responses),
  (SELECT LIST(treatment_group) FROM survey_responses),
  (SELECT LIST(store_id) FROM survey_responses)
);
```
