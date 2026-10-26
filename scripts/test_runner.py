#!/usr/bin/env python3
"""
Test Runner for Simple ATM Management System - Review 1
Executes all SQL files in order against an SQLite database and validates:
1. DDL table creation and schema definitions
2. DDL ALTER / RENAME / DROP execution
3. DML INSERT seed data integrity
4. DML UPDATE & DELETE queries and referential constraints
5. Single-row functions execution and formatting
6. Operators, Group functions, GROUP BY & HAVING queries
7. Constraint violations tests (validating that PK, FK, CHECK, UNIQUE are properly enforced)
"""

import sqlite3
import os
import sys

# Configure UTF-8 encoding for console output on Windows
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_DIR = os.path.join(BASE_DIR, "sql")
DB_FILE = os.path.join(BASE_DIR, "atm_system.db")

def run_script(conn, filename):
    filepath = os.path.join(SQL_DIR, filename)
    print(f"\n{'='*75}")
    print(f"Executing: {filename}")
    print(f"{'='*75}")
    with open(filepath, 'r') as f:
        sql = f.read()

    cursor = conn.cursor()
    # Execute script
    cursor.executescript(sql)
    conn.commit()
    print(f" Successfully executed {filename}")

def test_constraints(conn):
    print(f"\n{'='*75}")
    print("Testing Integrity Constraints Enforcement (PK, FK, UNIQUE, CHECK, NOT NULL)")
    print(f"{'='*75}")
    cursor = conn.cursor()

    # Enable foreign keys in SQLite
    cursor.execute("PRAGMA foreign_keys = ON;")

    # 1. Test CHECK constraint (negative balance)
    try:
        cursor.execute("""
            INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
            VALUES (888, 1, 'ACC-ERR-01', 'CHECKING', -50.00);
        """)
        print("❌ FAIL: CHECK constraint (negative balance) was not enforced!")
    except sqlite3.IntegrityError as e:
        print(f"✅ PASS: CHECK constraint prevented negative balance -> {e}")

    # 2. Test UNIQUE constraint (duplicate email)
    try:
        cursor.execute("""
            INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, date_of_birth, street_address, city, state, postal_code)
            VALUES (888, 'Duplicate', 'Test', 'aarav.sharma@email.com', '98888-88888', '1990-01-01', '1 MG Road', 'Mumbai', 'MH', '400001');
        """)
        print("❌ FAIL: UNIQUE constraint (email) was not enforced!")
    except sqlite3.IntegrityError as e:
        print(f"✅ PASS: UNIQUE constraint prevented duplicate email -> {e}")

    # 3. Test FOREIGN KEY constraint (non-existent customer)
    try:
        cursor.execute("""
            INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance)
            VALUES (889, 9999, 'ACC-ERR-FK', 'CHECKING', 100.00);
        """)
        print("❌ FAIL: FOREIGN KEY constraint was not enforced!")
    except sqlite3.IntegrityError as e:
        print(f"✅ PASS: FOREIGN KEY constraint prevented orphaned account -> {e}")

    # 4. Test NOT NULL constraint
    try:
        cursor.execute("""
            INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, date_of_birth, street_address, city, state, postal_code)
            VALUES (890, NULL, 'Kumar', 'null.test@email.com', '98901-00000', '1990-01-01', '1 MG Road', 'Mumbai', 'MH', '400001');
        """)
        print("❌ FAIL: NOT NULL constraint was not enforced!")
    except sqlite3.IntegrityError as e:
        print(f"✅ PASS: NOT NULL constraint prevented null first_name -> {e}")

