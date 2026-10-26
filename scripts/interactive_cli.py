#!/usr/bin/env python3
"""
Interactive Terminal CLI for Simple ATM Management System
Allows interactive card insertion, PIN authentication, cash withdrawal,
cash deposit, fund transfers, balance inquiry, mini-statement, and admin tasks.
"""

import sqlite3
import hashlib
import os
import sys
import getpass
from datetime import datetime

# UTF-8 handling for Windows
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_FILE = os.path.join(BASE_DIR, "atm_system.db")

if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)
try:
    from app import evaluate_fraud_risk, haversine_distance
except ImportError:
    evaluate_fraud_risk = None
    haversine_distance = None

# ANSI Color Codes
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

CURRENT_ATM = {"id": 1, "city": "Mumbai", "loc": "Nariman Point"}

def switch_atm_terminal(conn):
    global CURRENT_ATM
    cur = conn.cursor()
    cur.execute("SELECT atm_id, city, location_description, latitude, longitude FROM atm_machines ORDER BY atm_id;")
    terminals = cur.fetchall()
    print(f"\n{CYAN}{BOLD}--- SELECT PHYSICAL ATM TERMINAL LOCATION ---{RESET}")
    for t in terminals:
        active_mark = f"{GREEN}*ACTIVE*{RESET}" if t["atm_id"] == CURRENT_ATM["id"] else ""
        print(f"  [{t['atm_id']}] {t['city']:<12} - {t['location_description']:<26} ({t['latitude']:.4f}°N, {t['longitude']:.4f}°E) {active_mark}")

    choice = input(f"\nSelect ATM ID (1-{len(terminals)}) > ").strip()
    if choice.isdigit() and 1 <= int(choice) <= len(terminals):
        t_sel = next((t for t in terminals if t["atm_id"] == int(choice)), None)
        if t_sel:
            CURRENT_ATM = {"id": t_sel["atm_id"], "city": t_sel["city"], "loc": t_sel["location_description"]}
            print(f"\n{GREEN}✅ Switched physical location to: ATM-{t_sel['atm_id']:02d} ({t_sel['city']} - {t_sel['location_description']}){RESET}")

def get_db():
    conn = sqlite3.connect(DB_FILE)
    conn.execute("PRAGMA foreign_keys = ON;")
    conn.row_factory = sqlite3.Row
    return conn

def hash_pin(pin_str):
    return hashlib.sha256(pin_str.strip().encode("utf-8")).hexdigest()

def banner():
    print(f"{CYAN}{BOLD}")
    print("=" * 65)
    print("      🏧  METRO BANK OF INDIA - INTERACTIVE ATM SYSTEM  🏧      ")
    print("         ACID-Compliant Relational Banking Simulation           ")
    print("=" * 65)
    print(f"{RESET}")

def print_receipt(tx_id, acc_num, tx_type, amount, balance_after, terminal="ATM-MUM-01"):
    print(f"\n{YELLOW}┌──────────────────────────────────────────────┐")
    print("│             TRANSACTION RECEIPT              │")
    print("├──────────────────────────────────────────────┤")
    print(f"│ Terminal:   {terminal:<32} │")
    print(f"│ Tx Ref:     TXN-{tx_id:<28} │")
    print(f"│ Timestamp:  {datetime.now().strftime('%Y-%m-%d %H:%M:%S'):<32} │")
    print(f"│ Account:    {acc_num:<32} │")
    print(f"│ Type:       {tx_type:<32} │")
    print(f"│ Amount:     ₹{amount:,.2f}{' ' * (31 - len(f'₹{amount:,.2f}'))}│")
    print(f"│ Available:  ₹{balance_after:,.2f}{' ' * (31 - len(f'₹{balance_after:,.2f}'))}│")
    print(f"│ Status:     SUCCESS                          │")
    print("└──────────────────────────────────────────────┘" + RESET)

