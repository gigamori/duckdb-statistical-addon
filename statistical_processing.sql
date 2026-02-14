-- MIT License
--
-- Copyright (c) 2026 Takamichi Yanai
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- =============================================================================
-- Standard Normal CDF Approximation
-- =============================================================================
CREATE OR REPLACE FUNCTION standard_normal_cdf_approx(z) AS (
  CASE
    WHEN z IS NULL THEN NULL
    ELSE (
      SELECT
        -- CDF: Φ(z)
        -- z > 0: Φ(z) = 1 - Q(|z|) = 1 - complementary_cdf
        -- z < 0: Φ(z) = Q(|z|) = complementary_cdf
        IF(z > 0, 1.0 - complementary_cdf, complementary_cdf)
      FROM (
        SELECT
          -- Abramowitz and Stegun approximation (complementary CDF: Q(|z|) = 1 - Φ(|z|))
          (1.0 / SQRT(2.0 * PI())) * EXP(-z_abs * z_abs / 2.0) * t *
          (0.319381530 + t * (-0.356563782 + t * (1.781477937 + 
           t * (-1.821255978 + t * 1.330274429)))) AS complementary_cdf
        FROM (
          SELECT
            ABS(z) AS z_abs,
            -- Rational approximation parameter for normal CDF
            1.0 / (1.0 + 0.2316419 * ABS(z)) AS t
        )
      )
    )
  END
);

-- =============================================================================
-- Chi-squared CDF Approximation
-- =============================================================================
CREATE OR REPLACE FUNCTION chi2_cdf_approx(chi2, df) AS (
  CASE
    WHEN chi2 IS NULL OR df IS NULL OR df <= 0 THEN NULL
    ELSE (
      SELECT
        -- CDF: Φ(z)
        -- z > 0: Φ(z) = 1 - Q(|z|) = 1 - complementary_cdf
        -- z < 0: Φ(z) = Q(|z|) = complementary_cdf
        IF(z > 0, 1.0 - complementary_cdf, complementary_cdf)
      FROM (
        SELECT
          z,
          -- Abramowitz and Stegun approximation (complementary CDF: Q(|z|) = 1 - Φ(|z|))
          (1.0 / SQRT(2.0 * PI())) * EXP(-z * z / 2.0) * t *
          (0.319381530 + t * (-0.356563782 + t * (1.781477937 + 
           t * (-1.821255978 + t * 1.330274429)))) AS complementary_cdf
        FROM (
          SELECT
            -- Wilson-Hilferty transformation: chi-squared to approximately normal
            (POWER(chi2 / df, 1.0/3.0) - (1.0 - 2.0 / (9.0 * df))) / 
            SQRT(2.0 / (9.0 * df)) AS z,
            -- Rational approximation parameter for normal CDF
            1.0 / (1.0 + 0.2316419 * ABS(
              (POWER(chi2 / df, 1.0/3.0) - (1.0 - 2.0 / (9.0 * df))) / 
              SQRT(2.0 / (9.0 * df))
            )) AS t
        )
      )
    )
  END
);

-- =============================================================================
-- t-distribution CDF Approximation
-- =============================================================================
CREATE OR REPLACE FUNCTION t_cdf_approx(t_val, df) AS (
  CASE
    WHEN t_val IS NULL OR df IS NULL OR df <= 0 THEN NULL
    ELSE (
      SELECT
        -- CDF: Φ(z)
        -- z > 0: Φ(z) = 1 - Q(|z|) = 1 - complementary_cdf
        -- z < 0: Φ(z) = Q(|z|) = complementary_cdf
        IF(z > 0, 1.0 - complementary_cdf, complementary_cdf)
      FROM (
        SELECT
          z,
          -- Abramowitz and Stegun approximation (complementary CDF: Q(|z|) = 1 - Φ(|z|))
          (1.0 / SQRT(2.0 * PI())) * EXP(-z * z / 2.0) * t *
          (0.319381530 + t * (-0.356563782 + t * (1.781477937 +
           t * (-1.821255978 + t * 1.330274429)))) AS complementary_cdf
        FROM (
          SELECT
            -- Transform t-distribution to approximately standard normal z
            -- Source: Abramowitz and Stegun formula 26.7.7
            t_val * (1.0 - 1.0 / (4.0 * df)) / SQRT(1.0 + (t_val * t_val) / (2.0 * df)) AS z,
            -- Rational approximation parameter for normal CDF
            1.0 / (1.0 + 0.2316419 * ABS(
              t_val * (1.0 - 1.0 / (4.0 * df)) / SQRT(1.0 + (t_val * t_val) / (2.0 * df))
            )) AS t
        )
      )
    )
  END
);

