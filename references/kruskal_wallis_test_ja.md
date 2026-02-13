# kruskal_wallis_test

## 目的

Kruskal–Wallis k標本順位検定

## 入力

- y_list: DOUBLE[]
- x_list: VARCHAR[]（グループラベル）、y_listと同じ長さ

## 出力列

- statistic: DOUBLE（タイ補正を含むH統計量）
- df: INTEGER（k - 1）
- p_value: DOUBLE（`chi2_cdf_approx`による右側確率）
- n_groups: BIGINT（異なるグループ数）
- n_total: BIGINT（有効な観測数）
- tie_correction_factor: DOUBLE
- effect_size_epsilon_squared: DOUBLE
- excluded_records: BIGINT（検証中に除外されたレコード数）
- group_sizes: MAP(VARCHAR, BIGINT)
- rank_sums: MAP(VARCHAR, DOUBLE)

## 注意事項

- 無効または空白のラベルと非有限値は除外される
- タイ補正はゼロ除算を防ぐ

## 使用例

```sql
SELECT *
FROM kruskal_wallis_test(
  (SELECT LIST(revenue) FROM customer),
  (SELECT LIST(first_landing_page) FROM customer)
);
```
