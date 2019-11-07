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