-- =============================================================================
-- Brunner-Munzel Test (Two-Sample Rank Test)
-- =============================================================================
CREATE OR REPLACE FUNCTION brunner_munzel_test(
  y_list DOUBLE[], 
  x_list DOUBLE[],
  alternative VARCHAR
) AS TABLE (
  WITH 
  input_data AS (
    SELECT
      UNNEST(y_list) as y_value,
      UNNEST(x_list) as x_value
  ),
  -- Step 1: Convert y and x data to long format
  combined_data AS (
    SELECT 'y' AS grp, y_value AS val FROM input_data WHERE y_value IS NOT NULL AND x_value IS NOT NULL
    UNION ALL
    SELECT 'x' AS grp, x_value AS val FROM input_data WHERE y_value IS NOT NULL AND x_value IS NOT NULL
  ),
  -- Step 2: Calculate row numbers for overall and within-group
  initial_ranks AS (
    SELECT
      grp,
      val,
      ROW_NUMBER() OVER (ORDER BY val) AS rn_combined,
      ROW_NUMBER() OVER (PARTITION BY grp ORDER BY val) AS rn_within
    FROM combined_data
  ),
  -- Step 3: Calculate mean ranks for tied values
  all_ranks AS (
    SELECT
      grp,
      val,
      AVG(rn_combined) OVER (PARTITION BY val) AS rank_combined,
      AVG(rn_within) OVER (PARTITION BY grp, val) AS rank_within
    FROM initial_ranks
  ),
  -- Step 4: Optimized conditional aggregation for both groups
  pivoted_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE grp = 'y') AS n_y,
      COUNT(*) FILTER (WHERE grp = 'x') AS n_x,
      AVG(rank_combined) FILTER (WHERE grp = 'y') AS mean_rank_y,
      AVG(rank_combined) FILTER (WHERE grp = 'x') AS mean_rank_x,
      VAR_SAMP(rank_combined - rank_within) FILTER (WHERE grp = 'y') AS var_rank_diff_y,
      VAR_SAMP(rank_combined - rank_within) FILTER (WHERE grp = 'x') AS var_rank_diff_x
    FROM all_ranks
  ),
  -- Step 5: Calculate test parameters
  test_params AS (
    SELECT
      *,
      (mean_rank_y - (n_y + 1) / 2.0) / n_x AS p_hat,
      var_rank_diff_y / (n_x * n_x) AS s2_y,
      var_rank_diff_x / (n_y * n_y) AS s2_x
    FROM pivoted_stats
  ),
  -- Step 6: Calculate final test statistic and degrees of freedom
  final_calc AS (
    SELECT
      n_y,
      n_x,
      mean_rank_y,
      mean_rank_x,
      p_hat,
      s2_y,
      s2_x,
      (p_hat - 0.5) / SQRT(GREATEST((s2_y / n_y) + (s2_x / n_x), 1e-16)) AS statistic,
      GREATEST(
        POWER((s2_y / n_y) + (s2_x / n_x), 2) /
        NULLIF(
          (POWER(s2_y / n_y, 2) / (n_y - 1)) + (POWER(s2_x / n_x, 2) / (n_x - 1)),
          0
        ),
        1.0
      ) AS df
    FROM test_params
  )
-- Step 7: Output final result table
SELECT
  fc.statistic,
  CASE
    WHEN fc.df IS NULL THEN NULL
    WHEN alternative = 'two.sided' THEN 2.0 * LEAST(t_cdf_approx(fc.statistic, fc.df), 1.0 - t_cdf_approx(fc.statistic, fc.df))
    WHEN alternative = 'greater' THEN 1.0 - t_cdf_approx(fc.statistic, fc.df)
    WHEN alternative = 'less' THEN t_cdf_approx(fc.statistic, fc.df)
    ELSE NULL
  END AS p_value,
  fc.df,
  fc.p_hat AS estimate,
  fc.n_y,
  fc.n_x,
  fc.mean_rank_y,
  fc.mean_rank_x,
  fc.s2_y AS variance_y,
  fc.s2_x AS variance_x,
  alternative AS alternative
