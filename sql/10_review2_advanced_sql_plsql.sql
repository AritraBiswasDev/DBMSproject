-- ============================================================================
-- Simple ATM Management System - Review 2 Submission
-- Script 10: Advanced SQL & PL/SQL Implementation (10 Marks)
-- ============================================================================
-- Contents:
--   1. Subqueries (Scalar, Nested IN/EXISTS, Correlated Subquery)
--   2. Joins (INNER JOIN, LEFT OUTER JOIN, SELF / CROSS JOIN)
--   3. Views (Analytical Views, Security Views, Monitoring Views)
--   4. Stored Procedures (PL/SQL Atomic Transaction Processing with SAVEPOINT)
--   5. User-Defined Functions (PL/SQL & SQL Pure Function Calculations)
--   6. Cursors (PL/SQL Explicit Cursors with OPEN, FETCH, CLOSE loop)
--   7. Database Triggers (BEFORE / AFTER Row-Level Integrity Enforcement)
-- ============================================================================

-- ============================================================================
-- 1. SUBQUERIES
-- ============================================================================

-- 1.1 Nested Subquery with IN: Find all customers who have performed transactions > ₹10,000
SELECT customer_id, first_name, last_name, email, city
FROM customers
WHERE customer_id IN (
    SELECT a.customer_id
    FROM accounts a
    JOIN transactions t ON a.account_id = t.account_id
    WHERE t.amount > 10000.00 AND t.status = 'SUCCESS'
);

-- 1.2 Correlated Subquery: Find accounts whose balance is strictly above the average balance of their account type
SELECT a1.account_id, a1.account_number, a1.account_type, a1.balance
FROM accounts a1
WHERE a1.balance > (
    SELECT AVG(a2.balance)
    FROM accounts a2
    WHERE a2.account_type = a1.account_type
);

-- 1.3 Scalar Subquery: Display each ATM along with the percentage of total fleet cash it holds
SELECT 
    terminal_code,
    city,
    current_cash_level,
    ROUND(
        (current_cash_level * 100.0) / (SELECT SUM(current_cash_level) FROM atm_machines), 
        2
    ) AS pct_of_network_reserves
FROM atm_machines
WHERE status = 'ONLINE';


-- ============================================================================
-- 2. JOINS
-- ============================================================================

-- 2.1 Multi-Table INNER JOIN: Comprehensive Customer Card & Account Ledger
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    a.account_number,
    a.account_type,
    a.balance,
    '****-****-****-' || SUBSTR(cd.card_number, 13, 4) AS masked_card,
    cd.status AS card_status
FROM customers c
INNER JOIN accounts a ON c.customer_id = a.customer_id
INNER JOIN cards cd ON a.account_id = cd.account_id
WHERE a.status = 'ACTIVE';

-- 2.2 LEFT OUTER JOIN: Audit of all physical ATMs and their recorded withdrawals
-- Terminals with 0 withdrawals still appear in results with count = 0
SELECT 
    m.atm_id,
    m.terminal_code,
    m.city,
    m.current_cash_level,
    COUNT(t.transaction_id) AS total_withdrawals_handled,
    COALESCE(SUM(t.amount), 0.00) AS total_dispensed_volume
FROM atm_machines m
LEFT OUTER JOIN transactions t 
    ON m.atm_id = t.atm_id AND t.transaction_type = 'WITHDRAWAL' AND t.status = 'SUCCESS'
GROUP BY m.atm_id, m.terminal_code, m.city, m.current_cash_level
ORDER BY total_dispensed_volume DESC;

-- 2.3 SELF-JOIN / CROSS JOIN: Geodesic Inter-Terminal Distance Matrix
SELECT 
    a1.terminal_code AS origin_atm,
    a1.city AS origin_city,
    a2.terminal_code AS dest_atm,
    a2.city AS dest_city,
    ROUND(6371.0 * acos(
        max(-1.0, min(1.0,
            sin(radians(a1.latitude)) * sin(radians(a2.latitude)) +
            cos(radians(a1.latitude)) * cos(radians(a2.latitude)) *
            cos(radians(a2.longitude - a1.longitude))
        ))
    ), 2) AS distance_km
