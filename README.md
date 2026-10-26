# Simple ATM Management System
## Relational Database Architecture & Core Banking Operations

![DBMS](https://img.shields.io/badge/Course-DBMS_Case_Study-blue.svg)
![Status](https://img.shields.io/badge/Review_1-100%25_Complete-brightgreen.svg)
![Engine](https://img.shields.io/badge/SQL-ANSI_Standard_|_SQLite_|_MySQL_|_PostgreSQL-orange.svg)

---

## 📌 Project Overview
The **Simple ATM Management System** simulates core banking operations using a fully normalized relational database architecture. The system models customer relationships, categorized checking and savings accounts, card authentication credentials, automated teller machine terminals, and an immutable transaction ledger.

This repository currently implements **Review 1 (10 Marks)** of the 30-Mark DBMS Case Study rubric.

---

## 📋 Review 1 Rubric Compliance Matrix (10 Marks)

| Rubric Component | Deliverable Location | Status & Description |
|---|---|:---:|
| **1. Problem & Domain Analysis** | [`docs/REVIEW_1_CASE_STUDY_REPORT.md`](file:///Users/aritrabiswas/Desktop/DBMSproject/docs/REVIEW_1_CASE_STUDY_REPORT.md#1-problem--domain-analysis) | ✅ Complete: Banking domain, race conditions, ACID foundations. |
| **2. Requirements, Users & Business Rules** | [`docs/REVIEW_1_CASE_STUDY_REPORT.md`](file:///Users/aritrabiswas/Desktop/DBMSproject/docs/REVIEW_1_CASE_STUDY_REPORT.md#2-requirements-users--business-rules) | ✅ Complete: 4 user personas, FRs, NFRs, and 10 formal business rules. |
| **3. Entities, Attributes, Keys & ER/EER** | [`docs/REVIEW_1_CASE_STUDY_REPORT.md`](file:///Users/aritrabiswas/Desktop/DBMSproject/docs/REVIEW_1_CASE_STUDY_REPORT.md#3-entities-attributes-keys--er-eer-modeling) | ✅ Complete: 5 entities, cardinalities, Mermaid ER & EER diagrams. |
| **4. DDL Implementation (CREATE, ALTER, DROP)** | [`sql/01_ddl_create.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/01_ddl_create.sql) & [`sql/02_ddl_alter_drop.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/02_ddl_alter_drop.sql) | ✅ Complete: Executable table definitions, ALTER, RENAME, safe DROP. |
| **5. Constraints (PK, FK, UNIQUE, NOT NULL, CHECK, DEFAULT)** | [`sql/01_ddl_create.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/01_ddl_create.sql) & [`scripts/test_runner.py`](file:///Users/aritrabiswas/Desktop/DBMSproject/scripts/test_runner.py) | ✅ Complete: All 6 constraints implemented and verified against violations. |
| **6. DML Operations (INSERT, UPDATE, DELETE)** | [`sql/03_dml_insert.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/03_dml_insert.sql) & [`sql/04_dml_update_delete.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/04_dml_update_delete.sql) | ✅ Complete: Seed data, realistic updates, safe delete & soft-delete pattern. |
| **7. Single-Row Functions** | [`sql/05_single_row_functions.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/05_single_row_functions.sql) | ✅ Complete: String (masking), Math, Date/Time, and Conditional (`CASE`/`COALESCE`). |
| **8. Operators & Group Functions** | [`sql/06_operators_and_group_functions.sql`](file:///Users/aritrabiswas/Desktop/DBMSproject/sql/06_operators_and_group_functions.sql) | ✅ Complete: Arithmetic, Comparison, Logical, Pattern, `GROUP BY`, and `HAVING`. |
| **9. Presentation** | [`docs/REVIEW_1_PRESENTATION_GUIDE.md`](file:///Users/aritrabiswas/Desktop/DBMSproject/docs/REVIEW_1_PRESENTATION_GUIDE.md) | ✅ Complete: Slide structure, speaker script, demo guide, and 8+ Viva Q&A answers. |

---

## 🗂 Project Directory Layout

```text
DBMSproject/
├── README.md                              # Main project documentation & quickstart
├── app.py                                 # Interactive Web GUI server (Flask + SQLite + Fraud Engine)
├── atm_system.db                          # Normalized SQLite database file
├── docs/
│   ├── REVIEW_1_CASE_STUDY_REPORT.md      # Comprehensive academic report for Review 1
│   └── REVIEW_1_PRESENTATION_GUIDE.md     # Slide deck outline, speaker notes & viva defense Q&A
├── scripts/
│   ├── interactive_cli.py                 # Interactive Terminal CLI ATM Application with Fraud Radar
│   └── test_runner.py                     # Automated Python test runner (verifies 7 SQL scripts & fraud engine)
├── sql/
│   ├── 01_ddl_create.sql                  # Schema definition with 6 integrity constraints & fraud_alerts
│   ├── 02_ddl_alter_drop.sql              # Schema evolution (ALTER, RENAME, DROP operations)
│   ├── 03_dml_insert.sql                  # Realistic Indian seed dataset with ATM GPS coordinates
│   ├── 04_dml_update_delete.sql           # Balance updates, card locks, safe delete & soft deletes
│   ├── 05_single_row_functions.sql        # String (PCI-DSS masking), Math, Date, CASE, COALESCE
│   ├── 06_operators_and_group_functions.sql# Operators, COUNT, SUM, AVG, GROUP BY & HAVING
│   └── 07_fraud_detection_engine.sql      # Novel in-database Geo-Velocity & window function fraud engine
└── templates/
    └── index.html                         # ATM Simulator, Bank Admin & Fraud Radar Web UI
```

---

## 🛡️ Project Novelty: In-Database Real-Time Fraud & Geo-Velocity Radar

To exceed standard academic ATM implementations, this project introduces a **Real-Time In-Database Fraud & Geo-Velocity Detection Engine**. Rather than treating the relational database as a dumb store, advanced relational constructs, spherical mathematics, and temporal window functions execute directly inside the SQL engine.

### 1. Mathematical Architecture: Great-Circle Haversine Trigonometry
Every ATM terminal stores its exact latitude and longitude:
* **Nariman Point, Mumbai:** $18.9256^\circ\text{ N}, 72.8242^\circ\text{ E}$
* **Connaught Place, New Delhi:** $28.6315^\circ\text{ N}, 77.2167^\circ\text{ E}$
* **Distance:** $1,167.81\text{ km}$

The physical distance between any two consecutive card swipes is computed in pure SQL using spherical trigonometry:
$$d = 2R \cdot \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\phi}{2}\right) + \cos\phi_1\cos\phi_2\sin^2\left(\frac{\Delta\lambda}{2}\right)}\right)$$
$$\text{Velocity } (v) = \frac{\Delta d\text{ (km)}}{\Delta t\text{ (hours)}}$$

* **Rule BR-08 (Impossible Travel Threshold):** If calculated velocity exceeds **$500\text{ km/h}$**, physical human transit between terminals is impossible without supersonic aviation. The database identifies card cloning, triggers an automated ACID rollback, logs a `CRITICAL` breach in `fraud_alerts`, and auto-locks the card (`cards.status = 'BLOCKED'`).

### 2. Temporal Window Functions (`LAG()` Partitioning)
Instead of expensive iterative self-joins, the database inspects transaction sequences using SQL analytic window functions:
```sql
SELECT
    transaction_id,
    card_id,
    atm_id,
    transaction_timestamp,
    LAG(atm_id, 1) OVER (
        PARTITION BY card_id
        ORDER BY transaction_timestamp
    ) AS prev_atm_id,
    LAG(transaction_timestamp, 1) OVER (
        PARTITION BY card_id
        ORDER BY transaction_timestamp
    ) AS prev_timestamp
FROM transactions;
```

### 3. Rapid Frequency Burst & Outlier Analysis
* **Rule BR-09 (High-Frequency Swiping Anomaly):** Flags $\ge 3$ transaction attempts within any sliding $5\text{-minute}$ window across distinct terminals.
* **Rule BR-10 (Outlier Spending Spike):** Detects single withdrawal attempts exceeding $3.0\times$ the account's historical baseline.

---

## 🎮 Interactive Simulation (Web GUI & Terminal CLI)

### Option A: Interactive Web ATM GUI (Recommended for Presentations)
Launch the graphical browser-based ATM simulator, Bank Admin Portal, and Fraud Radar:

```bash
python app.py
```
* **URL:** Open [http://127.0.0.1:5000](http://127.0.0.1:5000) in your web browser.
* **Three Dedicated Views:**
  1. 🏧 **ATM Terminal**: Realistic enclosure, sound effects, card insertion, PIN authentication, cash withdrawal, deposit, transfer, mini-statement, and thermal receipt generation.
  2. 🏛️ **Bank Admin & Analytics**: Fleet monitor of all 8 Indian ATM terminals, cash replenishment, card unblocking, and aggregate financial metrics.
  3. 🛡️ **Fraud & Geo-Velocity Radar**:
     * **Threat Counters**: Total Alerts, Critical Breaches, Auto-Locked Cards, and Maximum Velocity Detected.
     * **Interactive Attack Simulation Sandbox**: 1-click execution of *Impossible Travel (Mumbai ➔ Delhi in 15 mins)*, *Rapid Frequency Burst (4 swipes in 2 mins)*, and *Outlier Spending Spike*.
     * **Live Security Audit Table**: Real-time forensic ledger of `fraud_alerts`.
     * **ATM Geolocation Mesh**: Terminal coordinates, live cash reserves, and city-level risk heat index.
  4. ⚡ **Live SQL Query Inspector**: Fixed footer showing the exact SQL queries executed in real-time.

---

### Option B: Interactive Terminal CLI
Run the interactive ATM application directly in your terminal console:

```bash
python scripts/interactive_cli.py
```
* Interactive menus, sample card picker, PIN authentication, cash withdrawals with real-time fraud evaluation, and option `[F]` for the **Fraud & Geo-Velocity Radar**.

---

## 🚀 Automated Verification Suite

To run the complete verification suite, execute the following from the root directory:

```bash
python scripts/test_runner.py
```

### Expected Output Summary:
* Executes all 7 SQL scripts in proper sequence (`01_ddl_create.sql` through `07_fraud_detection_engine.sql`).
* Runs **Integrity Constraint Tests** and proves that the database blocks:
  * ❌ Negative balances (`CHECK balance >= 0.00`)
  * ❌ Duplicate email addresses (`UNIQUE`)
  * ❌ Orphaned accounts (`FOREIGN KEY`)
  * ❌ Missing required names (`NOT NULL`)
* Executes single-row functions including PCI-DSS compliant card masking.
* Generates aggregate portfolio summaries by account type.
* Filters high-volume accounts using `HAVING`.
* **Fraud & Geo-Velocity Test Suite:**
  * ✅ Verifies Great-Circle Haversine distance accuracy between Mumbai and Delhi ($1,167.81\text{ km}$).
  * ✅ Verifies Impossible Travel velocity detection ($4,671.24\text{ km/h} > 500\text{ km/h}$).
  * ✅ Verifies automated soft-lockout of compromised cards.

---

## 🔄 Roadmap to Review 2 & Final Report
* **Review 2 (10 Marks):**
  * Advanced SQL: Nested & Correlated Subqueries, Complex Multi-table Joins.
  * Views: Customer statements, ATM cash level monitoring, and fraud movement forensics.
  * PL/SQL: Stored Procedures (atomic transfers), Functions, Cursors, and Triggers.
* **Project Report (10 Marks):**
  * Final consolidated academic report combining Review 1, Review 2, screenshots, normalization proofs, and conclusion.

