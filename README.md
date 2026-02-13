# DuckDB Statistical Functions

A collection of pure-SQL statistical testing functions implemented as DuckDB UDFs. No extensions or external libraries required — everything runs inside DuckDB's SQL engine.

## Motivation

DuckDB ships with rich aggregate and window functions, but lacks built-in support for common statistical hypothesis tests such as the Brunner-Munzel test, Kruskal-Wallis test, or Cochran-Armitage trend test. This library fills that gap with pure-SQL scalar and table-valued macros that can be loaded with a single `CREATE FUNCTION` script.

## Features

- Pure SQL — no C/C++ extensions, no Python UDFs
- Works with any DuckDB client (CLI, Python, R, Node.js, WASM, …)
- Handles tied observations and applies appropriate corrections
- Includes internal CDF approximations (normal, chi-squared, t) so results are self-contained

## Provided Functions

### Hypothesis Tests

| Function | Description |
|----------|-------------|
| `brunner_munzel_test(y, x, alternative)` | Two-sample rank test robust to unequal variances |
| `kruskal_wallis_test(y, x)` | k-sample rank test with tie correction and epsilon-squared effect size |
| `chi2_test(y, x)` | Pearson's chi-squared test of independence for binary outcome × k categories |
| `cochran_armitage_test(y, x, alternative, correction)` | Trend test for binary outcome across ordered categories (optional Yates correction) |
| `jonckheere_terpstra_test(y, x, alternative)` | Trend test for a continuous variable across ordered categories |
| `generalized_cochran_mantel_haenszel_ordinal_test(y, x, z)` | Stratified ordinal correlation test adjusting for a confounder |

### Information-Theoretic Measures

| Function | Description |
|----------|-------------|
| `normalized_entropy_continuous(arr)` | Normalized Shannon entropy for a continuous variable (scalar, 0–1) |
| `normalized_entropy_continuous_tbl(arr)` | Same as above, returning a table with raw entropy, bin count, and normalized entropy |
| `normalized_entropy_category(arr)` | Normalized Shannon entropy for a categorical variable (scalar, 0–1) |
| `normalized_entropy_category_tbl(arr)` | Same as above, returning a table with raw entropy, unique-count, and normalized entropy |

### Internal Helpers

These functions are used internally by the tests above. You generally do not need to call them directly.

| Function | Description |
|----------|-------------|
| `standard_normal_cdf_approx(z)` | Standard normal CDF (Abramowitz & Stegun approximation) |
| `chi2_cdf_approx(chi2, df)` | Chi-squared CDF (Wilson-Hilferty transformation) |
| `t_cdf_approx(t_val, df)` | Student's t CDF (Abramowitz & Stegun formula 26.7.7) |

## Documentation

Each function has a detailed reference manual in the `references/` directory covering usage, parameters, return columns, and worked examples.

| Function | Reference |
|----------|-----------|
| Internal CDF helpers | [basic.md](references/basic.md) |
| `brunner_munzel_test` | [brunner_munzel_test.md](references/brunner_munzel_test.md) |
| `kruskal_wallis_test` | [kruskal_wallis_test.md](references/kruskal_wallis_test.md) |
| `chi2_test` | [chi2_test.md](references/chi2_test.md) |
| `cochran_armitage_test` | [cochran_armitage_test.md](references/cochran_armitage_test.md) |
| `jonckheere_terpstra_test` | [jonckheere_terpstra_test.md](references/jonckheere_terpstra_test.md) |
| `generalized_cochran_mantel_haenszel_ordinal_test` | [generalized_cochran_mantel_haenszel_ordinal_test.md](references/generalized_cochran_mantel_haenszel_ordinal_test.md) |
| `normalized_entropy_*` | [normalized_entropy.md](references/normalized_entropy.md) |

Japanese versions (`*_ja.md`) are also available in the same directory.

## Quick Start

```sql
-- 1. Load all functions
.read statistical_processing.sql

-- 2. Run a Brunner-Munzel test
SELECT * FROM brunner_munzel_test(
  [5.0, 7.0, 3.0, 8.0, 6.0],
  [2.0, 4.0, 1.0, 3.0, 5.0],
  'two.sided'
);

-- 3. Run a Kruskal-Wallis test
SELECT * FROM kruskal_wallis_test(
  [10.0, 12.0, 14.0, 8.0, 9.0, 15.0],
  ['A', 'A', 'B', 'B', 'C', 'C']
);

-- 4. Compute normalized entropy for a continuous variable
SELECT normalized_entropy_continuous([1.0, 2.0, 3.0, 4.0, 5.0, 5.0, 6.0, 7.0]);
```

## Function Signatures

### `brunner_munzel_test(y_list DOUBLE[], x_list DOUBLE[], alternative VARCHAR)`

Returns: `statistic`, `p_value`, `df`, `estimate` (P(Y > X)), `n_y`, `n_x`, `mean_rank_y`, `mean_rank_x`, `variance_y`, `variance_x`, `alternative`

`alternative`: `'two.sided'` | `'greater'` | `'less'`

### `kruskal_wallis_test(y_list DOUBLE[], x_list VARCHAR[])`

Returns: `statistic` (H), `df`, `p_value`, `n_groups`, `n_total`, `tie_correction_factor`, `effect_size_epsilon_squared`

### `chi2_test(y_list HUGEINT[], x_list VARCHAR[])`

Returns: `statistic`, `df`, `p_value`, `n_total`, `n_groups`

`y_list` must contain binary values (0 or 1).

### `cochran_armitage_test(y_list HUGEINT[], x_list VARCHAR[], alternative VARCHAR, correction VARCHAR)`

Returns: `statistic`, `statistic_uncorrected`, `p_value`, `n_total`, `n_success`, `n_groups`, `numerator_raw`, `variance_raw`

`correction`: `'yates'` | `'none'`

### `jonckheere_terpstra_test(y_list DOUBLE[], x_list VARCHAR[], alternative VARCHAR)`

Returns: `u_statistic`, `variance`, `statistic` (z), `p_value`, `n_total`, `expected_u`, `alternative`, `n_groups`, `tie_correction_term`

### `generalized_cochran_mantel_haenszel_ordinal_test(y_score_list DOUBLE[], x_list VARCHAR[], z_list VARCHAR[])`

Returns: `statistic`, `p_value`, `df`, `correlation_sum`, `variance_sum`, `n_strata`, `n_y_levels`, `n_x_levels`, `n_z_levels`, `n_total`

### `normalized_entropy_continuous(input_array DOUBLE[])` → `DOUBLE`

Returns a scalar between 0.0 (no variation) and 1.0 (maximum entropy). Uses Freedman-Diaconis rule for binning.

### `normalized_entropy_category(input_array ANY[])` → `DOUBLE`

Returns a scalar between 0.0 and 1.0.

## Requirements

- DuckDB ≥ 1.4.2

## Numerical Methods

The CDF approximations use well-known numerical recipes:

- Standard normal CDF: Abramowitz & Stegun polynomial approximation (error < 7.5 × 10⁻⁸)
- Chi-squared CDF: Wilson-Hilferty cube-root transformation to normal
- Student's t CDF: Abramowitz & Stegun formula 26.7.7

These are sufficient for typical hypothesis-testing use cases. For extreme tail probabilities or very small degrees of freedom, consider using a language with dedicated statistical libraries.

## License

MIT License — see [LICENSE](LICENSE) for the full text.