FROM final_calc AS fc
);

-- =============================================================================
-- Kruskal-Wallis Test (k-Sample Rank Test)
-- =============================================================================
CREATE OR REPLACE FUNCTION kruskal_wallis_test(
  y_list DOUBLE[], 
  x_list VARCHAR[]
) AS TABLE
WITH
  -- Step 1: Unnest arrays
  input_data AS (
    SELECT
      UNNEST(y_list) as value,
      UNNEST(x_list) as group_label
  ),

  -- Step 2: Clean and validate data
  valid_data AS (
    SELECT
      value,
      trim(group_label) as group_label
    FROM input_data
    WHERE
      value IS NOT NULL
      AND group_label IS NOT NULL
  ),

  -- Step 3: Calculate ranks and tie correction terms
  ranked_data AS (
    SELECT
      group_label,
      -- Average rank = Rank + (Count-1)/2
      RANK() OVER (ORDER BY value) + (COUNT(*) OVER (PARTITION BY value) - 1) / 2.0 as rank,
      -- Tie correction term fragment = (t^2 - 1)
      POW(COUNT(*) OVER (PARTITION BY value), 2) - 1.0 as tie_term
    FROM valid_data
  ),

  -- Step 4: Aggregate by group
  group_stats AS (
    SELECT
      group_label,
      SUM(rank) as rank_sum,
      COUNT(*) as n_i
    FROM ranked_data
    GROUP BY group_label
  ),

  -- Step 5: Calculate overall statistics and tie correction constant C
  constants AS (
    SELECT
      SUM(n_i) as N,
      COUNT(*) as k,
      (SELECT SUM(tie_term) FROM ranked_data) as C
    FROM group_stats
  ),

  -- Step 6: Calculate H statistic (uncorrected)
  h_statistic_uncorrected AS (
    SELECT
      (12.0 / (c.N * (c.N + 1.0))) * SUM(pow(gs.rank_sum, 2) / gs.n_i) - 3.0 * (c.N + 1.0) AS H_unc
    FROM constants c, group_stats gs
    GROUP BY c.N
  ),

  -- Step 7: Apply tie correction
  final_results AS (
    SELECT
      c.N,
      c.k,
      1.0 - (c.C / (pow(c.N, 3) - c.N)) AS tie_correction,
      h.H_unc / (
        CASE
          WHEN (1.0 - (c.C / (pow(c.N, 3) - c.N))) > 1e-9 
          THEN (1.0 - (c.C / (pow(c.N, 3) - c.N)))
          ELSE 1e-9
        END
      ) AS H
    FROM constants c, h_statistic_uncorrected h
  )

-- Step 8: Output results
SELECT
  f.H AS statistic,
  f.k - 1 AS df,
  1.0 - chi2_cdf_approx(f.H, f.k - 1) AS p_value,
  f.k AS n_groups,
  f.N AS n_total,
  f.tie_correction AS tie_correction_factor,
  CASE
    WHEN (f.N - f.k) > 0 THEN
      greatest(0.0, (f.H - f.k + 1) / (f.N - f.k))
    ELSE NULL
  END AS effect_size_epsilon_squared
FROM final_results f
WHERE f.N >= 2 AND f.k >= 2;

-- =============================================================================
-- Chi-squared Test of Independence
-- =============================================================================
CREATE OR REPLACE FUNCTION chi2_test(y_list HUGEINT[], x_list VARCHAR[]) AS TABLE (
  WITH data AS (
    SELECT 
      UNNEST(y_list) as binary_val,
      UNNEST(x_list) as category
  ),
  group_counts AS (
    SELECT 
      category,
      SUM(binary_val) as obs_1,
      COUNT(*) - SUM(binary_val) as obs_0,
      COUNT(*) as n_i
    FROM data
    WHERE category IS NOT NULL AND binary_val IN (0, 1)
    GROUP BY category
  ),
  overall_stats AS (
    SELECT 
      SUM(obs_1) as total_1,
      SUM(obs_0) as total_0,
      SUM(n_i) as grand_total
    FROM group_counts
  ),
  stats AS (
    SELECT 
      obs_1,
      obs_0,
      n_i,
      n_i * total_1 * 1.0 / grand_total as exp_1,
      n_i * total_0 * 1.0 / grand_total as exp_0
    FROM group_counts
    CROSS JOIN overall_stats
  ),
  chi2_calc AS (
    SELECT 
      SUM(
        POW(obs_1 - exp_1, 2) / NULLIF(exp_1, 0) +
        POW(obs_0 - exp_0, 2) / NULLIF(exp_0, 0)
      ) as chi2_stat,
      COUNT(*) - 1 as df_val,
      SUM(n_i) as n_total,
      COUNT(*) as n_groups
    FROM stats
  )
  SELECT 
    chi2_stat as statistic,
    df_val::INTEGER as df,
    1.0 - chi2_cdf_approx(chi2_stat, df_val) as p_value,
    n_total,
    n_groups
  FROM chi2_calc
);

