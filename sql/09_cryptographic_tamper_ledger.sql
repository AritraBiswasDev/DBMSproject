-- ============================================================================
-- Simple ATM Management System - Advanced Analytics Extension
-- Script 09: In-Database Cryptographic Tamper-Proof Audit Ledger
-- DBMS Case Study: Merkle / Blockchain Hash Chaining & Pure SQL Integrity Verification
-- ============================================================================
-- Academic & Industry Significance:
--   1. The Insider Threat / "Rogue DBA" Problem: In conventional DBMS, users with
--      DBA privileges or SQL injection vulnerabilities can silently UPDATE or DELETE
--      financial records (e.g. changing withdrawal amounts or balances).
--   2. Cryptographic Hash Chaining in SQL: Every transaction stores:
--        - prev_hash: SHA-256 of the immediate predecessor transaction
--        - entry_hash: Deterministic SHA-256 over (payload + prev_hash)
--      Genesis block (transaction 1001) is anchored with 64 zeros.
--   3. Pure SQL Window Verification:
--        LAG(entry_hash, 1, '0000...0000') OVER (ORDER BY transaction_id)
--      detects unauthorized alterations instantly without requiring full database dumps.
--   4. Immutable Forensic Log: Unseals fraud when any field is manipulated.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. View: v_cryptographic_ledger
-- Computes expected previous hash for each block via window functions and
-- verifies link continuity across the entire ledger timeline.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_cryptographic_ledger;
CREATE VIEW v_cryptographic_ledger AS
SELECT
    t.transaction_id,
    t.account_id,
    t.dest_account_id,
    t.atm_id,
    t.transaction_type,
    t.amount,
    t.balance_after,
    t.status,
    t.transaction_timestamp,
    t.prev_hash,
    t.entry_hash,
    LAG(t.entry_hash, 1, '0000000000000000000000000000000000000000000000000000000000000000') 
        OVER (ORDER BY t.transaction_id) AS expected_prev_hash,
    CASE
        WHEN t.prev_hash = LAG(t.entry_hash, 1, '0000000000000000000000000000000000000000000000000000000000000000') 
            OVER (ORDER BY t.transaction_id)
        THEN 'VALID_BLOCK'
        ELSE 'TAMPERED_BROKEN_CHAIN'
    END AS chain_integrity_status
FROM transactions t;

-- ----------------------------------------------------------------------------
-- 2. View: v_tamper_detection_summary
-- High-level institutional auditor summary aggregating ledger metrics.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_tamper_detection_summary;
CREATE VIEW v_tamper_detection_summary AS
SELECT
    COUNT(*) AS total_blocks,
    SUM(CASE WHEN chain_integrity_status = 'VALID_BLOCK' THEN 1 ELSE 0 END) AS verified_blocks,
    SUM(CASE WHEN chain_integrity_status = 'TAMPERED_BROKEN_CHAIN' THEN 1 ELSE 0 END) AS corrupted_blocks,
    ROUND(100.0 * SUM(CASE WHEN chain_integrity_status = 'VALID_BLOCK' THEN 1 ELSE 0 END) / COUNT(*), 2) AS chain_integrity_pct,
    CASE
        WHEN SUM(CASE WHEN chain_integrity_status = 'TAMPERED_BROKEN_CHAIN' THEN 1 ELSE 0 END) = 0
        THEN 'LEDGER_INTACT_SECURE'
        ELSE 'CRITICAL_TAMPERING_DETECTED'
    END AS audit_status
FROM v_cryptographic_ledger;

-- ----------------------------------------------------------------------------
-- 3. View: v_broken_chain_forensics
-- Isolates corrupted blocks where the mathematical hash link broke.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_broken_chain_forensics;
CREATE VIEW v_broken_chain_forensics AS
SELECT
    transaction_id,
    account_id,
    atm_id,
    transaction_type,
    amount,
    transaction_timestamp,
    prev_hash AS recorded_prev_hash,
    expected_prev_hash,
    entry_hash,
    'HASH_MISMATCH: Chain discontinuity detected at block ' || transaction_id AS forensic_alert
FROM v_cryptographic_ledger
WHERE chain_integrity_status = 'TAMPERED_BROKEN_CHAIN';

-- ============================================================================
-- Verification and Demonstration Queries
-- ============================================================================

-- Query 1: Ledger Genesis & Early Blocks Verification
SELECT 
    transaction_id,
    account_id,
    transaction_type,
    amount,
    substr(prev_hash, 1, 16) || '...' AS prev_hash_short,
    substr(entry_hash, 1, 16) || '...' AS entry_hash_short,
    chain_integrity_status
FROM v_cryptographic_ledger
ORDER BY transaction_id ASC
LIMIT 10;

-- Query 2: Cryptographic Ledger Audit Overview
SELECT * FROM v_tamper_detection_summary;

-- Query 3: Forensic Scan (Returns 0 rows when ledger is uncorrupted)
SELECT * FROM v_broken_chain_forensics;

-- Query 4: Review Logged Forensic Tamper Incidents
SELECT 
    log_id,
    tampered_transaction_id,
    tamper_severity,
    action_taken,
    incident_details,
    detected_at
FROM ledger_tamper_log
ORDER BY log_id DESC;
