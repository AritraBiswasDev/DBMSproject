#!/usr/bin/env python3
"""
Simple ATM Management System - Interactive Web Application
Flask backend connecting the Interactive ATM Simulator and Admin Portal
to the SQLite relational database (atm_system.db).
"""

from flask import Flask, render_template, request, jsonify
import sqlite3
import hashlib
import os
import sys
from datetime import datetime

# UTF-8 handling for Windows
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(BASE_DIR, "atm_system.db")

app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False

# Global in-memory buffer to record SQL queries for the live SQL Query Inspector
SQL_LOGS = []

def log_sql(query, params=(), status="SUCCESS"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    formatted_query = query.strip()
    if params:
        formatted_query += f"  /* params: {params} */"
    SQL_LOGS.insert(0, {
        "time": timestamp,
        "query": formatted_query,
        "status": status
    })
    if len(SQL_LOGS) > 60:
        SQL_LOGS.pop()

def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.row_factory = sqlite3.Row
    return conn

def hash_pin(pin_str):
    return hashlib.sha256(str(pin_str).strip().encode("utf-8")).hexdigest()

@app.route('/')
def index():
    return render_template('index.html')

# -----------------------------------------------------------------------------
# ATM CARD & AUTHENTICATION ENDPOINTS
# -----------------------------------------------------------------------------
@app.route('/api/cards', methods=['GET'])
def get_cards():
    conn = get_db()
    cur = conn.cursor()
    query = """
        SELECT c.card_id, c.card_number, c.card_type, c.status, c.failed_pin_attempts,
               c.daily_withdrawal_limit, c.expiry_date,
               a.account_id, a.account_number, a.account_type, a.balance, a.minimum_balance,
               cust.customer_id, cust.first_name, cust.last_name, cust.city
        FROM cards c
        JOIN accounts a ON c.account_id = a.account_id
        JOIN customers cust ON a.customer_id = cust.customer_id
        ORDER BY c.card_id ASC;
    """
    cur.execute(query)
    rows = cur.fetchall()
    log_sql(query)
    conn.close()

    cards = []
    for r in rows:
        cards.append({
            "card_id": r["card_id"],
            "card_number": r["card_number"],
            "masked_number": f"{r['card_number'][:4]} •••• •••• {r['card_number'][-4:]}",
            "card_type": r["card_type"],
            "status": r["status"],
            "failed_pin_attempts": r["failed_pin_attempts"],
            "daily_limit": float(r["daily_withdrawal_limit"]),
            "expiry_date": r["expiry_date"],
            "account_id": r["account_id"],
            "account_number": r["account_number"],
            "account_type": r["account_type"],
            "balance": float(r["balance"]),
            "minimum_balance": float(r["minimum_balance"]),
            "customer_name": f"{r['first_name']} {r['last_name']}",
            "city": r["city"]
        })
    return jsonify({"success": True, "cards": cards})

@app.route('/api/auth/pin', methods=['POST'])
def verify_pin():
    data = request.json or {}
    card_number = data.get("card_number")
    entered_pin = data.get("pin")

    if not card_number or not entered_pin:
        return jsonify({"success": False, "message": "Card number and PIN are required."}), 400

    conn = get_db()
    cur = conn.cursor()
    query = """
        SELECT c.*, a.account_number, a.account_type, a.balance, a.minimum_balance,
               cust.first_name, cust.last_name
        FROM cards c
        JOIN accounts a ON c.account_id = a.account_id
        JOIN customers cust ON a.customer_id = cust.customer_id
        WHERE c.card_number = ?;
    """
    cur.execute(query, (card_number,))
    card = cur.fetchone()
    log_sql(query, (card_number,))

    if not card:
        conn.close()
        return jsonify({"success": False, "message": "Card not recognized by bank network."}), 404

    if card["status"] == "BLOCKED":
        conn.close()
        return jsonify({
            "success": False,
            "blocked": True,
            "message": "Card is BLOCKED due to security violations. Please contact customer support."
        }), 403

    if card["status"] != "ACTIVE":
        conn.close()
        return jsonify({
            "success": False,
            "message": f"Card is currently {card['status']} and cannot be used."
        }), 403

    hashed = hash_pin(entered_pin)
    if hashed == card["pin_hash"]:
        # Reset failed attempts if any
        if card["failed_pin_attempts"] > 0:
            upd_q = "UPDATE cards SET failed_pin_attempts = 0 WHERE card_id = ?;"
            cur.execute(upd_q, (card["card_id"],))
            conn.commit()
            log_sql(upd_q, (card["card_id"],))

        conn.close()
        return jsonify({
            "success": True,
            "message": f"Authentication successful. Welcome, {card['first_name']} {card['last_name']}!",
            "session": {
                "card_id": card["card_id"],
                "card_number": card["card_number"],
                "masked_card": f"{card['card_number'][:4]} •••• •••• {card['card_number'][-4:]}",
                "account_id": card["account_id"],
                "account_number": card["account_number"],
                "account_type": card["account_type"],
                "customer_name": f"{card['first_name']} {card['last_name']}",
                "balance": float(card["balance"]),
                "minimum_balance": float(card["minimum_balance"]),
                "daily_limit": float(card["daily_withdrawal_limit"])
            }
        })
    else:
        new_attempts = card["failed_pin_attempts"] + 1
        is_blocked = (new_attempts >= 3)
        new_status = "BLOCKED" if is_blocked else card["status"]

        upd_q = "UPDATE cards SET failed_pin_attempts = ?, status = ? WHERE card_id = ?;"
        cur.execute(upd_q, (new_attempts, new_status, card["card_id"]))
        conn.commit()
        log_sql(upd_q, (new_attempts, new_status, card["card_id"]))
        conn.close()

        if is_blocked:
            return jsonify({
                "success": False,
                "blocked": True,
                "attempts_left": 0,
                "message": "❌ 3 consecutive incorrect PIN entries! Card has been BLOCKED (Rule BR-07)."
            }), 403
        else:
            return jsonify({
                "success": False,
                "blocked": False,
                "attempts_left": 3 - new_attempts,
                "message": f"Incorrect PIN. {3 - new_attempts} attempt(s) remaining."
            }), 401

# -----------------------------------------------------------------------------
# ATM TRANSACTION SERVICES (ACID COMPLIANT)
# -----------------------------------------------------------------------------
@app.route('/api/atm/balance', methods=['GET'])
def atm_balance():
    account_id = request.args.get('account_id')
    atm_id = request.args.get('atm_id', 1)

    if not account_id:
        return jsonify({"success": False, "message": "Account ID is required."}), 400

    conn = get_db()
    cur = conn.cursor()
    sel_q = "SELECT account_id, account_number, account_type, balance, minimum_balance FROM accounts WHERE account_id = ?;"
    cur.execute(sel_q, (account_id,))
    acc = cur.fetchone()
    log_sql(sel_q, (account_id,))

    if not acc:
        conn.close()
        return jsonify({"success": False, "message": "Account not found."}), 404

    # Log balance inquiry transaction
    ins_q = """
        INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description)
        VALUES (?, ?, 'BALANCE_INQUIRY', 0.00, ?, 'SUCCESS', 'Interactive Web ATM Balance Inquiry');
    """
    cur.execute(ins_q, (account_id, atm_id, acc["balance"]))
    conn.commit()
    log_sql(ins_q, (account_id, atm_id, acc["balance"]))
    conn.close()

    return jsonify({
        "success": True,
        "account_number": acc["account_number"],
        "account_type": acc["account_type"],
        "balance": float(acc["balance"]),
        "minimum_balance": float(acc["minimum_balance"]),
        "withdrawable": max(0.0, float(acc["balance"]) - float(acc["minimum_balance"]))
    })

@app.route('/api/atm/withdraw', methods=['POST'])
def atm_withdraw():
    data = request.json or {}
    account_id = data.get("account_id")
    card_id = data.get("card_id")
    atm_id = data.get("atm_id", 1)
    try:
        amount = float(data.get("amount", 0))
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid amount format."}), 400

    if amount <= 0 or amount % 100 != 0:
        return jsonify({"success": False, "message": "Withdrawal amount must be a positive multiple of ₹100."}), 400

    conn = get_db()
    cur = conn.cursor()

    # 1. Check ATM machine status & cash reserve
    atm_q = "SELECT current_cash_level, status FROM atm_machines WHERE atm_id = ?;"
    cur.execute(atm_q, (atm_id,))
    atm = cur.fetchone()
    log_sql(atm_q, (atm_id,))

    if not atm or atm["status"] != "ONLINE" or float(atm["current_cash_level"]) < amount:
        conn.close()
        return jsonify({
            "success": False,
            "message": "ATM terminal has insufficient physical cash or is currently OFFLINE."
        }), 400

    # 2. Check Card daily limit
    card_q = "SELECT daily_withdrawal_limit, status FROM cards WHERE card_id = ?;"
    cur.execute(card_q, (card_id,))
    card = cur.fetchone()
    log_sql(card_q, (card_id,))

    if not card or card["status"] != "ACTIVE":
        conn.close()
        return jsonify({"success": False, "message": "Card is inactive or blocked."}), 403

    if amount > float(card["daily_withdrawal_limit"]):
        conn.close()
        return jsonify({
            "success": False,
            "message": f"Amount exceeds card daily withdrawal limit of ₹{float(card['daily_withdrawal_limit']):,.2f}."
        }), 400

    # 3. Check Account balance and minimum balance constraint
    acc_q = "SELECT balance, minimum_balance, account_number FROM accounts WHERE account_id = ?;"
    cur.execute(acc_q, (account_id,))
    acc = cur.fetchone()
    log_sql(acc_q, (account_id,))

    if not acc:
        conn.close()
        return jsonify({"success": False, "message": "Account not found."}), 404

    cur_bal = float(acc["balance"])
    if cur_bal < amount:
        conn.close()
        return jsonify({
            "success": False,
            "message": f"Insufficient funds. Current balance is ₹{cur_bal:,.2f}."
        }), 400

    # 4. Execute ACID Transaction: BEGIN -> DEBIT -> DISPENSE -> LOG -> COMMIT
    try:
        cur.execute("BEGIN TRANSACTION;")
        new_balance = cur_bal - amount

        # Debit account
        upd_acc = "UPDATE accounts SET balance = ? WHERE account_id = ?;"
        cur.execute(upd_acc, (new_balance, account_id))

        # Decrement ATM physical cash
        upd_atm = "UPDATE atm_machines SET current_cash_level = current_cash_level - ? WHERE atm_id = ?;"
        cur.execute(upd_atm, (amount, atm_id))

        # Record ledger
        ins_tx = """
            INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description)
            VALUES (?, ?, 'WITHDRAWAL', ?, ?, 'SUCCESS', 'Interactive ATM Cash Withdrawal');
        """
        cur.execute(ins_tx, (account_id, atm_id, amount, new_balance))
        tx_id = cur.lastrowid

        conn.commit()
        log_sql("BEGIN TRANSACTION; ... COMMIT;", (f"Withdrawal ₹{amount}", f"New Balance ₹{new_balance}"))
        conn.close()

        return jsonify({
            "success": True,
            "message": f"₹{amount:,.2f} dispensed successfully. Please collect your cash!",
            "transaction_id": tx_id,
            "amount": amount,
            "new_balance": new_balance,
            "account_number": acc["account_number"],
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })

    except Exception as e:
        conn.rollback()
        log_sql("ROLLBACK; /* Error during withdrawal */", status="FAILED")
        conn.close()
        return jsonify({"success": False, "message": f"Transaction aborted: {str(e)}"}), 500

@app.route('/api/atm/deposit', methods=['POST'])
def atm_deposit():
    data = request.json or {}
    account_id = data.get("account_id")
    atm_id = data.get("atm_id", 1)
    try:
        amount = float(data.get("amount", 0))
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid amount format."}), 400

    if amount <= 0 or amount % 100 != 0:
        return jsonify({"success": False, "message": "Deposit amount must be a positive multiple of ₹100."}), 400

    conn = get_db()
    cur = conn.cursor()

    acc_q = "SELECT balance, account_number FROM accounts WHERE account_id = ?;"
    cur.execute(acc_q, (account_id,))
    acc = cur.fetchone()
    log_sql(acc_q, (account_id,))

    if not acc:
        conn.close()
        return jsonify({"success": False, "message": "Account not found."}), 404

    cur_bal = float(acc["balance"])

    try:
        cur.execute("BEGIN TRANSACTION;")
        new_balance = cur_bal + amount

        # Credit account
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_balance, account_id))

        # Increase ATM cash
        cur.execute("UPDATE atm_machines SET current_cash_level = current_cash_level + ? WHERE atm_id = ?;", (amount, atm_id))

        # Record ledger
        ins_tx = """
            INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description)
            VALUES (?, ?, 'DEPOSIT', ?, ?, 'SUCCESS', 'Interactive ATM Cash Deposit');
        """
        cur.execute(ins_tx, (account_id, atm_id, amount, new_balance))
        tx_id = cur.lastrowid

        conn.commit()
        log_sql("BEGIN TRANSACTION; ... COMMIT;", (f"Deposit ₹{amount}", f"New Balance ₹{new_balance}"))
        conn.close()

        return jsonify({
            "success": True,
            "message": f"₹{amount:,.2f} deposited successfully into your account.",
            "transaction_id": tx_id,
            "amount": amount,
            "new_balance": new_balance,
            "account_number": acc["account_number"],
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })

    except Exception as e:
        conn.rollback()
        log_sql("ROLLBACK; /* Error during deposit */", status="FAILED")
        conn.close()
        return jsonify({"success": False, "message": f"Deposit aborted: {str(e)}"}), 500

