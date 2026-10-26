-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 01: DDL Implementation - Schema Creation & Constraints
-- DBMS Case Study: Core Banking & ATM Simulation
-- ============================================================================
-- Constraints Demonstrated:
--   1. PRIMARY KEY (Entity Integrity)
--   2. FOREIGN KEY (Referential Integrity with ON DELETE / ON UPDATE actions)
--   3. UNIQUE (Key uniqueness across alternate identifiers)
--   4. NOT NULL (Domain completeness)
--   5. CHECK (Business rule enforcement & value domain validation)
--   6. DEFAULT (Automatic baseline state assignment)
-- ============================================================================

-- Drop existing tables in reverse dependency order to avoid FK constraint errors
DROP TABLE IF EXISTS fraud_alerts;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS cards;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS atm_machines;
DROP TABLE IF EXISTS customers;

-- ----------------------------------------------------------------------------
-- Table 1: CUSTOMERS
-- Represents bank patrons who hold banking accounts.
-- ----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id         INTEGER PRIMARY KEY,
    first_name          VARCHAR(50)  NOT NULL,
    last_name           VARCHAR(50)  NOT NULL,
    email               VARCHAR(100) NOT NULL UNIQUE,
    phone_number        VARCHAR(15)  NOT NULL UNIQUE,
    date_of_birth       DATE         NOT NULL,
    street_address      VARCHAR(150) NOT NULL,
    city                VARCHAR(50)  NOT NULL,
    state               VARCHAR(50)  NOT NULL,
    postal_code         VARCHAR(10)  NOT NULL,
    kyc_status          VARCHAR(20)  NOT NULL DEFAULT 'VERIFIED'
                                     CHECK (kyc_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    created_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- Table 2: ACCOUNTS
-- Represents checking and savings accounts owned by customers.
-- Categorized by account_type with balance and minimum balance constraints.
-- ----------------------------------------------------------------------------
CREATE TABLE accounts (
    account_id          INTEGER PRIMARY KEY,
    customer_id         INTEGER        NOT NULL,
    account_number      VARCHAR(20)    NOT NULL UNIQUE,
    account_type        VARCHAR(15)    NOT NULL
                                       CHECK (account_type IN ('CHECKING', 'SAVINGS')),
    balance             DECIMAL(15, 2) NOT NULL DEFAULT 0.00
                                       CHECK (balance >= 0.00),
    minimum_balance     DECIMAL(15, 2) NOT NULL DEFAULT 50.00
                                       CHECK (minimum_balance >= 0.00),
    currency            VARCHAR(3)     NOT NULL DEFAULT 'INR',
    status              VARCHAR(15)    NOT NULL DEFAULT 'ACTIVE'
                                       CHECK (status IN ('ACTIVE', 'DORMANT', 'FROZEN', 'CLOSED')),
    opened_date         DATE           NOT NULL DEFAULT CURRENT_DATE,
    created_at          TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table 3: CARDS
-- Represents ATM / Debit cards issued for accessing specific accounts.
-- Includes PIN authentication data and security thresholds.
-- ----------------------------------------------------------------------------
CREATE TABLE cards (
    card_id                 INTEGER PRIMARY KEY,
    account_id              INTEGER        NOT NULL,
    card_number             VARCHAR(16)    NOT NULL UNIQUE
                                           CHECK (LENGTH(card_number) = 16),
    card_type               VARCHAR(10)    NOT NULL DEFAULT 'DEBIT'
                                           CHECK (card_type IN ('DEBIT', 'CREDIT')),
    pin_hash                VARCHAR(64)    NOT NULL,
    cvv                     VARCHAR(3)     NOT NULL
                                           CHECK (LENGTH(cvv) = 3),
    expiry_date             DATE           NOT NULL,
    daily_withdrawal_limit  DECIMAL(10, 2) NOT NULL DEFAULT 1000.00
                                           CHECK (daily_withdrawal_limit > 0.00),
    status                  VARCHAR(15)    NOT NULL DEFAULT 'ACTIVE'
                                           CHECK (status IN ('ACTIVE', 'BLOCKED', 'EXPIRED', 'INACTIVE')),
    failed_pin_attempts     INTEGER        NOT NULL DEFAULT 0
                                           CHECK (failed_pin_attempts >= 0 AND failed_pin_attempts <= 3),
    issued_date             DATE           NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_cards_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table 4: ATM_MACHINES
-- Represents physical Automated Teller Machine terminals in the network.
-- ----------------------------------------------------------------------------
CREATE TABLE atm_machines (
    atm_id              INTEGER PRIMARY KEY,
    terminal_code       VARCHAR(20)    NOT NULL UNIQUE,
    branch_name         VARCHAR(100)   NOT NULL,
    location_address    VARCHAR(150)   NOT NULL,
    city                VARCHAR(50)    NOT NULL,
    latitude            DECIMAL(9, 6)  NOT NULL DEFAULT 0.0,
    longitude           DECIMAL(9, 6)  NOT NULL DEFAULT 0.0,
    cash_capacity       DECIMAL(15, 2) NOT NULL DEFAULT 50000.00
                                       CHECK (cash_capacity >= 0.00),
    current_cash_level  DECIMAL(15, 2) NOT NULL DEFAULT 50000.00
                                       CHECK (current_cash_level >= 0.00 AND current_cash_level <= cash_capacity),
    status              VARCHAR(15)    NOT NULL DEFAULT 'ONLINE'
                                       CHECK (status IN ('ONLINE', 'OFFLINE', 'MAINTENANCE', 'OUT_OF_CASH')),
    last_serviced_date  DATE
);

-- ----------------------------------------------------------------------------
-- Table 5: TRANSACTIONS
-- Comprehensive ledger tracking financial activities (deposits, withdrawals,
-- transfers, balance inquiries) adhering to ACID transaction expectations.
-- ----------------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id          INTEGER PRIMARY KEY,
    account_id              INTEGER        NOT NULL,
    dest_account_id         INTEGER,
    atm_id                  INTEGER,
    transaction_type        VARCHAR(20)    NOT NULL
                                           CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'BALANCE_INQUIRY')),
    amount                  DECIMAL(15, 2) NOT NULL DEFAULT 0.00
                                           CHECK (amount >= 0.00),
    balance_after           DECIMAL(15, 2) NOT NULL
                                           CHECK (balance_after >= 0.00),
    status                  VARCHAR(15)    NOT NULL DEFAULT 'SUCCESS'
                                           CHECK (status IN ('SUCCESS', 'PENDING', 'FAILED', 'REVERSED')),
    description             VARCHAR(255),
    transaction_timestamp   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_trans_source_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_trans_dest_account
        FOREIGN KEY (dest_account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_trans_atm
        FOREIGN KEY (atm_id)
        REFERENCES atm_machines(atm_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- ----------------------------------------------------------------------------
-- Table 6: FRAUD_ALERTS
-- Real-time security, geo-velocity, and impossible travel anomaly ledger.
-- ----------------------------------------------------------------------------
CREATE TABLE fraud_alerts (
    alert_id             INTEGER PRIMARY KEY,
    transaction_id       INTEGER,
    card_id              INTEGER        NOT NULL,
    account_id           INTEGER        NOT NULL,
    alert_type           VARCHAR(50)    NOT NULL
                                        CHECK (alert_type IN ('GEO_VELOCITY_IMPOSSIBLE_TRAVEL', 'RAPID_FREQUENCY_BURST', 'HIGH_VALUE_OUTLIER', 'OFF_HOURS_HIGH_VALUE', 'PIN_BRUTE_FORCE')),
    severity             VARCHAR(15)    NOT NULL
                                        CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    risk_score           INTEGER        NOT NULL
                                        CHECK (risk_score >= 0 AND risk_score <= 100),
    prev_atm_id          INTEGER,
    current_atm_id       INTEGER,
    distance_km          DECIMAL(8, 2),
    time_delta_minutes   DECIMAL(8, 2),
    implied_speed_kmh    DECIMAL(8, 2),
    action_taken         VARCHAR(50)    NOT NULL
                                        CHECK (action_taken IN ('FLAGGED_FOR_REVIEW', 'TRANSACTION_BLOCKED', 'CARD_AUTO_LOCKED')),
    details              TEXT,
    alert_timestamp      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_fraud_trans
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_fraud_card
        FOREIGN KEY (card_id)
        REFERENCES cards(card_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_fraud_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_fraud_prev_atm
        FOREIGN KEY (prev_atm_id)
        REFERENCES atm_machines(atm_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_fraud_curr_atm
        FOREIGN KEY (current_atm_id)
        REFERENCES atm_machines(atm_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