-- =============================================================================
-- Cochran-Armitage Trend Test
-- =============================================================================
CREATE OR REPLACE FUNCTION cochran_armitage_test(
  y_list HUGEINT[], 
  x_list VARCHAR[], 
  alternative VARCHAR,
  correction VARCHAR
) AS TABLE (
WITH
  -- Step 1: Unnest arrays
  unnested_data AS (
    SELECT
      UNNEST(y_list) AS binary_val,
      UNNEST(x_list) AS group_label
  ),

  -- Step 2: Assign ordinal scores (weights) to ordered categories
  weighted_data AS (
    SELECT
      binary_val,
      group_label,
      DENSE_RANK() OVER (ORDER BY group_label) - 1 AS w
    FROM unnested_data
    WHERE binary_val IS NOT NULL AND group_label IS NOT NULL
  ),

  -- Step 3: Calculate global statistics (no intermediate GROUP BY)
  global_stats AS (
    SELECT
      COUNT(*) AS N,
      SUM(binary_val)::DOUBLE AS R,
      MAX(w) + 1 AS k, 
      SUM(w * binary_val) AS sum_score_r,
      SUM(w) AS sum_score_n,
      SUM(w * w) AS sum_score2_n
    FROM weighted_data
  ),

  -- Step 4: Calculate test statistic components (numerator and variance)
  base_calc AS (
    SELECT
      *,
      (sum_score_r - (R * sum_score_n / N)) AS numerator,
      (N * sum_score2_n - (sum_score_n * sum_score_n)) AS core_term,
      CASE 
        WHEN N > 1 THEN (R * (N - R) / (N * N)) * ((N * sum_score2_n - (sum_score_n * sum_score_n))::DOUBLE / (N - 1))
        ELSE NULL 
      END AS variance
    FROM global_stats
  ),

  -- Step 5: Apply correction and calculate standard error
  corrected_calc AS (
    SELECT
      *,
      CASE WHEN variance > 0 THEN sqrt(variance) ELSE NULL END AS se,
      CASE
        WHEN correction = 'yates' AND alternative = 'two.sided' THEN sign(numerator) * greatest(0.0, abs(numerator) - 0.5)
        WHEN correction = 'yates' AND alternative = 'greater' AND numerator > 0 THEN numerator - 0.5
        WHEN correction = 'yates' AND alternative = 'less' AND numerator < 0 THEN numerator + 0.5
        ELSE numerator
      END AS numerator_corrected,
      (R > 0 AND R < N AND core_term > 0 AND k >= 2 AND variance > 0) AS is_valid
    FROM base_calc
  )

  -- Step 6: Output final results
  SELECT 
    CASE WHEN is_valid THEN numerator_corrected / se ELSE NULL END AS statistic,
    CASE WHEN is_valid THEN numerator / se ELSE NULL END AS statistic_uncorrected,
    CASE
      WHEN alternative = 'greater' THEN 1.0 - standard_normal_cdf_approx(numerator_corrected / se)
      WHEN alternative = 'less' THEN standard_normal_cdf_approx(numerator_corrected / se)
      WHEN alternative = 'two.sided' THEN 2.0 * (1.0 - standard_normal_cdf_approx(abs(numerator_corrected / se)))
      ELSE NULL
    END AS p_value,
    N AS n_total,
    R AS n_success,
    k AS n_groups,
    numerator AS numerator_raw,
    variance AS variance_raw
  FROM corrected_calc
  WHERE is_valid = TRUE
);

