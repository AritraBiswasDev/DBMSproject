-- ============================================================================
-- Simple ATM Management System - Review 1
-- Script 03: DML Operations - INSERT Seed Data
-- ============================================================================
-- Populates the normalized database with realistic sample banking data
-- representing customers, accounts, cards, ATMs, and historical transactions.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Insert Customers
-- ----------------------------------------------------------------------------
INSERT INTO customers (customer_id, first_name, last_name, email, phone_number, date_of_birth, street_address, city, state, postal_code, kyc_status, created_at)
VALUES
(1, 'Aarav', 'Sharma', 'aarav.sharma@email.com', '98201-00101', '1985-04-12', '124 MG Road, Fort', 'Mumbai', 'MH', '400001', 'VERIFIED', '2023-01-15 09:30:00'),
(2, 'Priya', 'Patel', 'priya.patel@email.com', '98201-00102', '1992-08-23', '456 Linking Road, Bandra', 'Mumbai', 'MH', '400050', 'VERIFIED', '2023-02-20 11:15:00'),
(3, 'Rohan', 'Verma', 'rohan.verma@email.com', '98111-00103', '1978-11-05', '789 Connaught Place', 'New Delhi', 'DL', '110001', 'VERIFIED', '2023-03-10 14:00:00'),
(4, 'Ananya', 'Iyer', 'ananya.iyer@email.com', '98450-00104', '1995-02-17', '321 Brigade Road', 'Bengaluru', 'KA', '560025', 'VERIFIED', '2023-04-05 10:20:00'),
(5, 'Vikram', 'Malhotra', 'vikram.m@email.com', '98300-00105', '1980-06-30', '654 Park Street', 'Kolkata', 'WB', '700016', 'VERIFIED', '2023-05-12 16:45:00'),
(6, 'Sneha', 'Kulkarni', 'sneha.k@email.com', '98220-00106', '1999-12-14', '987 FC Road, Deccan', 'Pune', 'MH', '411004', 'PENDING', '2023-06-18 13:10:00'),
(7, 'Rajesh', 'Kumar', 'rajesh.kumar@email.com', '98400-00107', '1965-09-08', '159 Anna Salai', 'Chennai', 'TN', '600002', 'VERIFIED', '2023-07-22 08:50:00'),
(8, 'Pooja', 'Gupta', 'pooja.gupta@email.com', '98490-00108', '1990-03-25', '753 Banjara Hills', 'Hyderabad', 'TS', '500034', 'VERIFIED', '2023-08-14 15:30:00'),
(9, 'Amit', 'Singh', 'amit.singh@email.com', '98290-00109', '1987-07-19', '852 MI Road', 'Jaipur', 'RJ', '302001', 'REJECTED', '2023-09-01 12:00:00'),
(10, 'Kavita', 'Reddy', 'kavita.reddy@email.com', '98480-00110', '2001-05-10', '951 Jubilee Hills', 'Hyderabad', 'TS', '500033', 'VERIFIED', '2023-10-10 17:25:00');

-- ----------------------------------------------------------------------------
-- 2. Insert Accounts (Categorized by CHECKING or SAVINGS)
-- ----------------------------------------------------------------------------
INSERT INTO accounts (account_id, customer_id, account_number, account_type, balance, minimum_balance, currency, status, opened_date, created_at)
VALUES
(101, 1, 'ACC-MUM-100101', 'CHECKING', 3450.50, 50.00, 'INR', 'ACTIVE', '2023-01-15', '2023-01-15 10:00:00'),
(102, 1, 'ACC-MUM-100102', 'SAVINGS',  12800.00, 100.00, 'INR', 'ACTIVE', '2023-01-16', '2023-01-16 11:00:00'),
(103, 2, 'ACC-MUM-100201', 'CHECKING', 1850.75, 50.00, 'INR', 'ACTIVE', '2023-02-20', '2023-02-20 11:30:00'),
(104, 3, 'ACC-DEL-100301', 'CHECKING', 7200.00, 50.00, 'INR', 'ACTIVE', '2023-03-10', '2023-03-10 14:15:00'),
(105, 3, 'ACC-DEL-100302', 'SAVINGS',  24500.25, 200.00, 'INR', 'ACTIVE', '2023-03-12', '2023-03-12 09:45:00'),
(106, 4, 'ACC-BLR-100401', 'CHECKING', 920.00, 50.00, 'INR', 'ACTIVE', '2023-04-05', '2023-04-05 10:45:00'),
(107, 5, 'ACC-KOL-100501', 'CHECKING', 4150.80, 50.00, 'INR', 'ACTIVE', '2023-05-12', '2023-05-12 17:00:00'),
(108, 5, 'ACC-KOL-100502', 'SAVINGS',  8900.00, 100.00, 'INR', 'ACTIVE', '2023-05-15', '2023-05-15 14:00:00'),
(109, 6, 'ACC-PUN-100601', 'CHECKING', 250.00, 50.00, 'INR', 'DORMANT', '2023-06-18', '2023-06-18 13:30:00'),
(110, 7, 'ACC-CHE-100701', 'SAVINGS',  45200.00, 500.00, 'INR', 'ACTIVE', '2023-07-22', '2023-07-22 09:15:00'),
(111, 8, 'ACC-HYD-100801', 'CHECKING', 3120.40, 50.00, 'INR', 'ACTIVE', '2023-08-14', '2023-08-14 16:00:00'),
(112, 10, 'ACC-HYD-101001', 'CHECKING', 145.00, 50.00, 'INR', 'FROZEN', '2023-10-10', '2023-10-10 17:45:00');

