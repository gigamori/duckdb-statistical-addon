# cochran_armitage_test

## Purpose

Cochran–Armitage trend test.

## Inputs

- y_list: HUGEINT[] (0/1 responses)
- x_list: VARCHAR[] (ordered labels), same length as y_list
- alternative: 'two.sided' | 'greater' | 'less'
- correction: 'none' | 'yates'

## Output columns

- statistic: DOUBLE (corrected z statistic)
- statistic_uncorrected: DOUBLE (uncorrected z statistic)
- p_value: DOUBLE (tail selected by `alternative`)
- n_total: BIGINT (valid observations)
- n_success: DOUBLE (total successes)
- n_groups: BIGINT (distinct ordered labels)
- numerator_raw: DOUBLE (raw score numerator before correction)
- variance_raw: DOUBLE (score test variance)

## Notes

- NULLs are excluded pairwise.
- Categories are automatically scored 0, 1, 2, ...
- Returns no rows when requirements for the test are not met.

## Example

```sql
SELECT *
FROM cochran_armitage_test(
  (SELECT LIST(subscribed) FROM customer),
  (SELECT LIST(customer_stage) FROM customer),
  'two.sided',
  'none'
);
```
