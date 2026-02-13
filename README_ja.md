# DuckDB 統計関数ライブラリ

DuckDB の純粋 SQL だけで実装された統計的仮説検定関数コレクション。拡張機能や外部ライブラリは不要 — DuckDB の SQL エンジン上ですべて動作する。

## 背景

DuckDB には豊富な集約関数やウィンドウ関数が備わっているが、Brunner-Munzel 検定や Kruskal-Wallis 検定、Cochran-Armitage トレンド検定といった統計的仮説検定の組み込みサポートはない。このライブラリは、単一の `CREATE FUNCTION` スクリプトで読み込める純粋 SQL マクロ（スカラ関数・テーブル値関数）でそのギャップを埋める。

## 特徴

- 純粋 SQL — C/C++ 拡張も Python UDF も不要
- あらゆる DuckDB クライアントで動作（CLI, Python, R, Node.js, WASM, …）
- タイ（同順位）の処理と適切な補正を実装
- 内部に CDF 近似（正規分布, カイ二乗分布, t 分布）を含むため自己完結

## 提供する関数

### 仮説検定

| 関数 | 説明 |
|------|------|
| `brunner_munzel_test(y, x, alternative)` | 分散の不等性にロバストな2標本順位検定 |
| `kruskal_wallis_test(y, x)` | タイ補正・ε²効果量付きの k 標本順位検定 |
| `chi2_test(y, x)` | 2値アウトカム × k カテゴリの Pearson カイ二乗独立性検定 |
| `cochran_armitage_test(y, x, alternative, correction)` | 順序カテゴリにおける2値アウトカムの線形トレンド検定（Yates 補正対応） |
| `jonckheere_terpstra_test(y, x, alternative)` | 順序カテゴリにおける連続値の単調トレンド検定 |
| `generalized_cochran_mantel_haenszel_ordinal_test(y, x, z)` | 交絡因子を調整した層別順序相関検定 |

### 情報理論的指標

| 関数 | 説明 |
|------|------|
| `normalized_entropy_continuous(arr)` | 連続変数の正規化 Shannon エントロピー（スカラ, 0–1） |
| `normalized_entropy_continuous_tbl(arr)` | 同上。生エントロピー・ビン数・正規化エントロピーをテーブルで返す |
| `normalized_entropy_category(arr)` | カテゴリ変数の正規化 Shannon エントロピー（スカラ, 0–1） |
| `normalized_entropy_category_tbl(arr)` | 同上。生エントロピー・ユニーク数・正規化エントロピーをテーブルで返す |

### 内部ヘルパー

以下の関数は上記の検定が内部的に使用するもので、通常は直接呼び出す必要はない。

| 関数 | 説明 |
|------|------|
| `standard_normal_cdf_approx(z)` | 標準正規分布 CDF（Abramowitz & Stegun 近似） |
| `chi2_cdf_approx(chi2, df)` | カイ二乗分布 CDF（Wilson-Hilferty 変換） |
| `t_cdf_approx(t_val, df)` | t 分布 CDF（Abramowitz & Stegun 公式 26.7.7） |

## ドキュメント

各関数の詳細なリファレンスマニュアル（使い方・パラメータ・戻り値・実行例）が `references/` ディレクトリにある。

| 関数 | リファレンス |
|------|-------------|
| 内部 CDF ヘルパー | [basic_ja.md](references/basic_ja.md) |
| `brunner_munzel_test` | [brunner_munzel_test_ja.md](references/brunner_munzel_test_ja.md) |
| `kruskal_wallis_test` | [kruskal_wallis_test_ja.md](references/kruskal_wallis_test_ja.md) |
| `chi2_test` | [chi2_test_ja.md](references/chi2_test_ja.md) |
| `cochran_armitage_test` | [cochran_armitage_test_ja.md](references/cochran_armitage_test_ja.md) |
| `jonckheere_terpstra_test` | [jonckheere_terpstra_test_ja.md](references/jonckheere_terpstra_test_ja.md) |
| `generalized_cochran_mantel_haenszel_ordinal_test` | [generalized_cochran_mantel_haenszel_ordinal_test_ja.md](references/generalized_cochran_mantel_haenszel_ordinal_test_ja.md) |
| `normalized_entropy_*` | [normalized_entropy_ja.md](references/normalized_entropy_ja.md) |

