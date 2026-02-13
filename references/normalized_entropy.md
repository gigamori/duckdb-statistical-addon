# 📚 DuckDB Normalized Entropy Macros

## Overview
These SQL macros calculate **Normalized Entropy (0.0 to 1.0)** for data arrays. They allow you to quantify the "randomness" or "uniformity" of data distributions. By normalizing the entropy, you can fairly compare the dispersion of **continuous variables** (e.g., age, price) against **categorical/binary variables** (e.g., gender, status).

**Algorithm:** Shannon Entropy with Freedman-Diaconis Rule (for continuous) & Cardinality Normalization (for categorical).

## 1. `normalized_entropy_continuous(input_array)` / `normalized_entropy_continuous_tbl(input_array)`
Used for **Continuous/Numerical** variables.
It automatically determines the optimal number of bins using the **Freedman-Diaconis rule** to discretize the data before calculating entropy.

*   **Input:** `input_array` (List/Array of Numbers, e.g., `[1.5, 2.0, 5.1]`)
*   **Logic:**
    1.  Calculate Interquartile Range (IQR).
    2.  Determine Bin Width $h = 2 \times IQR \times n^{-1/3}$.
    3.  Generate Histogram.
    4.  Calculate Entropy $H$.
    5.  Normalize: $H / \log_2(\text{number\_of\_bins})$.

## 2. `normalized_entropy_category(input_array)` / `normalized_entropy_category_tbl(input_array)`
Used for **Categorical, Binary, or Discrete** variables.
It treats each unique value as a distinct "bin".

*   **Input:** `input_array` (List/Array of Strings or Booleans, e.g., `['A', 'B', 'A']`)
*   **Logic:**
    1.  Count occurrences of each unique value.
    2.  Calculate Entropy $H$.
    3.  Normalize: $H / \log_2(\text{number\_of\_unique\_values})$.

## Return Values (Schema)
- Scalar functions (`normalized_entropy_continuous`, `normalized_entropy_category`) return a single DOUBLE value.
- Table functions (`normalized_entropy_continuous_tbl`, `normalized_entropy_category_tbl`) return a table with the following columns:

| Column | Type | Description |
| :--- | :--- | :--- |
| **`raw_entropy`** | `DOUBLE` | The Shannon Entropy (in bits). |
| **`num_bins`** | `BIGINT` | **Continuous:** Number of histogram bins (FD rule).<br>**Categorical:** Number of unique values (Cardinality). |
| **`normalized_entropy`** | `DOUBLE` | **The Score (0.0 - 1.0).**<br>`0.0`: All values are the same (Concentrated).<br>`1.0`: Values are perfectly uniform (Dispersed). |

## Usage Example

```sql
-- 1. Continuous Variable (e.g., Price) - Scalar
SELECT normalized_entropy_continuous((SELECT list(price) FROM sales_data));

-- 2. Continuous Variable (e.g., Price) - Table
SELECT * FROM normalized_entropy_continuous_tbl((SELECT list(price) FROM sales_data));

-- 3. Categorical Variable (e.g., City) - Scalar
SELECT normalized_entropy_category((SELECT list(city) FROM sales_data));

-- 4. Categorical Variable (e.g., City) - Table
SELECT * FROM normalized_entropy_category_tbl((SELECT list(city) FROM sales_data));
```

## ⚠️ Interpretation Note

| Score | Meaning |
| :--- | :--- |
| **Near 0.0** | **Low Information / Deterministic**<br>The data is concentrated on a single value or a very narrow range. |
| **Near 1.0** | **High Information / Uniform**<br>The data is spread evenly across all bins or categories. |

*   **Note for IDs:** Do not use `normalized_entropy_category` on unique ID columns (e.g., UserID). It will always return `1.0` because every value is unique.