def list_sample_cards(conn):
    cur = conn.cursor()
    cur.execute("""
        SELECT c.card_id, c.card_number, c.status, c.failed_pin_attempts,
               cust.first_name || ' ' || cust.last_name AS customer_name,
               a.account_number, a.account_type, a.balance
        FROM cards c
        JOIN accounts a ON c.account_id = a.account_id
        JOIN customers cust ON a.customer_id = cust.customer_id
        LIMIT 6;
    """)
    rows = cur.fetchall()
    print(f"\n{BOLD}📋 Available Sample Cards (Default PIN: 1234):{RESET}")
    print(f"{'#':<3} {'Card Number':<20} {'Holder':<18} {'Type':<10} {'Balance':<12} {'Status'}")
    print("-" * 72)
    for idx, r in enumerate(rows, 1):
        status_color = GREEN if r["status"] == "ACTIVE" else RED
        masked_card = f"{r['card_number'][:4]} •••• •••• {r['card_number'][-4:]}"
        print(f"{idx:<3} {masked_card:<20} {r['customer_name']:<18} {r['account_type']:<10} ₹{r['balance']:<11,.2f} {status_color}{r['status']}{RESET}")
    return rows

def authenticate_card(conn):
    cards = list_sample_cards(conn)
    print(f"\n{BOLD}📍 Current Terminal: {CYAN}ATM-{CURRENT_ATM['id']:02d} ({CURRENT_ATM['city']} - {CURRENT_ATM['loc']}){RESET}")
    print(f"{BOLD}Options:{RESET}")
    print("  [1-6] Quick-select a card from the list above")
    print("  [M]   Manually enter a 16-digit card number")
    print("  [T]   📍 Switch Physical ATM Terminal Location (e.g. Mumbai ➔ Delhi)")
    print("  [A]   Bank Admin Dashboard")
    print("  [F]   🛡️  Fraud & Geo-Velocity Radar (DBMS Novelty Engine)")
    print("  [Q]   Exit Application")

    choice = input(f"\n{BOLD}Select an option > {RESET}").strip()
    if choice.upper() == 'Q':
        print(f"\n{GREEN}Thank you for banking with Metro Bank. Goodbye!{RESET}\n")
        sys.exit(0)
    elif choice.upper() == 'T':
        switch_atm_terminal(conn)
        return None
    elif choice.upper() == 'A':
        admin_dashboard(conn)
        return None
    elif choice.upper() == 'F':
        fraud_radar_cli(conn)
        return None
    elif choice.upper() == 'M':
        card_num = input("Enter 16-digit card number: ").strip()
    elif choice.isdigit() and 1 <= int(choice) <= len(cards):
        card_num = cards[int(choice) - 1]["card_number"]
    else:
        print(f"{RED}Invalid selection.{RESET}")
        return None

    cur = conn.cursor()
    cur.execute("""
        SELECT c.*, a.account_number, a.account_type, a.balance, a.minimum_balance, a.status AS acc_status,
               cust.first_name, cust.last_name
        FROM cards c
        JOIN accounts a ON c.account_id = a.account_id
        JOIN customers cust ON a.customer_id = cust.customer_id
        WHERE c.card_number = ?;
    """, (card_num,))
    card = cur.fetchone()

    if not card:
        print(f"{RED}❌ Card not found in bank database!{RESET}")
        return None

    if card["status"] == "BLOCKED":
        print(f"{RED}❌ This card is BLOCKED due to excessive failed PIN attempts.{RESET}")
        print(f"{YELLOW}Please contact customer branch support or ask Admin to unblock it.{RESET}")
        return None

    if card["status"] != "ACTIVE":
        print(f"{RED}❌ Card status is {card['status']}. Cannot process transactions.{RESET}")
        return None

    # PIN Authentication with 3-attempt lockout
    attempts_left = 3 - card["failed_pin_attempts"]
    while attempts_left > 0:
        entered_pin = input(f"Enter 4-Digit PIN for {card['first_name']} {card['last_name']} ({attempts_left} attempts left) [Demo: 1234]: ").strip()
        hashed = hash_pin(entered_pin)

        if hashed == card["pin_hash"]:
            # Reset failed attempts if any
            if card["failed_pin_attempts"] > 0:
                cur.execute("UPDATE cards SET failed_pin_attempts = 0 WHERE card_id = ?", (card["card_id"],))
                conn.commit()
            print(f"\n{GREEN}✅ PIN Accepted! Welcome, {card['first_name']} {card['last_name']}.{RESET}")
            return card
        else:
            attempts_left -= 1
            new_failed = card["failed_pin_attempts"] + (3 - attempts_left)
            if attempts_left == 0:
                cur.execute("UPDATE cards SET status = 'BLOCKED', failed_pin_attempts = 3 WHERE card_id = ?", (card["card_id"],))
                conn.commit()
                print(f"\n{RED}❌ 3 Failed Attempts! CARD HAS BEEN BLOCKED FOR SECURITY (Rule BR-07).{RESET}")
                return None
            else:
                cur.execute("UPDATE cards SET failed_pin_attempts = ? WHERE card_id = ?", (new_failed, card["card_id"]))
                conn.commit()
                print(f"{RED}Incorrect PIN. {attempts_left} attempt(s) remaining.{RESET}")

    return None

