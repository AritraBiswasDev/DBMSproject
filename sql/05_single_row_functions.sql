-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 05: Single-Row Functions
-- ============================================================================
-- Demonstrates SQL Single-Row Functions operating on individual rows:
--   1. String Functions (Formatting, Masking, Extraction)
--   2. Mathematical & Numeric Functions (Rounding, Absolute Value)
--   3. Date & Time Functions (Age, Expiry calculation, Timestamps)
--   4. Conditional & Null-Handling Functions (COALESCE, CASE, CAST)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. String Functions
-- ----------------------------------------------------------------------------

-- Query 1.1: Name Formatting & Initials (UPPER, LOWER, CONCAT, SUBSTR, LENGTH)
SELECT 
    customer_id,
    UPPER(last_name) || ', ' || first_name AS formatted_full_name,
    LOWER(email) AS normalized_email,
    SUBSTR(first_name, 1, 1) || '.' || SUBSTR(last_name, 1, 1) || '.' AS initials,
    LENGTH(street_address) AS address_character_count
FROM customers
LIMIT 5;

-- Query 1.2: PCI-DSS Compliant Card Masking (CONCAT, SUBSTR)
-- Displays only the last 4 digits of the card number, masking the rest.
SELECT 
    card_id,
    account_id,
    '****-****-****-' || SUBSTR(card_number, 13, 4) AS masked_card_number,
    card_type,
    status
FROM cards;

-- Query 1.3: String Cleaning & Replacement (TRIM, REPLACE)
SELECT 
    atm_id,
    branch_name,
    REPLACE(branch_name, 'Branch', 'Office') AS modernized_branch_title,
    TRIM(location_address) AS cleaned_address
FROM atm_machines;

-- ----------------------------------------------------------------------------
-- 2. Mathematical & Numeric Functions
-- ----------------------------------------------------------------------------

-- Query 2.1: Financial Rounding, Calculations & Projections (ROUND, ABS, CAST)
SELECT 
    account_id,
    account_number,
    balance,
    ROUND(balance * 0.035, 2) AS estimated_annual_interest_at_3_5_pct,
    ROUND(balance / 12, 2) AS monthly_liquidity_allowance,
    ABS(balance - minimum_balance) AS variance_from_minimum_requirement
FROM accounts
WHERE status = 'ACTIVE'
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 3. Date & Time Functions
-- ----------------------------------------------------------------------------

-- Query 3.1: Age Calculation & Membership Duration (DATE, CURRENT_DATE)
SELECT 
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    date_of_birth,
    CAST((strftime('%Y', CURRENT_DATE) - strftime('%Y', date_of_birth)) AS INTEGER) AS approximate_age,
    strftime('%Y-%m-%d', created_at) AS onboarded_on
FROM customers
LIMIT 5;

-- Query 3.2: Card Expiry Countdown & Warning
-- Evaluates days remaining before an ATM card expires
SELECT 
    card_id,
    '****-****-****-' || SUBSTR(card_number, 13, 4) AS masked_card,
    expiry_date,
    CAST(julianday(expiry_date) - julianday(CURRENT_DATE) AS INTEGER) AS days_until_expiry,
    CASE 
        WHEN julianday(expiry_date) < julianday(CURRENT_DATE) THEN 'EXPIRED'
        WHEN (julianday(expiry_date) - julianday(CURRENT_DATE)) <= 180 THEN 'EXPIRING SOON'
        ELSE 'VALID'
    END AS card_validity_alert
FROM cards;

-- Query 3.3: Transaction Time-of-Day Categorization
SELECT 
    transaction_id,
    transaction_type,
    amount,
    transaction_timestamp,
    strftime('%H:%M:%S', transaction_timestamp) AS transaction_time,
    CASE 
        WHEN CAST(strftime('%H', transaction_timestamp) AS INTEGER) < 12 THEN 'Morning'
        WHEN CAST(strftime('%H', transaction_timestamp) AS INTEGER) < 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day
FROM transactions
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 4. Conditional & Null-Handling Functions
-- ----------------------------------------------------------------------------

-- Query 4.1: Null Substitution with COALESCE
-- Handles transfers where destination account is present vs single-account transactions
SELECT 
    transaction_id,
    account_id AS source_account,
    COALESCE(CAST(dest_account_id AS VARCHAR), 'N/A (Self/ATM)') AS recipient_account,
    COALESCE(CAST(atm_id AS VARCHAR), 'Digital Transfer') AS terminal_reference,
    transaction_type,
    amount,
    COALESCE(description, 'No memo attached') AS memo
FROM transactions
LIMIT 8;

-- Query 4.2: Account Balance Tier Segmentation via CASE Expression
SELECT 
    account_id,
    account_number,
    account_type,
    balance,
    CASE 
        WHEN balance >= 20000.00 THEN 'Platinum Tier'
        WHEN balance >= 5000.00  THEN 'Gold Tier'
        WHEN balance >= 1000.00  THEN 'Silver Tier'
        ELSE 'Standard Tier'
    END AS wealth_management_tier
FROM accounts;