FROM atm_machines a1
CROSS JOIN atm_machines a2
WHERE a1.atm_id < a2.atm_id;


-- ============================================================================
-- 3. VIEWS
-- ============================================================================

-- 3.1 Operational View: Real-Time ATM Cash Liquidity & Stockout Urgency
CREATE VIEW IF NOT EXISTS v_atm_liquidity_monitor AS
SELECT 
    atm_id,
    terminal_code,
    branch_name,
    city,
    cash_capacity,
    current_cash_level,
    ROUND((current_cash_level / cash_capacity) * 100.0, 1) AS fill_percentage,
    ROUND(current_cash_level / daily_burn_rate, 2) AS days_to_stockout,
    CASE 
        WHEN current_cash_level <= min_threshold_level THEN 'CRITICAL_REORDER'
        WHEN (current_cash_level / daily_burn_rate) <= 1.5 THEN 'HIGH_URGENCY'
        ELSE 'NORMAL'
    END AS operational_health
FROM atm_machines;

-- 3.2 Forensic Security View: Cryptographic Merkle Hash Chain Audit View
CREATE VIEW IF NOT EXISTS v_cryptographic_ledger_review AS
SELECT 
    t.transaction_id,
    t.account_id,
    t.amount,
    t.balance_after,
    t.prev_hash,
    t.entry_hash,
    LAG(t.entry_hash, 1, '0000000000000000000000000000000000000000000000000000000000000000') 
        OVER (ORDER BY t.transaction_id) AS expected_prev_hash,
    CASE 
        WHEN t.prev_hash = LAG(t.entry_hash, 1, '0000000000000000000000000000000000000000000000000000000000000000') 
             OVER (ORDER BY t.transaction_id) THEN 'VALID_BLOCK'
        ELSE 'TAMPERED_BROKEN_CHAIN'
    END AS block_status
FROM transactions t;


-- ============================================================================
-- 4. PROCEDURES (Oracle PL/SQL Implementation)
-- ============================================================================

-- Stored Procedure: Atomic Cash Withdrawal with Multi-Table Locks and Exception Handling
CREATE OR REPLACE PROCEDURE sp_process_withdrawal (
    p_card_number   IN  VARCHAR2,
    p_pin           IN  VARCHAR2,
    p_atm_id        IN  NUMBER,
    p_amount        IN  NUMBER,
    p_status        OUT VARCHAR2,
    p_msg           OUT VARCHAR2
) IS
    v_card_id       cards.card_id%TYPE;
    v_acc_id        accounts.account_id%TYPE;
    v_pin_hash      cards.pin_hash%TYPE;
    v_card_status   cards.status%TYPE;
    v_balance       accounts.balance%TYPE;
    v_min_bal       accounts.minimum_balance%TYPE;
    v_atm_cash      atm_machines.current_cash_level%TYPE;
    v_prev_hash     VARCHAR2(64);
    v_entry_hash    VARCHAR2(64);

    ex_card_blocked EXCEPTION;
    ex_invalid_pin  EXCEPTION;
    ex_atm_cash     EXCEPTION;
    ex_insufficient EXCEPTION;
