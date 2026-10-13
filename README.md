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
├── atm_system.db                          # Generated SQLite database file
├── docs/
│   ├── REVIEW_1_CASE_STUDY_REPORT.md      # Comprehensive academic report for Review 1
│   └── REVIEW_1_PRESENTATION_GUIDE.md     # Slide deck outline, speaker notes & viva defense Q&A
├── scripts/
│   └── test_runner.py                     # Automated Python script to test & verify all SQL operations
└── sql/
    ├── 01_ddl_create.sql                  # Schema definition with 6 integrity constraints
    ├── 02_ddl_alter_drop.sql              # Schema evolution (ALTER, RENAME, DROP operations)
    ├── 03_dml_insert.sql                  # Realistic seed dataset (10 customers, 12 accounts, etc.)
    ├── 04_dml_update_delete.sql           # Balance updates, card locks, safe delete & soft deletes
    ├── 05_single_row_functions.sql        # String (PCI-DSS masking), Math, Date, CASE, COALESCE
    └── 06_operators_and_group_functions.sql# Operators, COUNT, SUM, AVG, GROUP BY & HAVING
```

---

## 🚀 Quickstart & Verification

To run the automated verification suite, execute the following from the root directory:

```bash
python3 scripts/test_runner.py
```

### Expected Output Summary:
* Executes all 6 SQL scripts in proper sequence.
* Runs **Integrity Constraint Tests** and proves that the database blocks:
  * ❌ Negative balances (`CHECK balance >= 0.00`)
  * ❌ Duplicate email addresses (`UNIQUE`)
  * ❌ Orphaned accounts (`FOREIGN KEY`)
  * ❌ Missing required names (`NOT NULL`)
* Executes single-row functions including PCI-DSS compliant card masking.
* Generates aggregate portfolio summaries by account type.
* Filters high-volume accounts using `HAVING`.

---

## 🔄 Roadmap to Review 2 & Final Report
* **Review 2 (10 Marks):**
  * Advanced SQL: Nested & Correlated Subqueries, Complex Multi-table Joins.
  * Views: Customer statements and ATM cash level monitoring.
  * PL/SQL: Stored Procedures (atomic transfers), Functions, Cursors, and Triggers.
* **Project Report (10 Marks):**
  * Final consolidated academic report combining Review 1, Review 2, screenshots, normalization proofs, and conclusion.