def check_balance(conn, card):
    cur = conn.cursor()
    cur.execute("SELECT balance, minimum_balance, account_number, account_type FROM accounts WHERE account_id = ?", (card["account_id"],))
    acc = cur.fetchone()

    # Log balance inquiry in transactions table
    cur.execute("""
        INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description)
        VALUES (?, 1, 'BALANCE_INQUIRY', 0.00, ?, 'SUCCESS', 'Interactive Balance Inquiry via ATM');
    """, (card["account_id"], acc["balance"]))
    conn.commit()

    print(f"\n{CYAN}--- ACCOUNT BALANCE INQUIRY ---{RESET}")
    print(f"Account Number:     {acc['account_number']}")
    print(f"Account Type:       {acc['account_type']}")
    print(f"Available Balance:  {GREEN}₹{acc['balance']:,.2f}{RESET}")
    print(f"Minimum Required:   ₹{acc['minimum_balance']:,.2f}")
    print(f"Withdrawable:       ₹{max(0.0, acc['balance'] - acc['minimum_balance']):,.2f}")

def withdraw_cash(conn, card):
    print(f"\n{CYAN}--- CASH WITHDRAWAL ---{RESET}")
    print("1. ₹500       2. ₹1,000")
    print("3. ₹2,000     4. ₹5,000")
    print("5. Custom Amount")
    print("0. Back to Main Menu")

    choice = input("\nSelect withdrawal option > ").strip()
    amounts = {"1": 500.0, "2": 1000.0, "3": 2000.0, "4": 5000.0}

    if choice in amounts:
        amt = amounts[choice]
    elif choice == "5":
        try:
            amt = float(input("Enter amount to withdraw (multiples of ₹100): ").strip())
            if amt <= 0 or amt % 100 != 0:
                print(f"{RED}Amount must be a positive multiple of ₹100.{RESET}")
                return
        except ValueError:
            print(f"{RED}Invalid numeric amount.{RESET}")
            return
    elif choice == "0":
        return
    else:
        print(f"{RED}Invalid choice.{RESET}")
        return

    cur = conn.cursor()
    # Check ATM machine cash reserve
    cur.execute("SELECT current_cash_level, status FROM atm_machines WHERE atm_id = ?;", (CURRENT_ATM["id"],))
    atm = cur.fetchone()
    if atm["status"] != "ONLINE" or atm["current_cash_level"] < amt:
        print(f"{RED}❌ Transaction Declined: ATM has insufficient physical cash or is offline.{RESET}")
        return

    # Check card daily limit
    if amt > card["daily_withdrawal_limit"]:
        print(f"{RED}❌ Transaction Declined: Exceeds card daily withdrawal limit of ₹{card['daily_withdrawal_limit']:,.2f}.{RESET}")
        return

    # Fetch current account balance
    cur.execute("SELECT balance, minimum_balance, account_number FROM accounts WHERE account_id = ?", (card["account_id"],))
    acc = cur.fetchone()

    if acc["balance"] < amt:
        print(f"{RED}❌ Transaction Declined: Insufficient balance! Current Balance: ₹{acc['balance']:,.2f}.{RESET}")
        return

    # Real-Time In-Database Fraud & Geo-Velocity Risk Assessment
    if evaluate_fraud_risk:
        fraud_risk = evaluate_fraud_risk(conn, card["card_id"], card["account_id"], CURRENT_ATM["id"], amt)
        if fraud_risk.get("is_blocked"):
            now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cur.execute("""
                INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description, transaction_timestamp)
                VALUES (?, ?, 'WITHDRAWAL', ?, ?, 'FAILED', ?, ?);
            """, (card["account_id"], CURRENT_ATM["id"], amt, acc["balance"], f"Declined: {fraud_risk.get('reason')}", now_str))
            conn.commit()
            print(f"\n{RED}{BOLD}🚨 SECURITY LOCKOUT (Rule BR-08 Violation)!{RESET}")
            print(f"{RED}{fraud_risk.get('reason')}{RESET}")
            print(f"{RED}Transaction blocked. Your card has been locked immediately. Contact branch admin.{RESET}")
            return
        elif fraud_risk.get("is_flagged"):
            print(f"\n{YELLOW}⚠️  SECURITY WARNING: {fraud_risk.get('reason')}{RESET}")

    # Execute ACID Transaction
    try:
        cur.execute("BEGIN TRANSACTION;")
        new_balance = acc["balance"] - amt
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 1. Deduct balance from account
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_balance, card["account_id"]))
        
        # 2. Deduct physical cash from ATM
        cur.execute("UPDATE atm_machines SET current_cash_level = current_cash_level - ? WHERE atm_id = ?;", (amt, CURRENT_ATM["id"]))
        
        # 3. Log transaction ledger
        cur.execute("""
            INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description, transaction_timestamp)
            VALUES (?, ?, 'WITHDRAWAL', ?, ?, 'SUCCESS', 'Interactive ATM Cash Dispense', ?);
        """, (card["account_id"], CURRENT_ATM["id"], amt, new_balance, now_str))
        tx_id = cur.lastrowid

        conn.commit()
        print(f"\n{GREEN}💵 [CHING!] Cash Dispensed: ₹{amt:,.2f}. Please collect your cash!{RESET}")
        print_receipt(tx_id, acc["account_number"], "WITHDRAWAL", amt, new_balance, terminal=f"ATM-{CURRENT_ATM['id']:02d} ({CURRENT_ATM['city']})")

    except Exception as e:
        conn.rollback()
        print(f"{RED}❌ Transaction failed and rolled back: {e}{RESET}")

