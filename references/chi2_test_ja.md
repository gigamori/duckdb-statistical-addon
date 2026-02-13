# chi2_test

## 目的

2値アウトカムに対するPearsonのχ²独立性検定

## 入力

- y_list: HUGEINT[]（0/1の応答）
- x_list: VARCHAR[]（カテゴリ）、y_listと同じ長さ

## 出力列

- statistic: DOUBLE（Pearsonのχ²統計量）
- df: INTEGER（カテゴリ数 - 1）
- p_value: DOUBLE（`chi2_cdf_approx`による右側確率）
- n_total: BIGINT（有効な観測数）
- n_groups: BIGINT（異なるカテゴリ数）

## 注意事項

- 0/1以外の値は集計時に削除される
- 期待度数はプールされた成功率を使用

## 使用例

```sql
SELECT *
FROM chi2_test(
  (SELECT LIST(subscribed) FROM customer),
  (SELECT LIST(first_landing_page) FROM customer)
);
```