英語版（`*_ja` なし）も同ディレクトリにある。

## クイックスタート

```sql
-- 1. 全関数を読み込み
.read statistical_processing.sql

-- 2. Brunner-Munzel 検定を実行
SELECT * FROM brunner_munzel_test(
  [5.0, 7.0, 3.0, 8.0, 6.0],
  [2.0, 4.0, 1.0, 3.0, 5.0],
  'two.sided'
);

-- 3. Kruskal-Wallis 検定を実行
SELECT * FROM kruskal_wallis_test(
  [10.0, 12.0, 14.0, 8.0, 9.0, 15.0],
  ['A', 'A', 'B', 'B', 'C', 'C']
);

-- 4. 連続変数の正規化エントロピーを計算
SELECT normalized_entropy_continuous([1.0, 2.0, 3.0, 4.0, 5.0, 5.0, 6.0, 7.0]);
```

## 関数シグネチャ

### `brunner_munzel_test(y_list DOUBLE[], x_list DOUBLE[], alternative VARCHAR)`

戻り値: `statistic`, `p_value`, `df`, `estimate`（P(Y > X)）, `n_y`, `n_x`, `mean_rank_y`, `mean_rank_x`, `variance_y`, `variance_x`, `alternative`

`alternative`: `'two.sided'` | `'greater'` | `'less'`

### `kruskal_wallis_test(y_list DOUBLE[], x_list VARCHAR[])`

戻り値: `statistic`（H 統計量）, `df`, `p_value`, `n_groups`, `n_total`, `tie_correction_factor`, `effect_size_epsilon_squared`

### `chi2_test(y_list HUGEINT[], x_list VARCHAR[])`

戻り値: `statistic`, `df`, `p_value`, `n_total`, `n_groups`

`y_list` は2値（0 または 1）であること。

### `cochran_armitage_test(y_list HUGEINT[], x_list VARCHAR[], alternative VARCHAR, correction VARCHAR)`

戻り値: `statistic`, `statistic_uncorrected`, `p_value`, `n_total`, `n_success`, `n_groups`, `numerator_raw`, `variance_raw`

`correction`: `'yates'` | `'none'`

### `jonckheere_terpstra_test(y_list DOUBLE[], x_list VARCHAR[], alternative VARCHAR)`

戻り値: `u_statistic`, `variance`, `statistic`（z 値）, `p_value`, `n_total`, `expected_u`, `alternative`, `n_groups`, `tie_correction_term`

### `generalized_cochran_mantel_haenszel_ordinal_test(y_score_list DOUBLE[], x_list VARCHAR[], z_list VARCHAR[])`

戻り値: `statistic`, `p_value`, `df`, `correlation_sum`, `variance_sum`, `n_strata`, `n_y_levels`, `n_x_levels`, `n_z_levels`, `n_total`

### `normalized_entropy_continuous(input_array DOUBLE[])` → `DOUBLE`

0.0（変動なし）から 1.0（最大エントロピー）のスカラを返す。ビン幅は Freedman-Diaconis ルールで決定。

### `normalized_entropy_category(input_array ANY[])` → `DOUBLE`

0.0 から 1.0 のスカラを返す。

## 動作要件

- DuckDB ≥ 1.4.2

## 数値計算手法

CDF 近似には以下の数値計算手法を使用している:

- 標準正規分布 CDF: Abramowitz & Stegun の多項式近似（誤差 < 7.5 × 10⁻⁸）
- カイ二乗分布 CDF: Wilson-Hilferty の立方根変換による正規近似
- t 分布 CDF: Abramowitz & Stegun 公式 26.7.7

これらは一般的な仮説検定の用途には十分な精度を持つ。極端な裾確率や非常に小さい自由度が必要な場合は、専用の統計ライブラリを持つ言語の利用を検討すること。

## ライセンス

MIT License — 全文は [LICENSE](LICENSE) を参照。
