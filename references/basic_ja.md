# 基本関数（CDF近似）

## standard_normal_cdf_approx(z)

目的: 標準正規分布のCDF近似

入力:
- z: DOUBLE（z値）

出力: DOUBLE（近似Φ(z)）

注意事項:
- zがNULLの場合、NULLを返す
- Abramowitz–Stegun式の有理近似を使用

使用例:

```sql
SELECT standard_normal_cdf_approx(1.96);
```

## chi2_cdf_approx(chi2, df)

目的: カイ二乗分布のCDF近似

入力:
- chi2: DOUBLE（χ²統計量）
- df: DOUBLE/INTEGER（自由度 > 0）

出力: DOUBLE（近似CDF P[X ≤ chi2] for χ²_df）

注意事項:
- 入力がNULLまたはdf ≤ 0の場合、NULLを返す
- Wilson–Hilferty変換と正規分布CDF近似を使用

使用例:

```sql
SELECT 1.0 - chi2_cdf_approx(10.5, 4) AS p_right_tail;
```

## t_cdf_approx(t, df)

目的: t分布のCDF近似

入力:
- t_val: DOUBLE（t統計量）
- df: DOUBLE/INTEGER（自由度 > 0）

出力: DOUBLE（近似CDF P[T ≤ t] for t_df）

注意事項:
- 入力がNULLまたはdf ≤ 0の場合、NULLを返す
- Abramowitz and Stegun式26.7.7を使用してtをzに変換

使用例:

```sql
SELECT t_cdf_approx(2.5, 10);
```