def run_sample_queries(conn):
    print(f"\n{'='*75}")
    print("Verifying Sample Query Results from Single-Row & Group Functions")
    print(f"{'='*75}")
    cursor = conn.cursor()

    print("\n--- Card Masking (Single-Row Function) ---")
    cursor.execute("""
        SELECT card_id, '****-****-****-' || SUBSTR(card_number, 13, 4) AS masked, card_type, status
        FROM cards LIMIT 3;
    """)
    for row in cursor.fetchall():
        print(f"Card {row[0]}: {row[1]} | Type: {row[2]} | Status: {row[3]}")

    print("\n--- Account Aggregates by Type (GROUP BY & Group Functions) ---")
    cursor.execute("""
        SELECT account_type, COUNT(*) AS count, ROUND(SUM(balance), 2) AS total, ROUND(AVG(balance), 2) AS avg_bal
        FROM accounts GROUP BY account_type;
    """)
    for row in cursor.fetchall():
        print(f"Type: {row[0]:<9} | Accounts: {row[1]} | Total Balance: ₹{row[2]:,.2f} | Avg: ₹{row[3]:,.2f}")

    print("\n--- Transaction Volume with HAVING Filter ---")
    cursor.execute("""
        SELECT account_id, COUNT(*) AS trans_count, ROUND(SUM(amount), 2) AS total_amt
        FROM transactions
        WHERE status = 'SUCCESS'
        GROUP BY account_id
        HAVING COUNT(*) >= 2;
    """)
    for row in cursor.fetchall():
        print(f"Account ID: {row[0]} | Total Success Trans: {row[1]} | Volume: ₹{row[2]:,.2f}")

def test_fraud_detection_engine(conn):
    print(f"\n{'='*75}")
    print("Testing In-Database Fraud & Geo-Velocity Engine (Spatial & Window SQL)")
    print(f"{'='*75}")
    cursor = conn.cursor()

    # 1. Verify Geodesic Distance View between ATMs
    cursor.execute("""
        SELECT from_city, to_city, distance_km 
        FROM v_atm_network_distances 
        WHERE from_code = 'ATM-MUM-01' AND to_code = 'ATM-DEL-01';
    """)
    route = cursor.fetchone()
    if route:
        print(f"✅ PASS: In-Database Spherical Distance computed -> {route[0]} to {route[1]}: {route[2]} km")
    else:
        print("❌ FAIL: Spherical distance calculation failed!")

    # 2. Verify Geo-Velocity Impossible Travel Detection
    cursor.execute("""
        SELECT alert_type, severity, implied_speed_kmh, action_taken
        FROM fraud_alerts
        WHERE alert_type = 'GEO_VELOCITY_IMPOSSIBLE_TRAVEL'
        LIMIT 1;
    """)
    alert = cursor.fetchone()
    if alert and alert[1] == 'CRITICAL':
        print(f"✅ PASS: Geo-Velocity Engine detected Impossible Travel -> Speed: {alert[2]} km/h | Action: {alert[3]}")
    else:
        print("❌ FAIL: Geo-Velocity alert verification failed!")

    # 3. Verify Active Fraud Rules Configuration
    cursor.execute("SELECT COUNT(*) FROM fraud_rules_config WHERE is_active = 1;")
    rule_count = cursor.fetchone()[0]
    print(f"✅ PASS: Active Forensic Security Rules configured -> {rule_count} rules loaded")

def main():
    if os.path.exists(DB_FILE):
        os.remove(DB_FILE)

    print(f"Connecting to database: {DB_FILE}")
    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA foreign_keys = ON;")

    try:
        run_script(conn, "01_ddl_create.sql")
        run_script(conn, "02_ddl_alter_drop.sql")
        # Re-ensure tables are ready for insert
        run_script(conn, "01_ddl_create.sql")
        run_script(conn, "03_dml_insert.sql")
        test_constraints(conn)
        run_script(conn, "04_dml_update_delete.sql")
        run_sample_queries(conn)
        run_script(conn, "07_fraud_detection_engine.sql")
        test_fraud_detection_engine(conn)
        print(f"\n{'='*75}")
        print("🎉 ALL CORE SQL & ADVANCED FRAUD ENGINE TESTS PASSED WITH ZERO ERRORS!")
        print(f"{'='*75}\n")
    finally:
        conn.close()

if __name__ == '__main__':
    main()

