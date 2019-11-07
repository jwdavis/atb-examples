# query to recalc balances for each customer/transaction combo
# you can project results back over existing table, or into new table
# or into a view
SELECT
  trans_id,
  date,
  cust_id,
  sur_key,
  type,
  amount,
  SUM(amount) OVER (PARTITION BY cust_id ORDER BY trans_id) as balance
FROM
  scd.trans
order by 
  trans_id