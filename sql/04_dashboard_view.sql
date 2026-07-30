-- =====================================================================
-- 04_dashboard_view.sql
-- Purpose: Create a single flat view joining the fact table back to all
-- dimensions, suitable as a direct data source for Tableau or Power BI.
-- =====================================================================

CREATE OR REPLACE VIEW `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.vw_shipments_dashboard` AS
SELECT
  f.ID,
  w.Warehouse_block,
  m.Mode_of_Shipment,
  p.Product_importance,
  g.Gender,
  f.Customer_care_calls,
  f.Customer_rating,
  f.Cost_of_the_Product,
  f.Prior_purchases,
  f.Discount_offered,
  f.Weight_in_gms,
  f.Reached_on_Time_Y_or_N
FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.fact_shipments` f
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_warehouse` w ON f.warehouse_key = w.warehouse_key
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_shipment_mode` m ON f.shipment_mode_key = m.shipment_mode_key
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_product_importance` p ON f.importance_key = p.importance_key
JOIN `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.dim_gender` g ON f.gender_key = g.gender_key;

-- Validation: confirm the view returns all rows with no drops
SELECT * FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.vw_shipments_dashboard` LIMIT 10;
SELECT COUNT(*) FROM `project-d9613b04-8b7a-42e1-820.Ecommerce_Shipment.vw_shipments_dashboard`;