BEGIN
    SAVEPOINT sp_withdrawal_start;
    p_status := 'FAILED';

    -- 1. Validate Card and PIN Hash
    SELECT card_id, account_id, status, pin_hash 
    INTO v_card_id, v_acc_id, v_card_status, v_pin_hash
    FROM cards 
    WHERE card_number = p_card_number 
    FOR UPDATE;

    IF v_card_status != 'ACTIVE' THEN
        RAISE ex_card_blocked;
    END IF;

    IF STANDARD_HASH(p_pin, 'SHA256') != v_pin_hash THEN
        UPDATE cards 
        SET failed_pin_attempts = failed_pin_attempts + 1 
        WHERE card_id = v_card_id;
        COMMIT;
        RAISE ex_invalid_pin;
    END IF;

    -- Reset failed attempts upon successful PIN authentication
    UPDATE cards SET failed_pin_attempts = 0 WHERE card_id = v_card_id;

    -- 2. Verify ATM Vault Cash Reserves
    SELECT current_cash_level INTO v_atm_cash
    FROM atm_machines WHERE atm_id = p_atm_id FOR UPDATE;

    IF v_atm_cash < p_amount THEN
        RAISE ex_atm_cash;
    END IF;

    -- 3. Verify Account Balance & Minimum Balance Constraint
    SELECT balance, minimum_balance INTO v_balance, v_min_bal
    FROM accounts WHERE account_id = v_acc_id FOR UPDATE;

    IF (v_balance - p_amount) < v_min_bal THEN
        RAISE ex_insufficient;
    END IF;

    -- 4. Execute Atomic Double-Entry Balance Updates
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_acc_id;
    UPDATE atm_machines SET current_cash_level = current_cash_level - p_amount WHERE atm_id = p_atm_id;

    -- 5. Cryptographic Hash Chain Insertion
    SELECT NVL(entry_hash, LPAD('0', 64, '0')) INTO v_prev_hash
    FROM (SELECT entry_hash FROM transactions ORDER BY transaction_id DESC) WHERE ROWNUM = 1;

    v_entry_hash := STANDARD_HASH(v_acc_id || '|' || p_amount || '|' || v_prev_hash, 'SHA256');

    INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, prev_hash, entry_hash)
    VALUES (v_acc_id, p_atm_id, 'WITHDRAWAL', p_amount, v_balance - p_amount, 'SUCCESS', v_prev_hash, v_entry_hash);

    COMMIT;
    p_status := 'SUCCESS';
    p_msg := 'Cash dispensed successfully.';

EXCEPTION
    WHEN ex_card_blocked THEN
        p_msg := 'Declined: Card is blocked or inactive.';
    WHEN ex_invalid_pin THEN
        p_msg := 'Authentication failed: Invalid PIN.';
    WHEN ex_insufficient THEN
        ROLLBACK TO sp_withdrawal_start;
        p_msg := 'Declined: Insufficient account balance.';
    WHEN ex_atm_cash THEN
        ROLLBACK TO sp_withdrawal_start;
        p_msg := 'Declined: ATM terminal has insufficient physical cash.';
    WHEN OTHERS THEN
        ROLLBACK TO sp_withdrawal_start;
        p_msg := 'Internal transaction error: ' || SQLERRM;
END sp_process_withdrawal;
/


-- ============================================================================
-- 5. FUNCTIONS (Oracle PL/SQL Implementation)
-- ============================================================================

-- 5.1 Function: Compute Geodesic Haversine Distance (km) between Two Coordinates
CREATE OR REPLACE FUNCTION fn_haversine_distance (
    p_lat1 IN NUMBER,
    p_lon1 IN NUMBER,
    p_lat2 IN NUMBER,
    p_lon2 IN NUMBER
) RETURN NUMBER IS
    v_r        CONSTANT NUMBER := 6371.0; -- Earth radius in km
    v_rad_lat1 NUMBER; v_rad_lat2 NUMBER;
    v_rad_lon1 NUMBER; v_rad_lon2 NUMBER;
    v_dlat     NUMBER; v_dlon     NUMBER;
    v_a        NUMBER; v_c        NUMBER;
BEGIN
    v_rad_lat1 := p_lat1 * (ACOS(-1) / 180);
    v_rad_lat2 := p_lat2 * (ACOS(-1) / 180);
    v_rad_lon1 := p_lon1 * (ACOS(-1) / 180);
    v_rad_lon2 := p_lon2 * (ACOS(-1) / 180);

    v_dlat := v_rad_lat2 - v_rad_lat1;
    v_dlon := v_rad_lon2 - v_rad_lon1;

    v_a := POWER(SIN(v_dlat / 2), 2) +
           COS(v_rad_lat1) * COS(v_rad_lat2) * POWER(SIN(v_dlon / 2), 2);
    v_c := 2 * ATAN2(SQRT(v_a), SQRT(1 - v_a));

    RETURN ROUND(v_r * v_c, 2);
END fn_haversine_distance;
/

-- 5.2 Function: Compute Daily Cash Burn Velocity & Stockout Risk
CREATE OR REPLACE FUNCTION fn_estimate_stockout_days (
    p_atm_id IN NUMBER
) RETURN NUMBER IS
    v_cash  NUMBER;
    v_burn  NUMBER;