def deposit_cash(conn, card):
    print(f"\n{CYAN}--- CASH DEPOSIT ---{RESET}")
    try:
        amt = float(input("Enter cash amount to deposit (₹): ").strip())
        if amt <= 0 or amt % 100 != 0:
            print(f"{RED}Amount must be a positive multiple of ₹100.{RESET}")
            return
    except ValueError:
        print(f"{RED}Invalid numeric amount.{RESET}")
        return

    cur = conn.cursor()
    cur.execute("SELECT balance, account_number FROM accounts WHERE account_id = ?", (card["account_id"],))
    acc = cur.fetchone()

    try:
        cur.execute("BEGIN TRANSACTION;")
        new_balance = acc["balance"] + amt

        # 1. Credit account
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_balance, card["account_id"]))

        # 2. Increase ATM cash
        cur.execute("UPDATE atm_machines SET current_cash_level = current_cash_level + ? WHERE atm_id = 1;", (amt,))

        # 3. Record transaction
        cur.execute("""
            INSERT INTO transactions (account_id, atm_id, transaction_type, amount, balance_after, status, description)
            VALUES (?, 1, 'DEPOSIT', ?, ?, 'SUCCESS', 'Interactive ATM Cash Deposit');
        """, (card["account_id"], amt, new_balance))
        tx_id = cur.lastrowid

        conn.commit()
        print(f"\n{GREEN}✅ Deposit Successful! ₹{amt:,.2f} credited to your account.{RESET}")
        print_receipt(tx_id, acc["account_number"], "DEPOSIT", amt, new_balance)

    except Exception as e:
        conn.rollback()
        print(f"{RED}❌ Deposit failed and rolled back: {e}{RESET}")

