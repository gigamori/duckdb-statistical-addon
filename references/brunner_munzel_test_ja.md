# brunner_munzel_test

## 目的

2つの独立標本に対するBrunner–Munzel検定

## 入力

- y_list: DOUBLE[]（標本1の値）
- x_list: DOUBLE[]（標本2の値）
- alternative: 'two.sided' | 'greater' | 'less'

## 出力列

- statistic: DOUBLE（t統計量）
- p_value: DOUBLE（tまたは正規分布CDFに基づくp値）
- df: DOUBLE（Welch–Satterthwaiteの自由度）
- estimate: DOUBLE（p_hat、yのxに対する確率的優越性）
- n_y: BIGINT（yの標本サイズ）
- n_x: BIGINT（xの標本サイズ）
- mean_rank_y: DOUBLE
- mean_rank_x: DOUBLE
- variance_y: DOUBLE
- variance_x: DOUBLE
- alternative: VARCHAR（入力値のエコー）

## 注意事項

- 分散が異なる場合、Mann–Whitney U検定より検出力が高い
- NULLは対ごとに除外される

## 使用例

```sql
SELECT *
FROM brunner_munzel_test(
  (SELECT LIST(value) FROM group_a),
  (SELECT LIST(value) FROM group_b),
  'two.sided'
);
```
