# jonckheere_terpstra_test

## 目的

Jonckheere–Terpstra順序対立仮説検定

## 入力

- y_list: DOUBLE[]
- x_list: VARCHAR[]（順序付きラベル）、y_listと同じ長さ
- alternative: 'two.sided' | 'greater' | 'less'

## 出力列

- u_statistic: DOUBLE（U統計量）
- variance: DOUBLE（タイ調整後の分散）
- statistic: DOUBLE（z統計量）
- p_value: DOUBLE（`alternative`で選択された側の確率）
- n_total: BIGINT（有効な観測数）
- expected_u: DOUBLE（H0下での期待U）
- alternative: VARCHAR（入力値のエコー）
- n_groups: BIGINT（異なる順序付きラベル数）
- tie_correction_term: DOUBLE（タイ調整項T）

## 注意事項

- 少なくとも2つのグループ、N ≥ 2、正の分散が必要
- NULLは対ごとに除外される
- 同順位調整後の分散を使用

## 使用例

```sql
SELECT *
FROM jonckheere_terpstra_test(
  (SELECT LIST(revenue) FROM customer),
  (SELECT LIST(LPAD(pageviews_detail::varchar, 3, '0')) FROM customer),
  'greater'
);
```