def transfer_funds(conn, card):
    print(f"\n{CYAN}--- INTER-ACCOUNT FUND TRANSFER ---{RESET}")
    cur = conn.cursor()
    
    # List other available accounts for quick transfer
    cur.execute("""
        SELECT a.account_id, a.account_number, a.account_type, cust.first_name || ' ' || cust.last_name AS name
        FROM accounts a
        JOIN customers cust ON a.customer_id = cust.customer_id
        WHERE a.account_id != ? AND a.status = 'ACTIVE'
        LIMIT 5;
    """, (card["account_id"],))
    dest_options = cur.fetchall()

    print("Suggested recipient accounts:")
    for idx, d in enumerate(dest_options, 1):
        print(f"  [{idx}] {d['account_number']} ({d['name']} - {d['account_type']})")
    print("  [M] Enter custom account number")
    print("  [0] Cancel")

    dest_choice = input("\nSelect recipient > ").strip()
    if dest_choice == "0":
        return
    elif dest_choice.upper() == "M":
        dest_acc_num = input("Enter destination account number: ").strip()
    elif dest_choice.isdigit() and 1 <= int(dest_choice) <= len(dest_options):
        dest_acc_num = dest_options[int(dest_choice) - 1]["account_number"]
    else:
        print(f"{RED}Invalid selection.{RESET}")
        return

    cur.execute("SELECT account_id, account_number, balance, status FROM accounts WHERE account_number = ?", (dest_acc_num,))
    dest_acc = cur.fetchone()

    if not dest_acc:
        print(f"{RED}❌ Destination account not found.{RESET}")
        return

    if dest_acc["account_id"] == card["account_id"]:
        print(f"{RED}❌ Cannot transfer funds to the same account (Rule BR-09).{RESET}")
        return

    try:
        amt = float(input(f"Enter amount to transfer to {dest_acc_num} (₹): ").strip())
        if amt <= 0:
            print(f"{RED}Amount must be positive.{RESET}")
            return
    except ValueError:
        print(f"{RED}Invalid numeric amount.{RESET}")
        return

    # Check sender balance
    cur.execute("SELECT balance, account_number FROM accounts WHERE account_id = ?", (card["account_id"],))
    sender_acc = cur.fetchone()

    if sender_acc["balance"] < amt:
        print(f"{RED}❌ Insufficient balance for transfer. Current balance: ₹{sender_acc['balance']:,.2f}.{RESET}")
        return

    # ACID Two-Phase Transfer
    try:
        cur.execute("BEGIN TRANSACTION;")
        new_sender_bal = sender_acc["balance"] - amt
        new_dest_bal = dest_acc["balance"] + amt

        # 1. Debit sender
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_sender_bal, card["account_id"]))

        # 2. Credit receiver
        cur.execute("UPDATE accounts SET balance = ? WHERE account_id = ?;", (new_dest_bal, dest_acc["account_id"]))

        # 3. Record sender transaction ledger
        cur.execute("""
            INSERT INTO transactions (account_id, dest_account_id, atm_id, transaction_type, amount, balance_after, status, description)
            VALUES (?, ?, 1, 'TRANSFER', ?, ?, 'SUCCESS', ?);
        """, (card["account_id"], dest_acc["account_id"], amt, new_sender_bal, f"Transfer sent to {dest_acc_num}"))
        tx_id = cur.lastrowid

        conn.commit()
        print(f"\n{GREEN}✅ Transfer of ₹{amt:,.2f} to {dest_acc_num} completed successfully!{RESET}")
        print_receipt(tx_id, sender_acc["account_number"], "TRANSFER", amt, new_sender_bal)

    except Exception as e:
        conn.rollback()
        print(f"{RED}❌ Transfer failed and rolled back: {e}{RESET}")

def mini_statement(conn, card):
    print(f"\n{CYAN}--- MINI-STATEMENT (LAST 5 TRANSACTIONS) ---{RESET}")
    cur = conn.cursor()
    cur.execute("""
        SELECT transaction_id, transaction_type, amount, balance_after, status,
               strftime('%d-%m-%Y %H:%M', transaction_timestamp) AS formatted_time,
               COALESCE(description, 'No description') AS memo
        FROM transactions
        WHERE account_id = ? OR dest_account_id = ?
        ORDER BY transaction_timestamp DESC, transaction_id DESC
        LIMIT 5;
    """, (card["account_id"], card["account_id"]))
    rows = cur.fetchall()

    if not rows:
        print("No transactions logged for this account yet.")
        return

    print(f"{'Tx ID':<7} {'Date/Time':<18} {'Type':<16} {'Amount':<12} {'Balance After':<14} {'Status'}")
    print("-" * 75)
    for r in rows:
        color = GREEN if r["status"] == "SUCCESS" else RED
        amt_str = f"₹{r['amount']:,.2f}"
        bal_str = f"₹{r['balance_after']:,.2f}"
        print(f"{r['transaction_id']:<7} {r['formatted_time']:<18} {r['transaction_type']:<16} {amt_str:<12} {bal_str:<14} {color}{r['status']}{RESET}")