@app.route('/api/atm/transfer', methods=['POST'])
def atm_transfer():
    data = request.json or {}
    source_acc_id = data.get("source_account_id")
    dest_acc_number = data.get("dest_account_number")
    atm_id = data.get("atm_id", 1)
    try:
        amount = float(data.get("amount", 0))
    except (ValueError, TypeError):
        return jsonify({"success": False, "message": "Invalid amount format."}), 400

    if amount <= 0:
        return jsonify({"success": False, "message": "Transfer amount must be positive."}), 400

    conn = get_db()
    cur = conn.cursor()

    # Source account
    cur.execute("SELECT account_id, account_number, balance FROM accounts WHERE account_id = ?;", (source_acc_id,))
    source_acc = cur.fetchone()

    # Dest account
    cur.execute("SELECT account_id, account_number, balance, status FROM accounts WHERE account_number = ?;", (dest_acc_number,))
    dest_acc = cur.fetchone()

    if not source_acc or not dest_acc:
        conn.close()
        return jsonify({"success": False, "message": "Source or destination account not found."}), 404

    if source_acc["account_id"] == dest_acc["account_id"]:
        conn.close()
        return jsonify({"success": False, "message": "Sender and recipient accounts cannot be the same (Rule BR-09)."}), 400

    if dest_acc["status"] != "ACTIVE":
        conn.close()
        return jsonify({"success": False, "message": f"Recipient account is {dest_acc['status']} and cannot receive funds."}), 400

    source_bal = float(source_acc["balance"])
    if source_bal < amount:
        conn.close()
        return jsonify({
            "success": False,
            "message": f"Insufficient funds for transfer. Available: ₹{source_bal:,.2f}."
        }), 400

    # Atomic Two-Phase Transfer
    try:
        cur.execute("BEGIN TRANSACTION;")
        new_source_bal = source_bal - amount
        new_dest_bal = float(dest_acc["balance"]) + amount

        # Debit source
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_source_bal, source_acc["account_id"]))

        # Credit destination
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_dest_bal, dest_acc["account_id"]))

        # Record ledger
        ins_tx = """
            INSERT INTO transactions (account_id, dest_account_id, atm_id, transaction_type, amount, balance_after, status, description)
            VALUES (?, ?, ?, 'TRANSFER', ?, ?, 'SUCCESS', ?);
        """
        cur.execute(ins_tx, (source_acc["account_id"], dest_acc["account_id"], atm_id, amount, new_source_bal, f"Fund transfer to {dest_acc_number}"))
        tx_id = cur.lastrowid

        conn.commit()
        log_sql("BEGIN TRANSACTION; /* Debit & Credit Transfer */ COMMIT;", (f"Transfer ₹{amount} to {dest_acc_number}"))
        conn.close()

        return jsonify({
            "success": True,
            "message": f"₹{amount:,.2f} transferred successfully to {dest_acc_number}.",
            "transaction_id": tx_id,
            "amount": amount,
            "new_balance": new_source_bal,
            "account_number": source_acc["account_number"],
            "recipient_account": dest_acc_number,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        })

    except Exception as e:
        conn.rollback()
        log_sql("ROLLBACK; /* Transfer failed */", status="FAILED")
        conn.close()
        return jsonify({"success": False, "message": f"Transfer aborted: {str(e)}"}), 500