-- ----------------------------------------------------------------------------
-- 3. Insert Cards (Linked to specific accounts)
-- ----------------------------------------------------------------------------
INSERT INTO cards (card_id, account_id, card_number, card_type, pin_hash, cvv, expiry_date, daily_withdrawal_limit, status, failed_pin_attempts, issued_date)
VALUES
(501, 101, '4532789012345678', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '382', '2027-12-31', 1000.00, 'ACTIVE', 0, '2023-01-15'),
(502, 102, '4532789012345679', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '719', '2027-12-31', 1500.00, 'ACTIVE', 0, '2023-01-16'),
(503, 103, '4532789012345680', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '521', '2028-02-28', 800.00,  'ACTIVE', 0, '2023-02-20'),
(504, 104, '4532789012345681', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '194', '2028-03-31', 2000.00, 'ACTIVE', 0, '2023-03-10'),
(505, 106, '4532789012345682', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '837', '2026-04-30', 500.00,  'ACTIVE', 0, '2023-04-05'),
(506, 107, '4532789012345683', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '412', '2028-05-31', 1200.00, 'ACTIVE', 0, '2023-05-12'),
(507, 109, '4532789012345684', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '603', '2024-06-30', 500.00,  'EXPIRED', 0, '2021-06-18'),
(508, 110, '4532789012345685', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '945', '2028-07-31', 3000.00, 'ACTIVE', 0, '2023-07-22'),
(509, 111, '4532789012345686', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '276', '2028-08-31', 1000.00, 'ACTIVE', 0, '2023-08-14'),
(510, 112, '4532789012345687', 'DEBIT', '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4', '789', '2028-10-31', 500.00,  'BLOCKED', 3, '2023-10-10');

-- ----------------------------------------------------------------------------
-- 4. Insert ATM Machines (with Geolocation Coordinates & Cash Inventory Rules)
-- ----------------------------------------------------------------------------
INSERT INTO atm_machines (atm_id, terminal_code, branch_name, location_address, city, latitude, longitude, cash_capacity, current_cash_level, min_threshold_level, daily_burn_rate, status, last_serviced_date)
VALUES
(1, 'ATM-MUM-01', 'Nariman Point Flagship', '100 Marine Drive',        'Mumbai',    18.9256, 72.8242, 75000.00, 48200.00, 20000.00, 12000.00, 'ONLINE',      '2024-02-01'),
(2, 'ATM-DEL-01', 'Connaught Place Hub',   'Block A, Connaught Place','New Delhi', 28.6315, 77.2167, 80000.00, 31400.00, 25000.00, 15000.00, 'ONLINE',      '2024-02-05'),
(3, 'ATM-BLR-01', 'MG Road Branch',        '500 MG Road',              'Bengaluru', 12.9756, 77.6066, 60000.00, 52000.00, 15000.00,  8000.00, 'ONLINE',      '2024-01-28'),
(4, 'ATM-KOL-01', 'Park Street Branch',     '230 Park Street',          'Kolkata',   22.5512, 88.3526, 65000.00, 21900.00, 20000.00, 11000.00, 'ONLINE',      '2024-02-10'),
(5, 'ATM-HYD-01', 'Banjara Hills Branch',   'Road No. 1, Banjara Hills','Hyderabad', 17.4156, 78.4357, 50000.00, 12500.00, 15000.00,  9000.00, 'ONLINE',      '2024-02-11'),
(6, 'ATM-CHE-01', 'Anna Salai Terminal',    '102 Anna Salai',           'Chennai',   13.0604, 80.2496, 50000.00, 45000.00, 15000.00,  6000.00, 'ONLINE',      '2024-01-15'),
(7, 'ATM-PUN-01', 'FC Road Terminal',       '700 FC Road',              'Pune',      18.5204, 73.8418, 40000.00,  1500.00, 12000.00,  7000.00, 'OUT_OF_CASH', '2024-02-12'),
(8, 'ATM-AMD-01', 'SG Highway Branch',      '1111 SG Highway',          'Ahmedabad', 23.0338, 72.5073, 70000.00,     0.00, 20000.00,  8000.00, 'MAINTENANCE', '2024-02-08');