def change_pin(conn, card):
    print(f"\n{CYAN}--- CHANGE ATM PIN ---{RESET}")
    current_pin = input("Enter current 4-digit PIN: ").strip()
    if hash_pin(current_pin) != card["pin_hash"]:
        print(f"{RED}❌ Incorrect current PIN.{RESET}")
        return

    new_pin = input("Enter NEW 4-digit PIN: ").strip()
    if not (new_pin.isdigit() and len(new_pin) == 4):
        print(f"{RED}❌ PIN must be exactly 4 numeric digits.{RESET}")
        return

    confirm_pin = input("Confirm NEW 4-digit PIN: ").strip()
    if new_pin != confirm_pin:
        print(f"{RED}❌ PIN confirmation mismatch.{RESET}")
        return

    cur = conn.cursor()
    cur.execute("UPDATE cards SET pin_hash = ? WHERE card_id = ?", (hash_pin(new_pin), card["card_id"]))
    conn.commit()
    print(f"\n{GREEN}✅ PIN updated successfully! Use your new PIN for future transactions.{RESET}")

def admin_dashboard(conn):
    print(f"\n{YELLOW}{BOLD}=======================================================")
    print("           🏛️  BANK ADMINISTRATION DASHBOARD            ")
    print("=======================================================" + RESET)
    cur = conn.cursor()

    print("\n1. 📊 View ATM Terminals & Cash Reserves")
    print("2. 💵 Replenish ATM Terminal Cash")
    print("3. 🔓 Unblock a Blocked Card (Reset PIN attempts)")
    print("4. 📈 View Group Aggregates (Review 1 Group Functions)")
    print("5. 📜 View Recent Global Transaction Audit Trail")
    print("0. 🔙 Return to ATM Mode")

    choice = input("\nSelect admin action > ").strip()

    if choice == "1":
        cur.execute("SELECT atm_id, terminal_code, branch_name, city, cash_capacity, current_cash_level, status FROM atm_machines;")
        print(f"\n{'ID':<4} {'Terminal':<14} {'Branch':<22} {'City':<12} {'Cash Level':<14} {'Status'}")
        print("-" * 75)
        for r in cur.fetchall():
            c = GREEN if r["status"] == "ONLINE" else (YELLOW if r["status"] == "OUT_OF_CASH" else RED)
            print(f"{r['atm_id']:<4} {r['terminal_code']:<14} {r['branch_name']:<22} {r['city']:<12} ₹{r['current_cash_level']:<13,.2f} {c}{r['status']}{RESET}")

    elif choice == "2":
        atm_id = input("Enter ATM ID to replenish (e.g., 7 for FC Road Pune): ").strip()
        amt = float(input("Enter cash amount to add (₹): ").strip())
        cur.execute("UPDATE atm_machines SET current_cash_level = current_cash_level + ?, status = 'ONLINE', last_serviced_date = CURRENT_DATE WHERE atm_id = ?;", (amt, atm_id))
        conn.commit()
        print(f"{GREEN}✅ ATM {atm_id} replenished successfully and marked ONLINE.{RESET}")

    elif choice == "3":
        cur.execute("""
            SELECT c.card_id, c.card_number, c.status, c.failed_pin_attempts, cust.first_name || ' ' || cust.last_name AS name
            FROM cards c
            JOIN accounts a ON c.account_id = a.account_id
            JOIN customers cust ON a.customer_id = cust.customer_id
            WHERE c.status = 'BLOCKED' OR c.failed_pin_attempts > 0;
        """)
        blocked = cur.fetchall()
        if not blocked:
            print(f"{GREEN}No cards are currently blocked or flagged.{RESET}")
            return
        print(f"\n{'ID':<5} {'Card Number':<20} {'Holder':<20} {'Status':<10} {'Failed Attempts'}")
        print("-" * 65)
        for b in blocked:
            print(f"{b['card_id']:<5} {b['card_number']:<20} {b['name']:<20} {RED}{b['status']:<10}{RESET} {b['failed_pin_attempts']}")
        card_id_to_unblock = input("\nEnter Card ID to unblock > ").strip()
        cur.execute("UPDATE cards SET status = 'ACTIVE', failed_pin_attempts = 0 WHERE card_id = ?", (card_id_to_unblock,))
        conn.commit()
        print(f"{GREEN}✅ Card {card_id_to_unblock} has been unblocked and failed attempts reset to 0.{RESET}")

    elif choice == "4":
        print(f"\n{BOLD}Review 1 Group Functions Demonstration:{RESET}")
        cur.execute("""
            SELECT account_type, COUNT(*) AS total_accounts,
                   ROUND(SUM(balance), 2) AS total_deposits,
                   ROUND(AVG(balance), 2) AS avg_balance
            FROM accounts GROUP BY account_type;
        """)
        for r in cur.fetchall():
            print(f"Type: {r['account_type']:<9} | Accounts: {r['total_accounts']} | Total Deposits: ₹{r['total_deposits']:,.2f} | Average: ₹{r['avg_balance']:,.2f}")

    elif choice == "5":
        cur.execute("""
            SELECT transaction_id, account_id, transaction_type, amount, balance_after, status, transaction_timestamp
            FROM transactions ORDER BY transaction_timestamp DESC LIMIT 8;
        """)
        print(f"\n{'Tx ID':<7} {'Acc':<5} {'Type':<16} {'Amount':<12} {'Balance After':<14} {'Status':<9} {'Time'}")
        print("-" * 75)
        for r in cur.fetchall():
            c = GREEN if r["status"] == "SUCCESS" else RED
            print(f"{r['transaction_id']:<7} {r['account_id']:<5} {r['transaction_type']:<16} ₹{r['amount']:<11,.2f} ₹{r['balance_after']:<13,.2f} {c}{r['status']:<9}{RESET} {r['transaction_timestamp']}")