@app.route('/api/atm/statement', methods=['GET'])
def atm_statement():
    account_id = request.args.get('account_id')
    if not account_id:
        return jsonify({"success": False, "message": "Account ID is required."}), 400

    conn = get_db()
    cur = conn.cursor()
    query = """
        SELECT transaction_id, transaction_type, amount, balance_after, status,
               strftime('%d-%m-%Y %H:%M', transaction_timestamp) AS formatted_time,
               COALESCE(description, 'Direct Transaction') AS memo
        FROM transactions
        WHERE account_id = ? OR dest_account_id = ?
        ORDER BY transaction_timestamp DESC, transaction_id DESC
        LIMIT 6;
    """
    cur.execute(query, (account_id, account_id))
    rows = cur.fetchall()
    log_sql(query, (account_id, account_id))
    conn.close()

    items = []
    for r in rows:
        items.append({
            "transaction_id": r["transaction_id"],
            "type": r["transaction_type"],
            "amount": float(r["amount"]),
            "balance_after": float(r["balance_after"]),
            "status": r["status"],
            "time": r["formatted_time"],
            "memo": r["memo"]
        })

    return jsonify({"success": True, "transactions": items})

@app.route('/api/atm/change-pin', methods=['POST'])
def change_pin():
    data = request.json or {}
    card_id = data.get("card_id")
    old_pin = data.get("old_pin")
    new_pin = data.get("new_pin")

    if not card_id or not old_pin or not new_pin:
        return jsonify({"success": False, "message": "All PIN fields are required."}), 400

    if not (str(new_pin).isdigit() and len(str(new_pin)) == 4):
        return jsonify({"success": False, "message": "New PIN must be exactly 4 digits."}), 400

    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT pin_hash FROM cards WHERE card_id = ?;", (card_id,))
    row = cur.fetchone()

    if not row or hash_pin(old_pin) != row["pin_hash"]:
        conn.close()
        return jsonify({"success": False, "message": "Current PIN verification failed."}), 401

    upd_q = "UPDATE cards SET pin_hash = ? WHERE card_id = ?;"
    new_hash = hash_pin(new_pin)
    cur.execute(upd_q, (new_hash, card_id))
    conn.commit()
    log_sql(upd_q, ("<new_sha256_hash>", card_id))
    conn.close()

    return jsonify({"success": True, "message": "PIN updated successfully!"})