-- =============================================================================
-- Jonckheere-Terpstra Trend Test
-- =============================================================================
CREATE OR REPLACE FUNCTION jonckheere_terpstra_test(
  y_list DOUBLE[], 
  x_list VARCHAR[], 
  alternative VARCHAR
) AS TABLE (
  WITH unnested_data AS (
    SELECT 
      UNNEST(y_list) as value,
      UNNEST(x_list) as group_label
  ),
  data_with_id AS (
    SELECT
      value,
      group_label,
      DENSE_RANK() OVER (ORDER BY group_label) as group_id
    FROM unnested_data
    WHERE value IS NOT NULL AND group_label IS NOT NULL
  ),
  -- Step 3: Calculate U statistic
  U_stat AS (
    SELECT SUM(
      CASE 
        WHEN t1.value < t2.value THEN 1.0
        WHEN t1.value = t2.value THEN 0.5
        ELSE 0.0
      END
    ) as U
    FROM data_with_id t1
    JOIN data_with_id t2 ON t1.group_id < t2.group_id
  ),
  -- Step 4: Calculate group counts
  group_stats AS (
    SELECT
      group_id,
      COUNT(*) AS n
    FROM data_with_id
    GROUP BY group_id
  ),
  -- Step 5: Pre-calculate sums for algebraic variance formula
  group_agg_stats AS (
    SELECT
      SUM(n) AS sum_n,
      SUM(n * n) AS sum_n_sq,
      SUM(n * (n - 1)) AS sum_m,
      SUM(n * (n - 1) * (n * (n - 1))) AS sum_m_sq,
      SUM(n * (n - 1) * (2 * n + 5)) AS S1
    FROM group_stats
  ),
  -- Step 6: Calculate variance components S2, S3 using algebraic identities
  variance_components AS (
    SELECT
      sum_n AS N,
      S1,
      (sum_n * sum_n - sum_n_sq) / 2.0 AS S2,
      (sum_m * sum_m - sum_m_sq) / 2.0 AS S3
    FROM group_agg_stats
  ),
  -- Step 7: Identify tie blocks
  tie_blocks AS (
      SELECT value, COUNT(*) as t FROM data_with_id GROUP BY value HAVING t > 1
  ),
  tie_group_counts AS (
      SELECT value, group_id, COUNT(*) as t_rk
      FROM data_with_id
      WHERE value IN (SELECT value FROM tie_blocks)
      GROUP BY value, group_id
  ),
  -- Step 8: Calculate tie contribution for S2
  tie_s2_contribution AS (
      SELECT 
        tb.t, 
        SUM(tgc.t_rk * (tgc.t_rk - 1)) as s2_per_block
      FROM tie_group_counts tgc 
      JOIN tie_blocks tb ON tgc.value = tb.value
      GROUP BY tb.t, tgc.value
  ),
  T_stat AS (
    SELECT
      (SELECT COALESCE(SUM(t * (t - 1) * (t - 2)) / 72.0, 0) FROM tie_blocks) +
      (SELECT CASE WHEN ANY_VALUE(N) > 1 THEN COALESCE((ANY_VALUE(N) * SUM(t * (t-1)) - SUM(t * (t-1) * t)) / (36.0 * ANY_VALUE(N) * (ANY_VALUE(N) - 1)), 0) ELSE 0 END FROM tie_blocks, (SELECT N FROM variance_components)) -
      (SELECT COALESCE(SUM(t_rk * (t_rk - 1) * (t_rk - 2)) / 12.0, 0) FROM tie_group_counts) -
      (SELECT CASE WHEN ANY_VALUE(N) > 1 THEN COALESCE((ANY_VALUE(N) * SUM(t_rk * (t_rk-1)) - SUM(t_rk * (t_rk-1) * t_rk)) / (6.0 * ANY_VALUE(N) * (ANY_VALUE(N) - 1)), 0) ELSE 0 END FROM tie_group_counts, (SELECT N FROM variance_components)) -
      (SELECT CASE WHEN ANY_VALUE(N) >= 3 THEN COALESCE((ANY_VALUE(N) * SUM(s2_per_block) - SUM(s2_per_block * t)) / (4.0 * ANY_VALUE(N) * (ANY_VALUE(N) - 1) * (ANY_VALUE(N) - 2)), 0) ELSE 0 END 
       FROM tie_s2_contribution, (SELECT N FROM variance_components))
    as T
  ),
  results AS (
    SELECT
      (SELECT U FROM U_stat) AS U,
      vc.N,
      0.5 * vc.S2 AS E,
      (
        ( (vc.N * (vc.N - 1) * (2 * vc.N + 5) - vc.S1) / 72.0 ) +
        ( vc.S2 / 36.0 ) +
        ( CASE WHEN vc.N > 1 THEN COALESCE(vc.S3, 0) / (12.0 * vc.N * (vc.N - 1)) ELSE 0.0 END )
      ) AS Var0,
      COALESCE((SELECT T FROM T_stat), 0) AS T,
      (SELECT COUNT(*) FROM group_stats) AS n_groups
    FROM variance_components AS vc
  ),
  results_with_stats AS (
    SELECT
      res.U,
      res.N,
      res.E,
      res.n_groups,
      res.T,
      alternative,
      GREATEST(res.Var0 - res.T, (res.Var0 * 1e-12) + 1e-12) AS variance,
      CASE
        WHEN res.N < 2 OR (res.Var0 - res.T) <= 0 THEN NULL
        ELSE (res.U - res.E) / SQRT(GREATEST(res.Var0 - res.T, (res.Var0 * 1e-12) + 1e-12))
      END AS statistic
    FROM results AS res
  )
  SELECT
    rws.U AS u_statistic,
    rws.variance AS variance,
    rws.statistic AS statistic,
    CASE
      WHEN rws.statistic IS NULL THEN NULL
      WHEN alternative = 'greater' THEN 1.0 - standard_normal_cdf_approx(rws.statistic)
      WHEN alternative = 'less' THEN standard_normal_cdf_approx(rws.statistic)
      WHEN alternative = 'two.sided' THEN 2.0 * LEAST(
          standard_normal_cdf_approx(rws.statistic),
          1.0 - standard_normal_cdf_approx(rws.statistic)
      )
      ELSE NULL
    END AS p_value,
    rws.N AS n_total,
    rws.E AS expected_u,
    alternative AS alternative,
    rws.n_groups AS n_groups,
    rws.T AS tie_correction_term
  FROM results_with_stats AS rws
);

