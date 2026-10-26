-- ============================================================================
-- Simple ATM Management System - Advanced Security Extension
-- Script 07: In-Database Real-Time Fraud & Geo-Velocity Detection Engine
-- DBMS Case Study: Spatial Distance, Temporal Window Functions & Forensics
-- ============================================================================
-- Technical Focus:
--   1. Geolocation Modeling (Latitude / Longitude coordinates for physical ATMs)
--   2. Haversine / Spherical Trigonometric Distance Calculation in Pure SQL
--   3. Analytical Window Functions (LAG, OVER, PARTITION BY) for transit tracking
--   4. Impossible Travel (Geo-Velocity Anomaly: speed > 500 km/h) detection
--   5. Micro-Frequency Burst Detection (rapid automated attacks)
--   6. High-Value Outlier Anomaly Isolation
--   7. Automated Security Lockdown & Forensic Audit Ledger
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Configuration & Rules Table
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fraud_rules_config (
    rule_code            VARCHAR(30) PRIMARY KEY,
    rule_name            VARCHAR(100) NOT NULL,
    threshold_value      DECIMAL(10, 2) NOT NULL,
    unit                 VARCHAR(20) NOT NULL,
    severity_level       VARCHAR(15) NOT NULL,
    auto_action          VARCHAR(50) NOT NULL,
    is_active            INTEGER NOT NULL DEFAULT 1
);

INSERT OR REPLACE INTO fraud_rules_config (rule_code, rule_name, threshold_value, unit, severity_level, auto_action, is_active)
VALUES
('GEO_VELOCITY_LIMIT',    'Maximum Plausible Transit Speed',      500.00,   'km/h',    'CRITICAL', 'CARD_AUTO_LOCKED',    1),
('RAPID_BURST_COUNT',     'Max Transactions in Short Window',       3.00,   'count',   'HIGH',     'TRANSACTION_BLOCKED', 1),
('RAPID_BURST_WINDOW',    'Short Burst Time Window',                5.00,   'minutes', 'HIGH',     'TRANSACTION_BLOCKED', 1),
('HIGH_VALUE_THRESHOLD',  'Single Cash Withdrawal Ceiling Spike', 25000.00, 'INR',     'MEDIUM',   'FLAGGED_FOR_REVIEW',  1),
('OFF_HOURS_THRESHOLD',   'Late Night Cash Withdrawal Ceiling',   10000.00, 'INR',     'MEDIUM',   'FLAGGED_FOR_REVIEW',  1);

-- ----------------------------------------------------------------------------
-- 2. View: Pre-Computed Geodesic Distances Across All ATM Terminal Pairs
-- Uses the Spherical Law of Cosines directly in SQL:
-- Distance = 6371 * acos( sin(lat1)*sin(lat2) + cos(lat1)*cos(lat2)*cos(lon2 - lon1) )
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_atm_network_distances;
CREATE VIEW v_atm_network_distances AS
SELECT 
    a1.atm_id AS from_atm_id,
    a1.terminal_code AS from_code,
    a1.city AS from_city,
    a2.atm_id AS to_atm_id,
    a2.terminal_code AS to_code,
    a2.city AS to_city,
    ROUND(
        6371.0 * acos(
            max(-1.0, min(1.0,
                sin(radians(a1.latitude)) * sin(radians(a2.latitude)) +
                cos(radians(a1.latitude)) * cos(radians(a2.latitude)) *
                cos(radians(a2.longitude - a1.longitude))
            ))
        ), 2
    ) AS distance_km
FROM atm_machines a1
CROSS JOIN atm_machines a2
WHERE a1.atm_id != a2.atm_id;

-- ----------------------------------------------------------------------------
-- 3. View: Card Movement & Geo-Velocity Temporal Audit Log
-- Applies Window Function LAG() to compute sequential travel time and speed.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_card_movement_analysis;
CREATE VIEW v_card_movement_analysis AS
WITH ordered_card_events AS (
    SELECT 
        t.transaction_id,
        t.account_id,
        c.card_id,
        c.card_number,
        t.transaction_type,
        t.amount,
        t.status,
        t.transaction_timestamp,
        t.atm_id AS current_atm_id,
        atm_curr.terminal_code AS current_terminal,
        atm_curr.city AS current_city,
        atm_curr.latitude AS current_lat,
        atm_curr.longitude AS current_lon,
        -- Prior transaction attributes using LAG()
        LAG(t.transaction_id) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_transaction_id,
        LAG(t.atm_id) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_atm_id,
        LAG(atm_curr.terminal_code) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_terminal,
        LAG(atm_curr.city) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_city,
        LAG(atm_curr.latitude) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_lat,
        LAG(atm_curr.longitude) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_lon,
        LAG(t.transaction_timestamp) OVER (PARTITION BY t.account_id ORDER BY t.transaction_timestamp, t.transaction_id) AS prev_timestamp
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN cards c ON a.account_id = c.account_id
    LEFT JOIN atm_machines atm_curr ON t.atm_id = atm_curr.atm_id
    WHERE t.atm_id IS NOT NULL -- ATM operations only
)
SELECT 
    transaction_id,
    account_id,
    card_id,
    '****-****-****-' || SUBSTR(card_number, 13, 4) AS masked_card,
    transaction_type,
    amount,
    status,
    prev_terminal || ' (' || prev_city || ') -> ' || current_terminal || ' (' || current_city || ')' AS transit_route,
    prev_timestamp,
    transaction_timestamp AS current_timestamp,
    ROUND((julianday(transaction_timestamp) - julianday(prev_timestamp)) * 1440.0, 2) AS delta_minutes,
    ROUND(
        6371.0 * acos(
            max(-1.0, min(1.0,
                sin(radians(prev_lat)) * sin(radians(current_lat)) +
                cos(radians(prev_lat)) * cos(radians(current_lat)) *
                cos(radians(current_lon - prev_lon))
            ))
        ), 2
    ) AS distance_km,
    CASE 
        WHEN (julianday(transaction_timestamp) - julianday(prev_timestamp)) * 24.0 > 0 THEN
            ROUND(
                (6371.0 * acos(
                    max(-1.0, min(1.0,
                        sin(radians(prev_lat)) * sin(radians(current_lat)) +
                        cos(radians(prev_lat)) * cos(radians(current_lat)) *
                        cos(radians(current_lon - prev_lon))
                    ))
                )) / ((julianday(transaction_timestamp) - julianday(prev_timestamp)) * 24.0), 2
            )
        ELSE 0.00
    END AS implied_speed_kmh