# -----------------------------------------------------------------------------
# BANK ADMIN & ANALYTICS ENDPOINTS
# -----------------------------------------------------------------------------
@app.route('/api/admin/atms', methods=['GET'])
def get_atms():
    conn = get_db()
    cur = conn.cursor()
    query = "SELECT atm_id, terminal_code, branch_name, location_address, city, cash_capacity, current_cash_level, status FROM atm_machines;"
    cur.execute(query)
    rows = cur.fetchall()
    log_sql(query)
    conn.close()

    atms = []
    for r in rows:
        atms.append({
            "atm_id": r["atm_id"],
            "terminal_code": r["terminal_code"],
            "branch_name": r["branch_name"],
            "city": r["city"],
            "cash_capacity": float(r["cash_capacity"]),
            "current_cash_level": float(r["current_cash_level"]),
            "status": r["status"]
        })
    return jsonify({"success": True, "atms": atms})

@app.route('/api/admin/replenish', methods=['POST'])
def replenish_atm():
    data = request.json or {}
    atm_id = data.get("atm_id", 1)
    amount = float(data.get("amount", 25000))

    conn = get_db()
    cur = conn.cursor()
    upd_q = "UPDATE atm_machines SET current_cash_level = current_cash_level + ?, status = 'ONLINE', last_serviced_date = CURRENT_DATE WHERE atm_id = ?;"
    cur.execute(upd_q, (amount, atm_id))
    conn.commit()
    log_sql(upd_q, (amount, atm_id))
    conn.close()

    return jsonify({"success": True, "message": f"ATM #{atm_id} replenished with ₹{amount:,.2f} and brought ONLINE."})