-- ----------------------------------------------------------------------------
-- 5. Insert Transactions (Ledger of Deposits, Withdrawals, Transfers & Inquiries)
-- ----------------------------------------------------------------------------
INSERT INTO transactions (transaction_id, account_id, dest_account_id, atm_id, transaction_type, amount, balance_after, status, description, prev_hash, entry_hash, transaction_timestamp)
VALUES
(1001, 101, NULL,    1, 'DEPOSIT', 1000.00,  4450.50, 'SUCCESS', 'Cash deposit at ATM Nariman Point Flagship', '0000000000000000000000000000000000000000000000000000000000000000', 'a1fc47f05f0259d4d7921467684465d1005c64898e030afed752c031769d908b', '2024-01-05 10:15:22'),
(1002, 101, NULL,    1, 'WITHDRAWAL',  200.00,  4250.50, 'SUCCESS', 'Cash withdrawal at ATM Nariman Point Flagship', 'a1fc47f05f0259d4d7921467684465d1005c64898e030afed752c031769d908b', '7dfa22f0d8cfc1f5b48dc72998de9916e7547b6879cf3efdd5f4b4bf17835b7a', '2024-01-08 14:22:10'),
(1003, 101,  102, NULL, 'TRANSFER',  800.00,  3450.50, 'SUCCESS', 'Online transfer from Checking to Savings', '7dfa22f0d8cfc1f5b48dc72998de9916e7547b6879cf3efdd5f4b4bf17835b7a', '768bd78b7ccfb900ea034a87c8eadcdca72d2db25a99ff6850140c00868df187', '2024-01-10 18:30:00'),
(1004, 103, NULL,    2, 'WITHDRAWAL',  300.00,  1550.75, 'SUCCESS', 'Cash withdrawal at Connaught Place Hub', '768bd78b7ccfb900ea034a87c8eadcdca72d2db25a99ff6850140c00868df187', '77ddfae97cfee39f2514313edc7c48e991a97a8089c46308f4f82affd171aa38', '2024-01-12 11:45:18'),
(1005, 103, NULL,    2, 'DEPOSIT',  300.00,  1850.75, 'SUCCESS', 'Cash deposit via ATM deposit chute', '77ddfae97cfee39f2514313edc7c48e991a97a8089c46308f4f82affd171aa38', '7aba1835339075d95efa72ba55e88b2ee4d0e3313811ab99c33513c33e07d625', '2024-01-15 16:10:05'),
(1006, 104, NULL,    3, 'WITHDRAWAL',  500.00,  6700.00, 'SUCCESS', 'Cash withdrawal at MG Road Branch', '7aba1835339075d95efa72ba55e88b2ee4d0e3313811ab99c33513c33e07d625', 'fb93e75c6cebb645553a72b67f84558845cf8a60e0b6b3a42e2936c16e0fbc60', '2024-01-18 09:20:44'),
(1007, 104, NULL,    3, 'DEPOSIT',  500.00,  7200.00, 'SUCCESS', 'Cash deposit at Bengaluru ATM', 'fb93e75c6cebb645553a72b67f84558845cf8a60e0b6b3a42e2936c16e0fbc60', '342b1bf6416c36a3390baba72baaa77d7c224d95916d617b8d6924985b888dca', '2024-01-20 13:05:30'),
(1008, 105, NULL,    3, 'BALANCE_INQUIRY',    0.00, 24500.25, 'SUCCESS', 'Balance inquiry at MG Road ATM', '342b1bf6416c36a3390baba72baaa77d7c224d95916d617b8d6924985b888dca', '00ae08c4af98f1e0252d96a3c15f5dada9e26f80039573b4b3bc364aa6660bad', '2024-01-22 17:40:12'),
(1009, 106, NULL,    4, 'WITHDRAWAL',  100.00,   820.00, 'SUCCESS', 'Cash withdrawal at Kolkata Park Street', '00ae08c4af98f1e0252d96a3c15f5dada9e26f80039573b4b3bc364aa6660bad', '172539c4b90651a68694c2a3a979336571507e5721184784b1f08b9445ba0b74', '2024-01-25 12:15:55'),
(1010, 106, NULL,    4, 'DEPOSIT',  100.00,   920.00, 'SUCCESS', 'Cash deposit at Kolkata ATM', '172539c4b90651a68694c2a3a979336571507e5721184784b1f08b9445ba0b74', 'd1dc92ca3eafc96635a28eed3ecf35e49a887f1dea10b03985047abfc5e2dd68', '2024-01-28 15:50:33'),
(1011, 107, NULL,    5, 'WITHDRAWAL',  400.00,  3750.80, 'SUCCESS', 'Cash withdrawal at Banjara Hills', 'd1dc92ca3eafc96635a28eed3ecf35e49a887f1dea10b03985047abfc5e2dd68', 'bd4ea3d7c8ce105d89d1c7517bf9d710a674973cfa8468b5a932ef2f055a1195', '2024-02-01 08:35:10'),
(1012, 107, NULL,    5, 'DEPOSIT',  400.00,  4150.80, 'SUCCESS', 'Cash deposit at Hyderabad ATM', 'bd4ea3d7c8ce105d89d1c7517bf9d710a674973cfa8468b5a932ef2f055a1195', '06fd55b448a484deda780d943f2ee2ea41771b2d0324191704bc2f9716dd7de8', '2024-02-03 14:48:22'),
(1013, 108, NULL,    5, 'BALANCE_INQUIRY',    0.00,  8900.00, 'SUCCESS', 'Balance inquiry at Hyderabad ATM', '06fd55b448a484deda780d943f2ee2ea41771b2d0324191704bc2f9716dd7de8', 'f5621057a7902035e4b3dd50c2ea61c3dffe33d1277fc0492ee6c5aa472aea2d', '2024-02-04 19:12:00'),
(1014, 110, NULL,    6, 'DEPOSIT', 2000.00, 45200.00, 'SUCCESS', 'Direct cash deposit at Anna Salai ATM', 'f5621057a7902035e4b3dd50c2ea61c3dffe33d1277fc0492ee6c5aa472aea2d', 'a3bac79eb00de215582ca7f58c6a9ae83678ae8ed10f7a2430d7e5e883b98c1e', '2024-02-06 11:02:40'),
(1015, 111, NULL,    7, 'WITHDRAWAL',  150.00,  2970.40, 'SUCCESS', 'Cash withdrawal at FC Road Terminal', 'a3bac79eb00de215582ca7f58c6a9ae83678ae8ed10f7a2430d7e5e883b98c1e', '9e13508fb4b02649ea036b18497192f13ef6d8f6be0149e8f147a5505d8a66ee', '2024-02-08 16:25:19'),
(1016, 111, NULL,    7, 'DEPOSIT',  150.00,  3120.40, 'SUCCESS', 'Check deposit envelope at Pune ATM', '9e13508fb4b02649ea036b18497192f13ef6d8f6be0149e8f147a5505d8a66ee', 'c193a4dd9cc9ed536c4444bf84f1493c90f357317f489d8cfc9a513663f34732', '2024-02-09 10:14:50'),
(1017, 101,  103, NULL, 'TRANSFER',  250.00,  3200.50, 'SUCCESS', 'Inter-account transfer to Priya Patel', 'c193a4dd9cc9ed536c4444bf84f1493c90f357317f489d8cfc9a513663f34732', 'd984d74ab45b59948296e4ecb05c3e84c4aee879223a5beef2684d16c66688fe', '2024-02-10 12:00:00'),
(1018, 103,  101, NULL, 'TRANSFER',  250.00,  1850.75, 'SUCCESS', 'Transfer reimbursement received', 'd984d74ab45b59948296e4ecb05c3e84c4aee879223a5beef2684d16c66688fe', '2d560f206a2e328f32a0dd075878fc7a25ab78a15140c0f47e9507cbdf182953', '2024-02-10 12:05:00'),
(1019, 106, NULL,    4, 'WITHDRAWAL', 1500.00,   920.00, 'FAILED', 'Declined: Amount exceeds card daily limit', '2d560f206a2e328f32a0dd075878fc7a25ab78a15140c0f47e9507cbdf182953', 'fdaf71ba2ef74c56099a78ec2c433d287b8293624eac88db686866161565908c', '2024-02-11 14:10:00'),
(1020, 112, NULL,    1, 'WITHDRAWAL',  200.00,   145.00, 'FAILED', 'Declined: Account is FROZEN & exceeded PIN', 'fdaf71ba2ef74c56099a78ec2c433d287b8293624eac88db686866161565908c', '1c58d67d6622b44b09dd628f07d469ff0bb85a153e3d1593e6cd8f014429891b', '2024-02-12 09:05:15'),
(1021, 101, NULL,    1, 'WITHDRAWAL',  800.00,  2400.50, 'SUCCESS', 'Cash withdrawal at Mumbai Flagship', '1c58d67d6622b44b09dd628f07d469ff0bb85a153e3d1593e6cd8f014429891b', '9eb47ace3a5f7b77bbfe8eaa2a17b8608e65204a5c6fe1f02bfab754a3306cc3', '2024-02-09 11:20:00'),
(1022, 102, NULL,    1, 'WITHDRAWAL',  500.00, 14750.00, 'SUCCESS', 'Cash withdrawal at Mumbai Flagship', '9eb47ace3a5f7b77bbfe8eaa2a17b8608e65204a5c6fe1f02bfab754a3306cc3', '0a27557e9c7a589bf3934aa8dc9632324f58f02b185a0f55f6135aa0852ddf8f', '2024-02-10 15:45:00'),
(1023, 104, NULL,    1, 'WITHDRAWAL', 1200.00,  5500.00, 'SUCCESS', 'Cash withdrawal at Mumbai Flagship', '0a27557e9c7a589bf3934aa8dc9632324f58f02b185a0f55f6135aa0852ddf8f', '7ab33e080a7d5657aff3164240ea37e313a728e872aa00605cc9e24b57eab99e', '2024-02-11 18:10:00'),
(1024, 103, NULL,    2, 'WITHDRAWAL',  600.00,  1250.75, 'SUCCESS', 'Cash withdrawal at Connaught Place Hub', '7ab33e080a7d5657aff3164240ea37e313a728e872aa00605cc9e24b57eab99e', 'cf576f1fa13116229d21e0f699e5e57c99258d40e61301ecb2bdf3fd3fcd3103', '2024-02-08 14:30:00'),
(1025, 105, NULL,    2, 'WITHDRAWAL', 1500.00, 23000.25, 'SUCCESS', 'Cash withdrawal at Connaught Place Hub', 'cf576f1fa13116229d21e0f699e5e57c99258d40e61301ecb2bdf3fd3fcd3103', '30d9181dec6e0c7124fe11645916825d3865c940ab430e8edcc3eb852430de0d', '2024-02-09 16:15:00'),
(1026, 107, NULL,    2, 'WITHDRAWAL',  900.00,  3250.80, 'SUCCESS', 'Cash withdrawal at Connaught Place Hub', '30d9181dec6e0c7124fe11645916825d3865c940ab430e8edcc3eb852430de0d', 'a143a13915e84ef4a1052a0621748ac89f66320c890651c740006375a291b9fe', '2024-02-11 10:40:00'),
(1027, 108, NULL,    3, 'WITHDRAWAL',  400.00,  8500.00, 'SUCCESS', 'Cash withdrawal at Bengaluru MG Road', 'a143a13915e84ef4a1052a0621748ac89f66320c890651c740006375a291b9fe', 'a87afebee9c1a8c06a7f6624bf8d8e6155a2a5e17903fd0a82924ddc8dacc224', '2024-02-08 09:15:00'),
(1028, 110, NULL,    3, 'WITHDRAWAL', 1000.00, 44200.00, 'SUCCESS', 'Cash withdrawal at Bengaluru MG Road', 'a87afebee9c1a8c06a7f6624bf8d8e6155a2a5e17903fd0a82924ddc8dacc224', '2cf28eb9d0d69aa4dabdb68be3027241b706ee2d1af961ae0fed8bf2ef16c2e9', '2024-02-10 13:20:00'),
(1029, 111, NULL,    4, 'WITHDRAWAL',  300.00,  2670.40, 'SUCCESS', 'Cash withdrawal at Kolkata Park Street', '2cf28eb9d0d69aa4dabdb68be3027241b706ee2d1af961ae0fed8bf2ef16c2e9', 'c5479d03aee8b03e22077dc9d63a5dd2fea7ca6ac74d3736f2429c7d2dceb589', '2024-02-09 17:05:00'),
(1030, 106, NULL,    4, 'WITHDRAWAL',  200.00,   720.00, 'SUCCESS', 'Cash withdrawal at Kolkata Park Street', 'c5479d03aee8b03e22077dc9d63a5dd2fea7ca6ac74d3736f2429c7d2dceb589', 'af742600d6649850f8cc09e215a2f6b906947cb8c630832f192d639ccf90d655', '2024-02-10 12:40:00'),
(1031, 107, NULL,    5, 'WITHDRAWAL',  500.00,  2750.80, 'SUCCESS', 'Cash withdrawal at Hyderabad Banjara Hills', 'af742600d6649850f8cc09e215a2f6b906947cb8c630832f192d639ccf90d655', '5b56372f6c3867e5d21bb809079862ee622b3908920f3b7be58a49f902d61cd9', '2024-02-09 11:50:00'),
(1032, 108, NULL,    5, 'WITHDRAWAL',  700.00,  7800.00, 'SUCCESS', 'Cash withdrawal at Hyderabad Banjara Hills', '5b56372f6c3867e5d21bb809079862ee622b3908920f3b7be58a49f902d61cd9', '1a73cfcd79b57a5255bc303b85a256f333e54522542149248cf62e9f34008f7a', '2024-02-10 16:35:00');

