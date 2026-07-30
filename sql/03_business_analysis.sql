-- =====================================================================
-- 03_business_analysis.sql
-- Purpose: Answer business questions about delivery performance,
-- pricing/discounting, and customer satisfaction using the star schema.
-- Uses CTEs, window functions (RANK, NTILE), and CASE-based segmentation.
-- =====================================================================

-- Shipment mode frequency: how shipments are distributed across modes
SELECT m.Mode_of_Shipment, COUNT(*) AS shipments
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_shipment_mode` m
  ON f.shipment_mode_key = m.shipment_mode_key
GROUP BY m.Mode_of_Shipment
ORDER BY shipments DESC;

-- On-time rate by warehouse block
SELECT w.Warehouse_block,
       ROUND(AVG(f.Reached_on_Time_Y_or_N) * 100, 1) AS pct_reached_on_time
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` w
  ON f.warehouse_key = w.warehouse_key
GROUP BY w.Warehouse_block
ORDER BY pct_reached_on_time DESC;

-- Average cost, discount, and weight by product importance tier
SELECT p.Product_importance,
       ROUND(AVG(f.Cost_of_the_Product), 2) AS avg_cost,
       ROUND(AVG(f.Discount_offered), 2) AS avg_discount,
       ROUND(AVG(f.Weight_in_gms), 0) AS avg_weight
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_product_importance` p
  ON f.importance_key = p.importance_key
GROUP BY p.Product_importance;

-- Rank warehouses by on-time delivery rate using a CTE + RANK()
-- Finding: all five warehouses land within ~1.6 points of each other --
-- warehouse location is not a meaningful driver of late delivery.
WITH warehouse_perf AS (
  SELECT w.Warehouse_block,
         AVG(f.Reached_on_Time_Y_or_N) AS on_time_rate
  FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
  JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` w
    ON f.warehouse_key = w.warehouse_key
  GROUP BY w.Warehouse_block
)
SELECT Warehouse_block,
       ROUND(on_time_rate * 100, 1) AS pct_on_time,
       RANK() OVER (ORDER BY on_time_rate DESC) AS rank_on_time
FROM warehouse_perf;

-- Bucket customers into rating quartiles using NTILE
SELECT ID, Customer_rating,
       NTILE(4) OVER (ORDER BY Customer_rating) AS rating_quartile
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Does discount ever exceed cost? Helps determine whether Discount_offered
-- behaves like a flat amount or a percentage.
SELECT COUNT(*) AS discount_exceeds_cost
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`
WHERE Discount_offered > Cost_of_the_Product;

-- Segment high-cost, high-discount shipments as a "problem" segment worth reviewing
SELECT ID, Cost_of_the_Product, Discount_offered,
       CASE
         WHEN Discount_offered > 50 AND Cost_of_the_Product > 200 THEN 'High cost + high discount'
         WHEN Discount_offered > 50 THEN 'High discount only'
         ELSE 'Normal'
       END AS segment
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`
ORDER BY Discount_offered DESC
LIMIT 100;

-- Overall on-time delivery percentage (headline metric)
SELECT ROUND(AVG(Reached_on_Time_Y_or_N) * 100, 1) AS pct_on_time
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Average discount offered across all shipments
SELECT ROUND(AVG(Discount_offered), 2) AS avg_discount
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Average cost per shipment (proxy for "order value" -- no true revenue field exists)
SELECT ROUND(AVG(Cost_of_the_Product), 2) AS avg_order_value_proxy
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`;

-- Average customer rating by on-time status: does lateness affect satisfaction?
SELECT Reached_on_Time_Y_or_N, ROUND(AVG(Customer_rating), 2) AS avg_rating
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.shipping`
GROUP BY Reached_on_Time_Y_or_N;
