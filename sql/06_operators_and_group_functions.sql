-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 06: Operators & Group Functions
-- ============================================================================
-- Demonstrates:
--   1. Arithmetic, Comparison, and Logical Operators
--   2. Range (BETWEEN), Set (IN), Pattern (LIKE), and Nullity (IS NULL) Operators
--   3. Aggregate Functions: COUNT, SUM, AVG, MIN, MAX
--   4. Grouping & Aggregate Filtering: GROUP BY and HAVING Clauses
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SQL Operators in Action
-- ----------------------------------------------------------------------------

-- Query 1.1: Arithmetic & Comparison Operators
-- Calculate post-fee withdrawal simulations and filter by liquidity thresholds
SELECT 
    account_id,
    account_number,
    balance,
    (balance - 50.00) AS balance_after_standard_fee,
    (balance * 0.05)  AS emergency_reserve_5_pct
FROM accounts
WHERE balance >= 1000.00;

-- Query 1.2: Logical Operators (AND, OR, NOT)
-- Filter active accounts with healthy balances that are NOT frozen or dormant
SELECT 
    account_id,
    account_number,
    account_type,
    balance,
    status
FROM accounts
WHERE (account_type = 'CHECKING' AND balance > 2000.00)
   OR (account_type = 'SAVINGS'  AND balance > 10000.00)
  AND NOT (status = 'FROZEN');

-- Query 1.3: Set (IN) and Range (BETWEEN ... AND) Operators
-- Find transactions between $200 and $1000 for withdrawals and transfers
SELECT 
    transaction_id,
    account_id,
    transaction_type,
    amount,
    status,
    transaction_timestamp
FROM transactions
WHERE transaction_type IN ('WITHDRAWAL', 'TRANSFER')
  AND amount BETWEEN 200.00 AND 1000.00;

-- Query 1.4: Pattern Matching (LIKE with % and _) Operator
-- Find customers whose city begins with 'New' or phone has specific prefix
SELECT 
    customer_id,
    first_name || ' ' || last_name AS full_name,
    city,
    phone_number,
    email
FROM customers
WHERE city LIKE 'New%'
   OR email LIKE '%.org'
   OR email LIKE '%@email.com';

-- Query 1.5: Nullity Operators (IS NULL and IS NOT NULL)
-- Distinguish direct ATM transactions from inter-account digital transfers
SELECT 
    transaction_id,
    transaction_type,
    amount,
    atm_id,
    dest_account_id
FROM transactions
WHERE dest_account_id IS NOT NULL; -- Inter-account transfers only

-- ----------------------------------------------------------------------------
-- 2. Group Functions & Aggregations (COUNT, SUM, AVG, MIN, MAX)
-- ----------------------------------------------------------------------------

-- Query 2.1: Overall System-Wide Financial Statistics
SELECT 
    COUNT(*) AS total_transactions_logged,
    COUNT(DISTINCT account_id) AS distinct_participating_accounts,
    SUM(amount) AS total_money_flow_volume,
    ROUND(AVG(amount), 2) AS average_transaction_amount,
    MIN(amount) AS lowest_positive_transaction,
    MAX(amount) AS highest_single_transaction
FROM transactions
WHERE status = 'SUCCESS' AND amount > 0;

-- Query 2.2: Account Breakdown by Account Type (GROUP BY)
SELECT 
    account_type,
    COUNT(*) AS total_accounts,
    ROUND(SUM(balance), 2) AS total_deposits_held,
    ROUND(AVG(balance), 2) AS average_account_balance,
    MIN(balance) AS minimum_observed_balance,
    MAX(balance) AS maximum_observed_balance
FROM accounts
GROUP BY account_type;

-- Query 2.3: Transaction Volume & Sum by Transaction Type (GROUP BY)
SELECT 
    transaction_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_volume,
    ROUND(AVG(amount), 2) AS average_volume
FROM transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;

-- Query 2.4: ATM Network Cash Utilization & Status Summary (GROUP BY)
SELECT 
    status,
    COUNT(*) AS terminal_count,
    ROUND(SUM(current_cash_level), 2) AS total_cash_available,
    ROUND(AVG(current_cash_level), 2) AS average_cash_per_atm
FROM atm_machines
GROUP BY status;

-- ----------------------------------------------------------------------------
-- 3. Advanced Grouping with HAVING Filter
-- ----------------------------------------------------------------------------

-- Query 3.1: High-Volume Accounts Filtered via HAVING
-- Lists accounts that have initiated more than 1 transaction and moved > $500 total
SELECT 
    account_id,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_transacted_amount,
    ROUND(AVG(amount), 2) AS average_transacted_amount
FROM transactions
WHERE status = 'SUCCESS'
GROUP BY account_id
HAVING COUNT(transaction_id) >= 2 
   AND SUM(amount) > 500.00
ORDER BY total_transacted_amount DESC;

-- Query 3.2: ATM Locations with Cash Turnover exceeding $500
SELECT 
    atm_id,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_dispensed_or_received
FROM transactions
WHERE atm_id IS NOT NULL 
  AND status = 'SUCCESS'
GROUP BY atm_id
HAVING SUM(amount) >= 500.00
ORDER BY total_dispensed_or_received DESC;