def fraud_radar_cli(conn):
    cur = conn.cursor()
    while True:
        print(f"\n{CYAN}{BOLD}=================================================================")
        print("      🛡️  REAL-TIME IN-DATABASE FRAUD & GEO-VELOCITY RADAR  🛡️      ")
        print("================================================================={RESET}")

        cur.execute("SELECT COUNT(*) AS total FROM fraud_alerts;")
        total_alerts = cur.fetchone()["total"]
        cur.execute("SELECT COUNT(*) AS critical FROM fraud_alerts WHERE severity = 'CRITICAL';")
        crit_alerts = cur.fetchone()["critical"]
        cur.execute("SELECT COUNT(*) AS locked FROM cards WHERE status = 'BLOCKED';")
        locked_cards = cur.fetchone()["locked"]

        print(f"\n{BOLD}Threat Summary:{RESET}")
        print(f"  • Total Alerts Logged:   {RED if total_alerts > 0 else GREEN}{total_alerts}{RESET}")
        print(f"  • Critical Breaches:     {RED if crit_alerts > 0 else GREEN}{crit_alerts}{RESET}")
        print(f"  • Cards Auto-Locked:     {YELLOW if locked_cards > 0 else GREEN}{locked_cards}{RESET}")

        print(f"\n{BOLD}Radar Actions:{RESET}")
        print("  [1] 📋 View Recent Forensic Fraud Alerts (fraud_alerts table)")
        print("  [2] 🌐 View ATM Fleet Geolocation Mesh & Risk Index")
        print("  [3] 🚀 Simulate Impossible Travel Attack (Mumbai ➔ Delhi in 15 mins)")
        print("  [4] ⚡ Simulate High-Frequency Swiping Burst (4 swipes in 2 mins)")
        print("  [5] 📈 Simulate Extreme Outlier Cash Withdrawal Spike")
        print("  [0] Back to Main Menu")

        choice = input(f"\n{BOLD}Select Radar Option > {RESET}").strip()

        if choice == "1":
            cur.execute("""
                SELECT fa.alert_id, fa.alert_type, fa.severity, fa.action_taken,
                       fa.distance_km, fa.time_diff_mins, fa.calculated_velocity_kmh,
                       fa.amount, fa.created_at,
                       cust.first_name || ' ' || cust.last_name AS customer_name,
                       c.card_number
                FROM fraud_alerts fa
                JOIN cards c ON fa.card_id = c.card_id
                JOIN accounts a ON c.account_id = a.account_id
                JOIN customers cust ON a.customer_id = cust.customer_id
                ORDER BY fa.created_at DESC LIMIT 10;
            """)
            alerts = cur.fetchall()
            print(f"\n{'ID':<5} {'Holder':<18} {'Type':<20} {'Severity':<10} {'Speed (km/h)':<14} {'Action'}")
            print("-" * 80)
            for a in alerts:
                sev_color = RED if a["severity"] == "CRITICAL" else (YELLOW if a["severity"] == "HIGH" else CYAN)
                speed_str = f"{a['calculated_velocity_kmh']:.1f} km/h" if a["calculated_velocity_kmh"] else "N/A"
                print(f"#{a['alert_id']:<4} {a['customer_name']:<18} {a['alert_type']:<20} {sev_color}{a['severity']:<10}{RESET} {speed_str:<14} {a['action_taken']}")

        elif choice == "2":
            cur.execute("""
                SELECT atm_id, location_description, city, latitude, longitude, current_cash_level, status
                FROM atm_machines ORDER BY atm_id;
            """)
            terminals = cur.fetchall()
            print(f"\n{'ID':<8} {'City':<12} {'Location':<24} {'Coordinates':<24} {'Cash':<12} {'Status'}")
            print("-" * 85)
            for t in terminals:
                coords = f"{t['latitude']:.4f}°N, {t['longitude']:.4f}°E"
                c_status = GREEN if t["status"] == "ONLINE" else RED
                print(f"ATM-{t['atm_id']:02d}   {t['city']:<12} {t['location_description']:<24} {coords:<24} ₹{t['current_cash_level']:<11,.2f} {c_status}{t['status']}{RESET}")

        elif choice in ["3", "4", "5"]:
            # Quick CLI simulation
            attack_types = {"3": "IMPOSSIBLE_TRAVEL", "4": "FREQUENCY_BURST", "5": "OUTLIER_AMOUNT"}
            atk = attack_types[choice]
            print(f"\n{YELLOW}Triggering simulation: {atk}...{RESET}")
            try:
                from app import app
                client = app.test_client()
                res = client.post("/api/fraud/simulate", json={"attack_type": atk, "card_id": 2})
                resp_json = res.get_json()
                if resp_json.get("success"):
                    print(f"{RED}{BOLD}🚨 [ALERT TRIGGERED]{RESET} {resp_json['message']}")
                    print(f"Forensics: {resp_json['details'].get('details')}")
                else:
                    print(f"{YELLOW}{resp_json.get('message')}{RESET}")
            except Exception as e:
                print(f"{RED}Simulation error: {e}{RESET}")

        elif choice == "0":
            break

