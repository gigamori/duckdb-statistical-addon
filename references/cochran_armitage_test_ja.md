# cochran_armitage_test

## 目的

Cochran–Armitageトレンド検定

## 入力

- y_list: HUGEINT[]（0/1の応答）
- x_list: VARCHAR[]（順序付きラベル）、y_listと同じ長さ
- alternative: 'two.sided' | 'greater' | 'less'
- correction: 'none' | 'yates'

## 出力列

- statistic: DOUBLE（補正済みz統計量）
- statistic_uncorrected: DOUBLE（未補正z統計量）
- p_value: DOUBLE（`alternative`で選択された側の確率）
- n_total: BIGINT（有効な観測数）
- n_success: DOUBLE（成功の総数）
- n_groups: BIGINT（異なる順序付きラベル数）
- numerator_raw: DOUBLE（補正前のスコア分子）
- variance_raw: DOUBLE（スコア検定の分散）

## 注意事項

- カテゴリは自動的に0, 1, 2, ...とスコア付けされる
- 検定の要件を満たさない場合、行は返されない

## 使用例

```sql
SELECT *
FROM cochran_armitage_test(
  (SELECT LIST(subscribed) FROM customer),
  (SELECT LIST(customer_stage) FROM customer),
  'two.sided',
  'none'
);
```
