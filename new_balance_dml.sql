# query to do update-in-place, updating balances
# for each customer/transaction combo
# need to test for viability with large data
UPDATE
  scd.trans t
SET
  balance = (
  SELECT
    SUM(amount)
  FROM
    scd.trans t2
  WHERE
    t2.cust_id=t.cust_id
    and t2.trans_id <= t.trans_id)
WHERE
  TRUE