def main():
    conn = get_db()
    banner()

    while True:
        card = authenticate_card(conn)
        if not card:
            continue

        while True:
            print(f"\n{BOLD}═══════════════════════════════════════════════════")
            print(f"  🏧 MAIN ATM MENU  |  {card['first_name']} {card['last_name']} ({card['account_type']})")
            print(f"  📍 Location: {CYAN}ATM-{CURRENT_ATM['id']:02d} ({CURRENT_ATM['city']} - {CURRENT_ATM['loc']}){RESET}")
            print(f"═══════════════════════════════════════════════════{RESET}")
            print("  [1] 💰 Check Balance")
            print("  [2] 💵 Withdraw Cash")
            print("  [3] 📥 Deposit Cash")
            print("  [4] 🔄 Inter-Account Fund Transfer")
            print("  [5] 📜 Mini-Statement")
            print("  [6] 🔑 Change PIN")
            print("  [T] 📍 Switch Physical ATM Terminal Location")
            print("  [0] ⏏️  Eject Card / Exit")

            choice = input(f"\n{BOLD}Enter option (0-6, T) > {RESET}").strip()

            if choice == "1":
                check_balance(conn, card)
            elif choice == "2":
                withdraw_cash(conn, card)
            elif choice == "3":
                deposit_cash(conn, card)
            elif choice == "4":
                transfer_funds(conn, card)
            elif choice == "5":
                mini_statement(conn, card)
            elif choice == "6":
                change_pin(conn, card)
            elif choice.upper() == "T":
                switch_atm_terminal(conn)
            elif choice == "0":
                print(f"\n{GREEN}⏏️  Card ejected. Please take your card. Thank you!{RESET}\n")
                break
            else:
                print(f"{RED}Invalid option. Please choose between 0 and 6.{RESET}")

if __name__ == "__main__":
    main()