-- =============================================================================
-- Generalized Cochran-Mantel-Haenszel Test (Ordinal Correlation)
-- =============================================================================
CREATE OR REPLACE FUNCTION generalized_cochran_mantel_haenszel_ordinal_test(y_score_list DOUBLE[], x_list VARCHAR[], z_list VARCHAR[])
AS TABLE
WITH
  -- Step 1: unnest arrays and drop NULL rows
  unpacked_data AS (
    SELECT
      UNNEST(y_score_list) as target,
      UNNEST(x_list) as cause,
      UNNEST(z_list) as confounder
  ),

  -- Step 2: assign ordinal scores to the exposure variable
  scored_data AS (
    SELECT
      target,
      cause,
      confounder,
      DENSE_RANK() OVER (ORDER BY cause)::DOUBLE AS cause_score
    FROM unpacked_data
    WHERE target IS NOT NULL AND cause IS NOT NULL AND confounder IS NOT NULL
  ),

  -- Step 3: capture level counts for reporting
  level_counts AS (
    SELECT
      COUNT(*) AS n_total,
      COUNT(DISTINCT target) AS y_levels,
      COUNT(DISTINCT cause) AS x_levels,
      COUNT(DISTINCT confounder) AS z_levels
    FROM scored_data
  ),

  -- Step 4: Calculate per-stratum raw sums for CMH statistics
  stratum_raw_sums AS (
    SELECT
      confounder,
      COUNT(*)::DOUBLE AS n_k,
      SUM(target) AS sum_y,
      SUM(cause_score) AS sum_x,
      SUM(target * cause_score) AS sum_xy,
      SUM(POWER(target, 2)) AS sum_y2,
      SUM(POWER(cause_score, 2)) AS sum_x2
    FROM scored_data
    GROUP BY confounder
      HAVING COUNT(*) > 1
  ),

  -- Step 5: Calculate per-stratum correlation contrasts and variances
  stratum_calculations AS (
    SELECT
      sum_xy - sum_y * sum_x / n_k AS C_k,
      (POWER(n_k, 2) / (n_k - 1.0))
      * ((sum_y2 - POWER(sum_y, 2) / n_k) / n_k)
      * ((sum_x2 - POWER(sum_x, 2) / n_k) / n_k)
      AS Var_C_k
    FROM stratum_raw_sums
  ),

  -- Step 6: Accumulate strata-level statistics
  total_stats AS (
    SELECT
      SUM(C_k) AS correlation_sum,
      SUM(Var_C_k) AS variance_sum,
      COUNT(*) FILTER (WHERE Var_C_k > 0) AS strata_used
    FROM stratum_calculations
    WHERE Var_C_k > 0
  )

