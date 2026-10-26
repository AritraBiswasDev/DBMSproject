-- ============================================================================
-- Simple ATM Management System - Advanced Analytics Extension
-- Script 08: In-Database Predictive Cash Replenishment & Logistics Engine
-- DBMS Case Study: Inventory Theory, Moving Averages & Reorder Point Modeling
-- ============================================================================
-- Technical Focus:
--   1. Inventory Theory in Relational Databases (Safety Stock & Reorder Points)
--   2. Multi-Period Analytical Window Functions (Moving Average Daily Burn Rates)
--   3. Pure SQL Days-to-Stockout and Hours-to-Stockout Depletion Modeling
--   4. Economic Replenishment Quantity (EOQ Target Top-Up) Calculations
--   5. Urgency Classification (CRITICAL_STOCKOUT, HIGH_URGENCY, MODERATE, OPTIMAL)
--   6. Cash-In-Transit (CIT) Armored Van Dispatch & Logistics Tracking
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Configuration Table for Cash Management Parameters
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cash_replenishment_config (
    config_key           VARCHAR(50) PRIMARY KEY,
    config_value         DECIMAL(10, 2) NOT NULL,
    unit                 VARCHAR(20) NOT NULL,
    description          VARCHAR(200) NOT NULL
);

INSERT OR REPLACE INTO cash_replenishment_config (config_key, config_value, unit, description)
VALUES
('CIT_LEAD_TIME_DAYS',           1.00, 'days',    'Standard armored van fulfillment lead time'),
('SAFETY_STOCK_RATIO',           0.25, 'ratio',   'Safety stock buffer as proportion of terminal capacity'),
('CRITICAL_STOCKOUT_HOURS',     12.00, 'hours',   'Hours threshold below which emergency dispatch is mandatory'),
('HIGH_URGENCY_DAYS',            1.50, 'days',    'Days-to-stockout threshold triggering automated CIT order'),
('ROUTINE_CYCLE_DAYS',           7.00, 'days',    'Standard scheduled preventative replenishment cycle');

-- ----------------------------------------------------------------------------
-- 2. View: Daily Cash Dispensed History per ATM
-- Aggregates financial ledger transactions into calendar day withdrawal totals.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_atm_daily_burn_history;
CREATE VIEW v_atm_daily_burn_history AS
SELECT
    atm_id,
    substr(transaction_timestamp, 1, 10) AS tx_date,
    COUNT(transaction_id) AS withdrawal_count,
    ROUND(SUM(amount), 2) AS daily_cash_dispensed,
    ROUND(AVG(amount), 2) AS avg_withdrawal_ticket
FROM transactions
WHERE transaction_type = 'WITHDRAWAL'
  AND status = 'SUCCESS'
  AND atm_id IS NOT NULL
GROUP BY atm_id, substr(transaction_timestamp, 1, 10);

