# 📚 DuckDB 正規化エントロピー計算マクロ

## 概要
データの「乱雑さ」や「ばらつき」を **0.0 から 1.0 の範囲** で定量化するDuckDB用マクロです。
エントロピーをビンの数（またはカテゴリ数）で正規化することで、**連続変数**（価格、年齢など）と**カテゴリ変数**（性別、地域など）のばらつきを、同じ尺度で比較・評価することができます。

## 1. `normalized_entropy_continuous(input_array)` / `normalized_entropy_continuous_tbl(input_array)`
**連続変数（数値）** 用の関数です。
**Freedman-Diaconisの法則** を用いて最適なビンの幅と数を自動計算し、ヒストグラムを作成してからエントロピーを算出します。

*   **入力:** `input_array` (数値の配列/リスト。例: `[10, 20, 15]`)
*   **ロジック:**
    1.  四分位範囲 (IQR) を計算。
    2.  ビン幅 $h = 2 \times IQR \times n^{-1/3}$ を決定。
    3.  ヒストグラムを作成。
    4.  エントロピー $H$ を計算。
    5.  正規化: $H / \log_2(\text{ビン数})$。

## 2. `normalized_entropy_category(input_array)` / `normalized_entropy_category_tbl(input_array)`
**カテゴリ変数・2値変数** 用の関数です。
ユニークな値（カーディナリティ）をビンの数とみなして計算します。

*   **入力:** `input_array` (文字列やBOOLの配列/リスト。例: `['Tokyo', 'Osaka', 'Tokyo']`)
*   **ロジック:**
    1.  各値の出現回数をカウント。
    2.  エントロピー $H$ を計算。
    3.  正規化: $H / \log_2(\text{ユニーク数})$。

## 出力値（スキーマ）
- スカラー関数（`normalized_entropy_continuous`, `normalized_entropy_category`）は単一のDOUBLE値を返します。
- テーブル関数（`normalized_entropy_continuous_tbl`, `normalized_entropy_category_tbl`）は以下のカラムを持つテーブルを返します。

| カラム名 | 型 | 説明 |
| :--- | :--- | :--- |
| **`raw_entropy`** | `DOUBLE` | シャノンエントロピー（ビット単位の情報量）。 |
| **`num_bins`** | `BIGINT` | **連続:** FD則で決定されたビンの数。<br>**カテゴリ:** ユニークな値の数（種類の数）。 |
| **`normalized_entropy`** | `DOUBLE` | **正規化スコア (0.0 - 1.0)**。<br>`0.0`: 全て同じ値（完全に偏っている）。<br>`1.0`: 均等に分布している（最も予測しにくい）。 |

## 使用例

```sql
-- 1. 連続変数の評価（例：売上金額）- スカラー
SELECT normalized_entropy_continuous((SELECT list(amount) FROM sales));

-- 2. 連続変数の評価（例：売上金額）- テーブル
SELECT * FROM normalized_entropy_continuous_tbl((SELECT list(amount) FROM sales));

-- 3. カテゴリ変数の評価（例：商品カテゴリ）- スカラー
SELECT normalized_entropy_category((SELECT list(category) FROM sales));

-- 4. カテゴリ変数の評価（例：商品カテゴリ）- テーブル
SELECT * FROM normalized_entropy_category_tbl((SELECT list(category) FROM sales));
```

## ⚠️ 解釈上の注意

| Score | 意味 |
| :--- | :--- |
| **Near 0.0** | データは特定の値に集中しており、情報量が少ない状態です。 |
| **Near 1.0** | データは取りうる範囲全体に均等に散らばっています。 |

*   **NULL**は計算前に除外される
*   **注意:** ユーザーIDのような「全行ユニーク」なカラムに `normalized_entropy_category` を使用しないでください。常に `1.0` が返されます。