-- Step 7: Assemble test statistics and reporting fields
SELECT
  CASE
    WHEN ts.variance_sum > 0 THEN POWER(ts.correlation_sum, 2) / ts.variance_sum
    ELSE NULL
  END AS statistic,
  CASE
    WHEN ts.variance_sum > 0 THEN 1.0 - chi2_cdf_approx(POWER(ts.correlation_sum, 2) / ts.variance_sum, 1)
    ELSE NULL
  END AS p_value,
  1 AS df,
  ts.correlation_sum AS correlation_sum,
  ts.variance_sum AS variance_sum,
  ts.strata_used AS n_strata,
  lc.y_levels AS n_y_levels,
  lc.x_levels AS n_x_levels,
  lc.z_levels AS n_z_levels,
  lc.n_total AS n_total
FROM total_stats AS ts, level_counts AS lc;

-- =============================================================================
-- Normalized Entropy (Continuous Variable)
-- =============================================================================
CREATE OR REPLACE FUNCTION normalized_entropy_continuous(input_array) AS (
    WITH 
    params AS (
        SELECT list_filter(input_array, x -> x IS NOT NULL) AS arr
    ),
    stats AS (
        SELECT 
            arr,
            len(arr) AS n,
            list_min(arr) AS min_v,
            list_max(arr) AS max_v,
            list_sort(arr) AS sorted_arr,
            (len(arr) - 1) * 0.25 AS q1_pos,
            (len(arr) - 1) * 0.75 AS q3_pos
        FROM params
    ),
    quartiles AS (
        SELECT
            arr, n, min_v, max_v,
            sorted_arr[floor(q1_pos)::INT + 1] * (1 - (q1_pos - floor(q1_pos))) +
            sorted_arr[least(n, floor(q1_pos)::INT + 2)] * (q1_pos - floor(q1_pos)) AS q1,
            sorted_arr[floor(q3_pos)::INT + 1] * (1 - (q3_pos - floor(q3_pos))) +
            sorted_arr[least(n, floor(q3_pos)::INT + 2)] * (q3_pos - floor(q3_pos)) AS q3
        FROM stats
    ),
    fd_params AS (
        SELECT
            arr, n, min_v, max_v,
            CASE 
                WHEN n > 0 THEN 2 * (q3 - q1) * power(n, -1.0/3.0)
                ELSE 0 
            END AS h
        FROM quartiles
    ),
    bin_config AS (
        SELECT
            arr, n, min_v, max_v,
            CASE 
                WHEN h <= 0 OR min_v = max_v THEN 1
                ELSE greatest(1, ceil((max_v - min_v) / h)::INT)
            END AS num_bins
        FROM fd_params
    ),
    binned AS (
        SELECT
            n, num_bins,
            map_values(list_histogram(
                list_transform(arr, val -> 
                    CASE
                        WHEN num_bins = 1 THEN 0
                        WHEN val = max_v THEN num_bins - 1
                        ELSE least(num_bins - 1, floor((val - min_v) / (max_v - min_v) * num_bins)::INT)
                    END
                )
            )) AS counts
        FROM bin_config
    )
    SELECT
        CASE 
            WHEN num_bins <= 1 THEN 0.0
            ELSE list_sum(
                list_transform(counts, c -> -1.0 * (c::DOUBLE / n) * log2(c::DOUBLE / n))
            ) / log2(num_bins)
        END
    FROM binned
);
CREATE OR REPLACE FUNCTION normalized_entropy_continuous_tbl(input_array) AS TABLE
WITH 
-- Step 1: Unnest and clean data
data_source AS (
    SELECT unnest(input_array) AS val
),
clean_data AS (
    SELECT val FROM data_source WHERE val IS NOT NULL
),
-- Step 2: Calculate basic statistics
stats AS (
    SELECT
        count(*) AS n,
        min(val) AS min_v,
        max(val) AS max_v,
        quantile_cont(val, 0.25) AS q1,
        quantile_cont(val, 0.75) AS q3
    FROM clean_data
),
-- Step 3: Calculate Freedman-Diaconis parameters
fd_params AS (
    SELECT
        n, min_v, max_v,
        (q3 - q1) AS iqr,
        CASE 
            WHEN n > 0 THEN 2 * (q3 - q1) * power(n, -1.0/3.0)
            ELSE 0 
        END AS h
    FROM stats
),
bin_config AS (
    SELECT
        n, min_v, max_v,
        CASE 
            WHEN h <= 0 OR min_v = max_v THEN 1
            ELSE ceil((max_v - min_v) / h)::INT 
        END AS num_bins
    FROM fd_params
),
-- Step 4: Manual binning
bin_counts AS (
    SELECT
        CASE
            WHEN b.num_bins = 1 THEN 0
            WHEN d.val = b.max_v THEN b.num_bins - 1
            ELSE floor((d.val - b.min_v) / (b.max_v - b.min_v) * b.num_bins)::INT
        END AS bucket_id,
        count(*) AS count_in_bin
    FROM clean_data d, bin_config b
    GROUP BY bucket_id
),
-- Step 5: Calculate entropy
entropy_calc AS (
    SELECT
        sum(
            -1 * (c.count_in_bin::DOUBLE / b.n) * log2(c.count_in_bin::DOUBLE / b.n)
        ) AS raw_entropy
    FROM bin_counts c, bin_config b
)
-- Step 6: Normalize and output
SELECT
    COALESCE(e.raw_entropy, 0) AS raw_entropy,
    b.num_bins,
    CASE 
        WHEN b.num_bins <= 1 THEN 0.0
        ELSE COALESCE(e.raw_entropy, 0) / log2(b.num_bins)
    END AS normalized_entropy
