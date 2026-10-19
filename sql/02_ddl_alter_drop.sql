-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 02: DDL Implementation - ALTER, RENAME & DROP Operations
-- ============================================================================
-- This script illustrates Data Definition Language (DDL) modifications that
-- evolve the schema over time without data corruption.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ALTER TABLE: ADD COLUMN
-- Scenario: Compliance mandates logging customer middle name and nationality.
-- ----------------------------------------------------------------------------
ALTER TABLE customers ADD COLUMN middle_name VARCHAR(50);
ALTER TABLE customers ADD COLUMN nationality VARCHAR(50) DEFAULT 'Indian';

-- Add an audit column to transactions to flag high-value or suspicious actions
ALTER TABLE transactions ADD COLUMN is_flagged INTEGER DEFAULT 0;

-- ----------------------------------------------------------------------------
-- 2. ALTER TABLE: RENAME COLUMN
-- Scenario: Standardizing naming convention for clarity.
-- ----------------------------------------------------------------------------
ALTER TABLE customers RENAME COLUMN middle_name TO second_name;

-- ----------------------------------------------------------------------------
-- 3. ALTER TABLE: DROP COLUMN
-- Scenario: Removing redundant or decommissioned attributes.
-- ----------------------------------------------------------------------------
ALTER TABLE customers DROP COLUMN second_name;
ALTER TABLE customers DROP COLUMN nationality;
ALTER TABLE transactions DROP COLUMN is_flagged;

-- ----------------------------------------------------------------------------
-- 4. ALTER TABLE: ADD / DROP CONSTRAINTS (Standard SQL / PostgreSQL / Oracle / MySQL 8.0+)
-- Scenario: Adding and modifying business integrity rules post-creation.
-- (Note: In pure SQLite, ALTER TABLE ADD CONSTRAINT is syntactically handled
-- via table recreation, whereas in MySQL / Oracle / PostgreSQL the following
-- standard DDL statements are executed directly):
-- ----------------------------------------------------------------------------

-- [PostgreSQL / Oracle / MySQL Syntax]:
-- Add an additional check constraint to ensure cash capacity is at least ₹1,000
-- ALTER TABLE atm_machines 
--     ADD CONSTRAINT chk_min_capacity CHECK (cash_capacity >= 1000.00);

-- Drop a constraint when business policy evolves
-- ALTER TABLE atm_machines 
--     DROP CONSTRAINT chk_min_capacity;

-- Add a new unique index/constraint for customer secondary contact
-- ALTER TABLE customers 
--     ADD CONSTRAINT uq_customer_email UNIQUE (email);

-- ----------------------------------------------------------------------------
-- 5. DDL DEMONSTRATION: TEMPORARY AUDIT LOG TABLE (CREATE -> ALTER -> DROP)
-- Creates an auxiliary table, applies modifications, and drops it cleanly.
-- ----------------------------------------------------------------------------
CREATE TABLE atm_maintenance_logs (
    log_id          INTEGER PRIMARY KEY,
    atm_id          INTEGER NOT NULL,
    engineer_name   VARCHAR(100) NOT NULL,
    notes           VARCHAR(255),
    maintenance_date DATE DEFAULT CURRENT_DATE
);

-- Modify maintenance log table structure
ALTER TABLE atm_maintenance_logs ADD COLUMN cost DECIMAL(10, 2) DEFAULT 0.00;
ALTER TABLE atm_maintenance_logs RENAME COLUMN notes TO service_notes;

-- Drop table cleanly to demonstrate schema cleanup
DROP TABLE IF EXISTS atm_maintenance_logs;

-- ============================================================================
-- 6. DROP TABLE: Best Practices & Referential Integrity Considerations
-- ============================================================================
-- When dropping relational tables with foreign keys:
-- Child tables (referencing tables) must be dropped before parent tables,
-- OR DROP TABLE ... CASCADE must be utilized.
--
-- Safe Execution Order:
--   1. DROP TABLE IF EXISTS transactions; (References accounts, atm_machines)
--   2. DROP TABLE IF EXISTS cards;        (References accounts)
--   3. DROP TABLE IF EXISTS accounts;     (References customers)
--   4. DROP TABLE IF EXISTS atm_machines; (Standalone / Referenced by transactions)
--   5. DROP TABLE IF EXISTS customers;    (Referenced by accounts)
-- ============================================================================