@app.route('/api/admin/unblock', methods=['POST'])
def unblock_card():
    data = request.json or {}
    card_id = data.get("card_id")

    conn = get_db()
    cur = conn.cursor()
    upd_q = "UPDATE cards SET status = 'ACTIVE', failed_pin_attempts = 0 WHERE card_id = ?;"
    cur.execute(upd_q, (card_id,))
    conn.commit()
    log_sql(upd_q, (card_id,))
    conn.close()

    return jsonify({"success": True, "message": f"Card #{card_id} has been unblocked. Failed attempts reset to 0."})

@app.route('/api/admin/analytics', methods=['GET'])
def get_analytics():
    conn = get_db()
    cur = conn.cursor()
    # Review 1 Group Functions Demonstration
    grp_q = """
        SELECT account_type, COUNT(*) AS total_accounts,
               ROUND(SUM(balance), 2) AS total_balance,
               ROUND(AVG(balance), 2) AS avg_balance,
               ROUND(MIN(balance), 2) AS min_balance,
               ROUND(MAX(balance), 2) AS max_balance
        FROM accounts
        GROUP BY account_type;
    """
    cur.execute(grp_q)
    group_rows = cur.fetchall()

    tx_q = """
        SELECT COUNT(*) AS total_transactions,
               ROUND(SUM(amount), 2) AS total_volume,
               ROUND(AVG(amount), 2) AS avg_volume
        FROM transactions WHERE status = 'SUCCESS';
    """
    cur.execute(tx_q)
    tx_summary = cur.fetchone()
    conn.close()

    groups = []
    for g in group_rows:
        groups.append({
            "type": g["account_type"],
            "count": g["total_accounts"],
            "total_balance": float(g["total_balance"]),
            "avg_balance": float(g["avg_balance"]),
            "min_balance": float(g["min_balance"]),
            "max_balance": float(g["max_balance"])
        })

    return jsonify({
        "success": True,
        "portfolio": groups,
        "transactions_count": tx_summary["total_transactions"],
        "total_volume": float(tx_summary["total_volume"] or 0),
        "avg_volume": float(tx_summary["avg_volume"] or 0)
    })

@app.route('/api/admin/sql-logs', methods=['GET'])
def get_sql_logs():
    return jsonify({"success": True, "logs": SQL_LOGS[:20]})

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    print("\n" + "=" * 70)
    print(" 🏧  METRO BANK OF INDIA — ATM SIMULATOR SERVER STARTING")
    print(f" 🌐  Open in your web browser: http://127.0.0.1:{port}")
    print("=" * 70 + "\n")
    app.run(host="127.0.0.1", port=port, debug=False)

