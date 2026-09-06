# 🚩 RedFlag — Fraud Detection

## 📌 Project Description

**RedFlag** is a MySQL-based fraud detection project that analyzes the PayFast synthetic transaction dataset from January to June 2024 to identify suspicious user, transaction, and merchant behavior. The project uses advanced SQL techniques such as aggregation, filtering, conditional logic, subqueries, CTEs, date/time analysis, and window functions to detect **12 different fraud patterns**, helping transform raw transaction data into actionable fraud indicators.

## 📊 Dataset

- **Transactions:** 200,594
- **Distinct users:** 14,755
- **Distinct merchants:** 800
- **Period:** January–June 2024
- **Database:** MySQL 8.x
- **Dataset:** PayFast synthetic transactions

## 🔎 Fraud Patterns Detected

1. **Velocity Fraud** — 30 or more transactions by a user on one calendar day.
2. **Round-Amount Clustering** — repeated transactions at exact round amounts.
3. **Card Testing** — 30 or more transactions below Rs 10 on one day.
4. **Failed-Then-Succeeded** — failed transactions followed within two minutes by a successful transaction for the same amount.
5. **Odd-Hour Concentration** — high transaction concentration between 02:00 and 04:59.
6. **Mule Accounts** — rapid movement of suspicious incoming credit funds to debit transactions.
7. **Refund Abuse** — unusually high proportion of refund transactions.
8. **Merchant Collusion** — excessive transaction value concentrated among a merchant's top users.
9. **Just-Under-Threshold / Structuring** — repeated transactions at exactly Rs 9,999.
10. **Dormant-Then-Active** — suspicious activity following a 90+ day transaction gap.
11. **Velocity Spike** — unusually large monthly transaction spikes compared with historical activity.
12. **Geographic Impossibility** — transactions in different cities within an implausibly short time.

## 🖼️ Query Result Screenshots

### 1. Round-Amount Clustering

![Round Amount Clustering](screenshots/round_amount_clustering.png)

### 2. Card Testing

![Card Testing](screenshots/card_testing.png)

### 3. Failed-Then-Succeeded

![Failed Then Succeeded](screenshots/failed_then_succeeded.png)

### 4. Odd-Hour Concentration

![Odd Hour Concentration](screenshots/odd_hour_concentration.png)

### 5. Mule Accounts

![Mule Accounts](screenshots/mule_accounts.png)

### 6. Refund Abuse

![Refund Abuse](screenshots/refund_abuse.png)

## 📈 Final Detection Summary

| Pattern | Suspect Results |
|---|---:|
| Velocity Fraud | 50 suspect user-days |
| Round-Amount Clustering | 25 suspect users |
| Card Testing | 20 suspect user-days |
| Failed-Then-Succeeded | 25 suspect users |
| Odd-Hour Concentration | 20 suspect users |
| Mule Accounts | 30 suspect users |
| Refund Abuse | 24 suspect users |
| Merchant Collusion | 15 suspect merchants |
| Just-Under-Threshold | 20 suspect users |
| Dormant-Then-Active | 26 suspect cases |
| Velocity Spike | 45 suspect users |
| Geographic Impossibility | 15 suspect users |

## 🛠️ Tech Stack

- **MySQL 8.x**
- **SQL**
- CTEs
- Window Functions
- Aggregations
- Date & Time Functions
- Conditional Logic
- Subqueries
- Transaction-level fraud analysis

## 📁 Project Structure

```text
RedFlag/
│
├── RedFlag_Abhishek_Kumar.sql
├── README.md
│
└── screenshots/
    ├── round_amount_clustering.png
    ├── card_testing.png
    ├── failed_then_succeeded.png
    ├── odd_hour_concentration.png
    ├── mule_accounts.png
    └── refund_abuse.png
```

## ▶️ How to Run

1. Open **MySQL 8.x / MySQL Workbench**.
2. Create or load the `redflag` database and transaction dataset.
3. Open `RedFlag_Abhishek_Kumar.sql`.
4. Execute the queries.
5. Review the result grids for the detected fraud patterns.

## 🎯 Objective

The objective of RedFlag is to demonstrate how SQL and data analytics can be used to identify suspicious financial transaction behavior and support fraud investigation through rule-based detection patterns.
