# generalized_cochran_mantel_haenszel_ordinal_test

## 目的

層別化を伴う一般化Cochran–Mantel–Haenszel相関検定

## 入力

- y_score_list: DOUBLE[]（順序アウトカムスコア）
- x_list: VARCHAR[]（曝露ラベル）、y_score_listと同じ長さ
- z_list: VARCHAR[]（層識別子）、y_score_listと同じ長さ

## 出力列

- statistic: DOUBLE（相関のχ²統計量）
- p_value: DOUBLE（`chi2_cdf_approx`による右側確率）
- df: INTEGER（自由度、常に1）
- correlation_sum: DOUBLE（層全体でのΣ C_k）
- variance_sum: DOUBLE（層全体でのΣ Var[C_k]）
- n_strata: BIGINT（検定に寄与する層の数）
- n_y_levels: BIGINT（異なるアウトカムレベル数）
- n_x_levels: BIGINT（異なる曝露レベル数）
- n_z_levels: BIGINT（異なる層レベル数）
- n_total: BIGINT（有効なペア観測数）

## 注意事項

- 観測数が2未満の層は無視される
- 曝露ラベルは昇順でランク付けされスコア化される
- 順序スコアは0/1アウトカムを超えた拡張を可能にする。連続値をビン化（例：ビンごとの中央値）してから`y_score_list`に渡すこと
- ビン化と層を適度にバランスさせ、CMH分散推定が安定するようにすること

## 使用例

```sql
SELECT *
FROM generalized_cochran_mantel_haenszel_ordinal_test(
  (SELECT LIST(score) FROM survey_responses),
  (SELECT LIST(treatment_group) FROM survey_responses),
  (SELECT LIST(store_id) FROM survey_responses)
);
```