BEGIN
    SELECT current_cash_level, daily_burn_rate INTO v_cash, v_burn
    FROM atm_machines WHERE atm_id = p_atm_id;

    IF v_burn <= 0 THEN RETURN 999.0; END IF;
    RETURN ROUND(v_cash / v_burn, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0.0;
END fn_estimate_stockout_days;
/


-- ============================================================================
-- 6. CURSORS (Oracle PL/SQL Implementation)
-- ============================================================================

-- Explicit Cursor: Batch Assessment of All Terminals for Emergency CIT Replenishment
CREATE OR REPLACE PROCEDURE sp_dispatch_cash_replenishment_batch IS
    -- Explicit Cursor Declaration
    CURSOR c_low_cash_atms IS
        SELECT atm_id, terminal_code, city, current_cash_level, cash_capacity, daily_burn_rate
        FROM atm_machines
        WHERE current_cash_level <= min_threshold_level
          AND status = 'ONLINE';

    -- Record variable to hold fetched row
    r_atm c_low_cash_atms%ROWTYPE;
    v_reorder_qty NUMBER;
    v_days_left   NUMBER;
BEGIN
    -- Open Cursor
    OPEN c_low_cash_atms;
    LOOP
        -- Fetch next row
        FETCH c_low_cash_atms INTO r_atm;
        EXIT WHEN c_low_cash_atms%NOTFOUND;

        v_reorder_qty := r_atm.cash_capacity - r_atm.current_cash_level;
        v_days_left   := ROUND(r_atm.current_cash_level / r_atm.daily_burn_rate, 2);

        DBMS_OUTPUT.PUT_LINE(
            'CIT DISPATCH ALERT: Terminal ' || r_atm.terminal_code || 
            ' (' || r_atm.city || ') has ' || v_days_left || ' days cash remaining. ' ||
            'Order generated for ₹' || v_reorder_qty
        );

        -- Insert replenishment logistics dispatch order
        INSERT INTO cash_replenishments (
            atm_id, requested_amount, urgency_level, vehicle_number, status
        ) VALUES (
            r_atm.atm_id, v_reorder_qty, 'HIGH_URGENCY', 'MH-01-CV-7890', 'DISPATCHED'
        );
    END LOOP;
    
    -- Close Cursor
    CLOSE c_low_cash_atms;
    COMMIT;
END sp_dispatch_cash_replenishment_batch;
/


-- ============================================================================
-- 7. TRIGGERS (Database Integrity & Security Enforcement)
-- ============================================================================

-- 7.1 Oracle PL/SQL Trigger: Strict Overdraft Prevention
CREATE OR REPLACE TRIGGER trg_prevent_negative_balance
BEFORE UPDATE OF balance ON accounts
FOR EACH ROW
BEGIN
    IF :NEW.balance < 0.00 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ACID Violation: Negative account balances are prohibited.');
    END IF;
END;
/

-- 7.2 Oracle PL/SQL Trigger: Automatic Card Lockdown on 3 Failed PIN Attempts
CREATE OR REPLACE TRIGGER trg_block_card_failed_attempts
BEFORE UPDATE OF failed_pin_attempts ON cards
FOR EACH ROW
BEGIN
    IF :NEW.failed_pin_attempts >= 3 THEN
        :NEW.status := 'BLOCKED';
    END IF;
END;
/

-- 7.3 SQLite Equivalent Triggers (Active in local atm_system.db)
CREATE TRIGGER IF NOT EXISTS trg_prevent_negative_balance_sqlite
BEFORE UPDATE OF balance ON accounts
FOR EACH ROW
WHEN NEW.balance < 0.00
BEGIN
    SELECT RAISE(ABORT, 'ACID Violation: Negative account balances are prohibited.');
END;

CREATE TRIGGER IF NOT EXISTS trg_block_card_failed_attempts_sqlite
BEFORE UPDATE OF failed_pin_attempts ON cards
FOR EACH ROW
WHEN NEW.failed_pin_attempts >= 3
BEGIN
    UPDATE cards SET status = 'BLOCKED' WHERE card_id = NEW.card_id;
END;
