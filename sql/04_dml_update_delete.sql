-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 04: DML Operations - UPDATE & DELETE
-- ============================================================================
-- Demonstrates data manipulation operations adhering to business rules,
-- data integrity constraints, and ledger protection.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. UPDATE Operations
-- ----------------------------------------------------------------------------

-- Operation 1.1: Deposit Simulation - Incrementing Account Balance
-- Scenario: Customer 1 deposits ₹500.00 into Checking Account (account_id = 101).
UPDATE accounts
SET balance = balance + 500.00
WHERE account_id = 101;

-- Operation 1.2: Withdrawal Simulation - Decrementing Account Balance
-- Scenario: Customer 1 withdraws ₹200.00, verified against check constraint.
UPDATE accounts
SET balance = balance - 200.00
WHERE account_id = 101 AND balance >= 200.00;

-- Operation 1.3: Card Security Management - Blocking a Card after failed attempts
-- Scenario: Security policy blocks card 510 due to 3 failed PIN entries.
UPDATE cards
SET status = 'BLOCKED',
    failed_pin_attempts = 3
WHERE card_id = 510;

-- Operation 1.4: Resetting Security Thresholds upon successful branch re-authentication
-- Scenario: Customer re-authenticates in person at branch; reset failed attempts.
UPDATE cards
SET status = 'ACTIVE',
    failed_pin_attempts = 0
WHERE card_id = 510;

-- Operation 1.5: Customer Information Modification
-- Scenario: Customer 2 moves to a new residence and updates contact information.
UPDATE customers
SET street_address = '789 Marine Drive, Nariman Point',
    city = 'Mumbai',
    phone_number = '98201-99999'
WHERE customer_id = 2;

-- Operation 1.6: ATM Cash Replenishment
-- Scenario: Armored carrier services ATM-PUN-01 (atm_id = 7) and replenishes cash.
UPDATE atm_machines
SET current_cash_level = 40000.00,
    status = 'ONLINE',
    last_serviced_date = CURRENT_DATE
WHERE atm_id = 7;

-- Operation 1.7: Conditional Batch Update using CASE
-- Scenario: Apply interest or tier adjustments based on account balance thresholds.
UPDATE accounts
SET balance = CASE 
    WHEN account_type = 'SAVINGS' AND balance >= 20000.00 THEN balance * 1.02 -- 2% interest bonus
    WHEN account_type = 'SAVINGS' AND balance < 20000.00  THEN balance * 1.01 -- 1% standard interest
    ELSE balance
END
WHERE account_type = 'SAVINGS';

-- ----------------------------------------------------------------------------
-- 2. DELETE Operations & Referential Integrity Preservation
-- ----------------------------------------------------------------------------

-- Create a temporary test customer and unlinked account to demonstrate clean deletion
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, date_of_birth, street_address, city, state, postal_code, kyc_status)
VALUES (999, 'Test', 'Kumar', 'test.kumar@email.com', '98999-99999', '1990-01-01', '000 MG Road', 'Mumbai', 'MH', '400001', 'PENDING');

INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance, minimum_balance)
VALUES (999, 999, 'ACC-VOID-999', 'CHECKING', 0.00, 0.00);

-- Operation 2.1: Safe Hard DELETE of an Unreferenced Child Record
-- Scenario: Customer closes newly opened unlinked account with zero balance.
DELETE FROM accounts
WHERE account_id = 999 AND balance = 0.00;

-- Operation 2.2: Hard DELETE of Unreferenced Parent Record
-- Scenario: Ghost customer application cancelled before any financial transactions occurred.
DELETE FROM customers
WHERE customer_id = 999;

-- ----------------------------------------------------------------------------
-- 2.3: Referential Integrity Violation Demonstration (Educational Case)
-- The following statement attempts to delete a Customer who owns active accounts:
--
-- DELETE FROM customers WHERE customer_id = 1;
--
-- RESULT: In a standard RDBMS enforcing Foreign Keys (ON DELETE RESTRICT),
-- this operation FAILS with:
--   "FOREIGN KEY constraint failed / integrity error: cannot delete parent key"
-- This guarantees financial audit records and accounts are NEVER orphaned!
-- ----------------------------------------------------------------------------

-- Operation 2.4: Industry Standard "Soft Delete" Pattern
-- In real-world financial architectures, financial ledger rows are NEVER deleted.
-- Instead, an account closure is modeled via status update:
UPDATE accounts
SET status = 'CLOSED'
WHERE account_id = 109;

