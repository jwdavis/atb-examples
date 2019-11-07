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

# query to update dimension table with new customer data
# takes existing active row and makes it inactive
# then inserts new row and makes it active
# only works when your updates have only 0-1 update per
# customer
MERGE
  scd.customer c
USING
  scd.cust_updates u
ON
  c.cust_id = u.cust_id
  WHEN MATCHED
  AND active THEN
UPDATE
SET
  `end` = u.ing_date,
  c.active = FALSE;
INSERT
  scd.customer ( sur_key,
    cust_id,
    cust_name,
    cust_phone,
    cust_city,
    active,
    start,
    `end`)
SELECT
  GENERATE_UUID() AS sur_key,
  cust_id,
  cust_name,
  cust_phone,
  cust_city,
  TRUE,
  ing_date,
  NULL
FROM
  scd.cust_updates

# query to generate new dimension table with new customer data
# handles multiple updates
INSERT
  scd.customer ( sur_key,
    cust_id,
    cust_name,
    cust_phone,
    cust_city,
    active,
    start,
    `end`)
SELECT
  GENERATE_UUID(),
  cust_id,
  details.cust_name,
  details.cust_phone,
  details.cust_city,
IF
  (details.new_end_date IS NULL,
    TRUE,
    FALSE),
  details.ing_date,
  details.new_end_date
FROM (
  WITH
    new_ends AS (
    SELECT
      *,
      LEAD(ing_date) OVER (PARTITION BY cust_id ORDER BY ing_date) AS new_end_date
    FROM
      scd.cust_updates
    ORDER BY
      cust_id,
      ing_date)
  SELECT
    cust_id,
    ARRAY_AGG(STRUCT( cust_name,
        cust_phone,
        cust_city,
        ing_date,
        new_end_date)) AS details
  FROM
    new_ends
  GROUP BY
    cust_id),
  UNNEST(details) AS details