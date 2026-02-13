# Basic Functions (CDF approximations)

## standard_normal_cdf_approx(z)

Purpose: Standard normal CDF approximation.

Inputs:
- z: DOUBLE (z-score)

Output: DOUBLE (approximate Φ(z))

Notes:
- Returns NULL when z is NULL.
- Relies on an Abramowitz–Stegun style rational approximation.

Example:

```sql
SELECT standard_normal_cdf_approx(1.96);
```

## chi2_cdf_approx(chi2, df)

Purpose: Chi-squared CDF approximation.

Inputs:
- chi2: DOUBLE (χ² statistic)
- df: DOUBLE/INTEGER (degrees of freedom > 0)

Output: DOUBLE (approximate CDF P[X ≤ chi2] for χ²_df)

Notes:
- Returns NULL when inputs are NULL or df ≤ 0.
- Uses the Wilson–Hilferty transform and the normal CDF approximation.

Example:

```sql
SELECT 1.0 - chi2_cdf_approx(10.5, 4) AS p_right_tail;
```

## t_cdf_approx(t, df)

Purpose: t-distribution CDF approximation.

Inputs:
- t_val: DOUBLE (t statistic)
- df: DOUBLE/INTEGER (degrees of freedom > 0)

Output: DOUBLE (approximate CDF P[T ≤ t] for t_df)

Notes:
- Returns NULL when inputs are NULL or df ≤ 0.
- Uses Abramowitz and Stegun formula 26.7.7 to transform t to z.

Example:

```sql
SELECT t_cdf_approx(2.5, 10);
```