-- ----------------------------------------------------------------------------
-- 6. Insert Fraud Alerts (Historical Security & Impossible Travel Incidents)
-- ----------------------------------------------------------------------------
INSERT INTO fraud_alerts (alert_id, transaction_id, card_id, account_id, alert_type, severity, risk_score, prev_atm_id, current_atm_id, distance_km, time_delta_minutes, implied_speed_kmh, action_taken, details, alert_timestamp)
VALUES
(1, 1020, 510, 112, 'GEO_VELOCITY_IMPOSSIBLE_TRAVEL', 'CRITICAL', 98, 5, 1, 620.00, 15.00, 2480.00, 'CARD_AUTO_LOCKED', 'Impossible transit: Card swiped at Hyderabad ATM then 15 mins later at Mumbai ATM (speed: 2,480 km/h). Auto-locked.', '2024-02-12 09:05:15'),
(2, NULL, 505, 106, 'RAPID_FREQUENCY_BURST', 'HIGH', 82, 4, 4, 0.00, 1.50, 0.00, 'TRANSACTION_BLOCKED', 'Rapid withdrawal burst: 3 consecutive max-limit attempts within 90 seconds at Kolkata Park Street.', '2024-02-11 14:10:00');

-- ----------------------------------------------------------------------------
-- 7. Insert Cash Replenishments (Predictive Logistics & CIT Armored Van Orders)
-- ----------------------------------------------------------------------------
INSERT INTO cash_replenishments (replenishment_id, atm_id, requested_amount, current_cash_at_request, burn_rate_at_request, estimated_days_left, urgency_level, status, cit_company, van_vehicle_number, dispatched_at, completed_at, created_at)
VALUES
(1, 7, 38500.00,  1500.00,  7000.00, 0.21, 'CRITICAL_STOCKOUT', 'IN_TRANSIT', 'SIS Prosegur Cash Logistics', 'MH-12-CV-4412', '2024-02-12 10:15:00', NULL,                  '2024-02-12 10:00:00'),
(2, 5, 37500.00, 12500.00,  9000.00, 1.39, 'HIGH',              'DISPATCHED', 'CMS Info Systems CIT',        'TS-09-UB-8891', '2024-02-12 11:30:00', NULL,                  '2024-02-12 11:15:00'),
(3, 1, 50000.00, 18000.00, 12000.00, 1.50, 'NORMAL',            'COMPLETED',  'SecureCorp India CIT',        'MH-01-CV-7890', '2024-02-01 07:00:00', '2024-02-01 09:30:00', '2024-02-01 06:45:00');