FROM bin_config b
LEFT JOIN entropy_calc e ON true;


-- =============================================================================
-- Normalized Entropy (Categorical Variable)
-- =============================================================================
CREATE OR REPLACE FUNCTION normalized_entropy_category(input_array) AS (
    WITH 
    params AS (
        SELECT 
            list_filter(input_array, x -> x IS NOT NULL) AS arr
    ),
    hist AS (
        SELECT 
            map_values(list_histogram(arr)) AS counts,
            len(arr) AS total_n,
            len(list_distinct(arr)) AS num_unique
        FROM params
    )
    SELECT
        CASE 
            WHEN num_unique <= 1 THEN 0.0
            ELSE list_sum(
                list_transform(counts, c -> -1.0 * (c::DOUBLE / total_n) * log2(c::DOUBLE / total_n))
            ) / log2(num_unique)
        END
    FROM hist
);

CREATE OR REPLACE FUNCTION normalized_entropy_category_tbl(input_array) AS TABLE
WITH 
-- Step 1: Unnest and clean data
data_source AS (
    SELECT unnest(input_array) AS val
),
clean_data AS (
    SELECT val FROM data_source WHERE val IS NOT NULL
),
-- Step 2: Count by category
counts AS (
    SELECT 
        val,
        count(*) AS cnt
    FROM clean_data
    GROUP BY val
),
-- Step 3: Calculate total and unique counts
stats AS (
    SELECT 
        sum(cnt) AS total_n,
        count(*) AS num_unique
    FROM counts
),
-- Step 4: Calculate entropy
entropy_calc AS (
    SELECT
        sum(
            -1 * (c.cnt::DOUBLE / s.total_n) * log2(c.cnt::DOUBLE / s.total_n)
        ) AS raw_entropy
    FROM counts c, stats s
)
-- Step 5: Normalize and output
SELECT
    COALESCE(e.raw_entropy, 0) AS raw_entropy,
    s.num_unique AS num_bins,
    CASE 
        WHEN s.num_unique <= 1 THEN 0.0
        ELSE COALESCE(e.raw_entropy, 0) / log2(s.num_unique)
    END AS normalized_entropy
FROM stats s
LEFT JOIN entropy_calc e ON true;