-- ----------------------------------------------------------------------------
-- 3. View: Analytical Window Functions for 3-Day Moving Average Burn Rate
-- Applies SQL analytic window functions:
-- AVG(...) OVER (PARTITION BY atm_id ORDER BY tx_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
-- Smooths sudden weekend or festival demand spikes.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_atm_moving_burn_velocity;
CREATE VIEW v_atm_moving_burn_velocity AS
SELECT
    atm_id,
    tx_date,
    daily_cash_dispensed,
    ROUND(
        AVG(daily_cash_dispensed) OVER (
            PARTITION BY atm_id
            ORDER BY tx_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_burn_3d
FROM v_atm_daily_burn_history;

-- ----------------------------------------------------------------------------
-- 4. View: Real-Time ATM Stockout Forecast & Reorder Urgency Radar
-- Combines current cash balance, baseline daily burn rate, and empirical 
-- moving averages to compute days-to-stockout, hours-to-stockout,
-- suggested replenishment volume, and urgency classification.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_atm_stockout_forecast;
CREATE VIEW v_atm_stockout_forecast AS
WITH latest_burn AS (
    SELECT 
        atm_id, 
        moving_avg_burn_3d 
    FROM (
        SELECT 
            atm_id, 
            moving_avg_burn_3d,
            ROW_NUMBER() OVER (PARTITION BY atm_id ORDER BY tx_date DESC) as rn
        FROM v_atm_moving_burn_velocity
    ) WHERE rn = 1
)
SELECT 
    a.atm_id,
    a.terminal_code,
    a.branch_name,
    a.city,
    a.cash_capacity,
    a.current_cash_level,
    a.min_threshold_level,
    ROUND(
        COALESCE(
            CASE 
                WHEN lb.moving_avg_burn_3d IS NOT NULL AND lb.moving_avg_burn_3d >= 2000 THEN lb.moving_avg_burn_3d
                ELSE a.daily_burn_rate 
            END, 
            a.daily_burn_rate
        ), 2
    ) AS effective_daily_burn,
    ROUND(
        COALESCE(
            CASE 
                WHEN lb.moving_avg_burn_3d IS NOT NULL AND lb.moving_avg_burn_3d >= 2000 THEN lb.moving_avg_burn_3d
                ELSE a.daily_burn_rate 
            END, 
            a.daily_burn_rate
        ) / 24.0, 2
    ) AS hourly_burn_rate,
    ROUND(
        CAST(a.current_cash_level AS REAL) / NULLIF(
            COALESCE(
                CASE 
                    WHEN lb.moving_avg_burn_3d IS NOT NULL AND lb.moving_avg_burn_3d >= 2000 THEN lb.moving_avg_burn_3d
                    ELSE a.daily_burn_rate 
                END, 
                a.daily_burn_rate
            ), 0
        ), 2
    ) AS days_to_stockout,
    ROUND(
        (CAST(a.current_cash_level AS REAL) / NULLIF(
            COALESCE(
                CASE 
                    WHEN lb.moving_avg_burn_3d IS NOT NULL AND lb.moving_avg_burn_3d >= 2000 THEN lb.moving_avg_burn_3d
                    ELSE a.daily_burn_rate 
                END, 
                a.daily_burn_rate
            ), 0
        )) * 24.0, 1
    ) AS hours_to_stockout,
    ROUND((CAST(a.current_cash_level AS REAL) / a.cash_capacity) * 100.0, 1) AS capacity_utilization_pct,
    ROUND(a.cash_capacity - a.current_cash_level, 2) AS suggested_replenishment_amount,
    CASE 
        WHEN a.status = 'OUT_OF_CASH' OR a.current_cash_level <= 0 THEN 'OUT_OF_CASH'
        WHEN a.current_cash_level <= a.min_threshold_level OR (CAST(a.current_cash_level AS REAL) / NULLIF(COALESCE(a.daily_burn_rate, 5000), 0)) <= 0.5 THEN 'CRITICAL_STOCKOUT'
        WHEN (CAST(a.current_cash_level AS REAL) / NULLIF(COALESCE(a.daily_burn_rate, 5000), 0)) <= 1.5 THEN 'HIGH_URGENCY'
        WHEN (CAST(a.current_cash_level AS REAL) / NULLIF(COALESCE(a.daily_burn_rate, 5000), 0)) <= 3.0 THEN 'MODERATE'
        ELSE 'OPTIMAL'
    END AS stockout_risk_category,
    CASE
        WHEN a.status = 'OUT_OF_CASH' OR a.current_cash_level <= a.min_threshold_level OR (CAST(a.current_cash_level AS REAL) / NULLIF(COALESCE(a.daily_burn_rate, 5000), 0)) <= 1.5 THEN 1
        ELSE 0
    END AS reorder_triggered,
    a.status AS machine_status,
    a.last_serviced_date
FROM atm_machines a
LEFT JOIN latest_burn lb ON a.atm_id = lb.atm_id;

-- ----------------------------------------------------------------------------
-- 5. View: Active CIT Cash Van Logistics & Replenishment Orders
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_active_cash_replenishments;
CREATE VIEW v_active_cash_replenishments AS
SELECT
    r.replenishment_id,
    r.atm_id,
    a.terminal_code,
    a.city,
    a.branch_name,
    r.requested_amount,
    r.current_cash_at_request,
    r.burn_rate_at_request,
    r.estimated_days_left,
    r.urgency_level,
    r.status AS replenishment_status,
    r.cit_company,
    r.van_vehicle_number,
    r.dispatched_at,
    r.completed_at,
    r.created_at
FROM cash_replenishments r
JOIN atm_machines a ON r.atm_id = a.atm_id
ORDER BY 
    CASE r.status 
        WHEN 'IN_TRANSIT' THEN 1 
        WHEN 'DISPATCHED' THEN 2 
        WHEN 'SCHEDULED' THEN 3 
        ELSE 4 
    END,
    r.created_at DESC;

-- ----------------------------------------------------------------------------
-- 6. Verification Analytical Query 1: Imminent Stockouts Under 36 Hours
-- ----------------------------------------------------------------------------
SELECT 
    terminal_code,
    city,
    current_cash_level,
    effective_daily_burn,
    days_to_stockout,
    hours_to_stockout,
    stockout_risk_category,
    suggested_replenishment_amount
FROM v_atm_stockout_forecast
WHERE reorder_triggered = 1
ORDER BY days_to_stockout ASC;

-- ----------------------------------------------------------------------------
-- 7. Verification Analytical Query 2: Fleet Liquidity Distribution & Health
-- ----------------------------------------------------------------------------
SELECT
    COUNT(atm_id) AS total_terminals,
    ROUND(SUM(current_cash_level), 2) AS total_vault_cash,
    ROUND(SUM(cash_capacity), 2) AS total_network_capacity,
    ROUND((SUM(current_cash_level) / SUM(cash_capacity)) * 100.0, 1) AS network_liquidity_pct,
    SUM(CASE WHEN stockout_risk_category IN ('CRITICAL_STOCKOUT', 'OUT_OF_CASH') THEN 1 ELSE 0 END) AS critical_alarms,
    SUM(CASE WHEN reorder_triggered = 1 THEN 1 ELSE 0 END) AS total_reorders_pending
FROM v_atm_stockout_forecast;