FROM ordered_card_events
WHERE prev_atm_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 4. FORENSIC QUERY 1: Real-Time Impossible Travel (Geo-Velocity Violations)
-- Flags cards where implied physical transit speed exceeds commercial air travel (> 500 km/h)
-- ----------------------------------------------------------------------------
SELECT 
    transaction_id,
    account_id,
    masked_card,
    transit_route,
    delta_minutes || ' mins' AS elapsed_time,
    distance_km || ' km' AS physical_distance,
    implied_speed_kmh || ' km/h' AS calculated_speed,
    CASE 
        WHEN implied_speed_kmh > 1000.0 THEN 'CRITICAL (Mach-1+ Physical Impossibility)'
        WHEN implied_speed_kmh > 500.0  THEN 'CRITICAL (Impossible Commercial Transit)'
        ELSE 'NORMAL'
    END AS fraud_risk_verdict
FROM v_card_movement_analysis
WHERE implied_speed_kmh > 500.0;

-- ----------------------------------------------------------------------------
-- 5. FORENSIC QUERY 2: Micro-Frequency Burst Attacks
-- Detects brute-force / rapid skimming attacks: >= 3 transactions in <= 5 minutes
-- ----------------------------------------------------------------------------
WITH frequency_spikes AS (
    SELECT 
        t1.account_id,
        t1.transaction_id,
        t1.amount,
        t1.transaction_timestamp,
        COUNT(t2.transaction_id) AS transactions_within_5min,
        ROUND(SUM(t2.amount), 2) AS total_burst_amount
    FROM transactions t1
    JOIN transactions t2 ON t1.account_id = t2.account_id
        AND t2.transaction_timestamp BETWEEN datetime(t1.transaction_timestamp, '-5 minutes') AND t1.transaction_timestamp
    GROUP BY t1.account_id, t1.transaction_id
)
SELECT 
    f.account_id,
    a.account_number,
    f.transaction_id,
    f.transaction_timestamp,
    f.transactions_within_5min AS rapid_event_count,
    f.total_burst_amount AS cumulative_drained_amount,
    'HIGH (Potential Cashout Skimming Attack)' AS alert_classification
FROM frequency_spikes f
JOIN accounts a ON f.account_id = a.account_id
WHERE f.transactions_within_5min >= 3;

-- ----------------------------------------------------------------------------
-- 6. FORENSIC QUERY 3: Outlier Spending Analysis (Spikes vs 30-Day Account Mean)
-- ----------------------------------------------------------------------------
WITH account_profiles AS (
    SELECT 
        account_id,
        ROUND(AVG(amount), 2) AS historical_avg_withdrawal,
        ROUND(MAX(amount), 2) AS historical_peak
    FROM transactions
    WHERE transaction_type = 'WITHDRAWAL' AND status = 'SUCCESS'
    GROUP BY account_id
)
SELECT 
    t.transaction_id,
    t.account_id,
    t.amount AS current_withdrawal,
    p.historical_avg_withdrawal,
    ROUND(t.amount / NULLIF(p.historical_avg_withdrawal, 0), 2) AS spike_multiplier,
    'MEDIUM (Unusual Spending Outlier)' AS alert_classification
FROM transactions t
JOIN account_profiles p ON t.account_id = p.account_id
WHERE t.transaction_type = 'WITHDRAWAL'
  AND t.amount >= (p.historical_avg_withdrawal * 2.5)
  AND t.amount > 1000.00;

-- ----------------------------------------------------------------------------
-- 7. FORENSIC QUERY 4: Terminal Fraud & Security Heatmap
-- Analyzes which ATM terminals are subject to the highest rate of security violations
-- ----------------------------------------------------------------------------
SELECT 
    atm.atm_id,
    atm.terminal_code,
    atm.branch_name,
    atm.city,
    COUNT(fa.alert_id) AS total_security_alerts,
    COUNT(CASE WHEN fa.severity = 'CRITICAL' THEN 1 END) AS critical_geo_velocity_breaches,
    COUNT(CASE WHEN fa.action_taken = 'CARD_AUTO_LOCKED' THEN 1 END) AS automated_card_lockouts,
    COALESCE(ROUND(AVG(fa.risk_score), 1), 0.0) AS average_risk_score
FROM atm_machines atm
LEFT JOIN fraud_alerts fa ON atm.atm_id = fa.current_atm_id
GROUP BY atm.atm_id
ORDER BY total_security_alerts DESC, average_risk_score DESC;

-- ----------------------------------------------------------------------------
-- 8. Live Active Security Alerts Dashboard
-- ----------------------------------------------------------------------------
SELECT 
    alert_id,
    alert_type,
    severity,
    risk_score || '/100' AS score,
    distance_km || ' km' AS distance,
    time_delta_minutes || ' min' AS delta_t,
    implied_speed_kmh || ' km/h' AS transit_speed,
    action_taken,
    details,
    alert_timestamp
FROM fraud_alerts
ORDER BY alert_timestamp DESC, alert_id DESC;
