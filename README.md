# RedFlag — Fraud Detection

## Project Description

**RedFlag** is a MySQL-based fraud detection project that analyzes the PayFast synthetic transaction dataset from January to June 2024 to identify suspicious user, transaction, and merchant behavior. The project uses SQL aggregation, filtering, conditional logic, subqueries, window functions, date/time analysis, and merchant-level comparisons to detect multiple fraud signatures such as unusually high transaction velocity, round-amount clustering, card testing, failed-then-succeeded retries, odd-hour activity, mule-account behavior, refund abuse, merchant collusion, threshold avoidance, dormant-account reactivation, velocity spikes, and geographically impossible transactions. The supplied dataset contains **200,594 transactions**, **14,755 distinct users**, and **800 distinct merchants**, covering transactions from **2024-01-01 to 2024-06-28**.

## Query Result Screenshots

### 1. Round-Amount Clustering
![Round Amount Clustering](screenshots/query_result_1.png)

### 2. Card Testing
![Card Testing](screenshots/query_result_2.png)

### 3. Failed-Then-Succeeded
![Failed Then Succeeded](screenshots/query_result_3.png)

### 4. Odd-Hour Concentration
![Odd Hour Concentration](screenshots/query_result_4.png)

### 5. Mule Accounts
![Mule Accounts](screenshots/query_result_5.png)

### 6. Refund Abuse
![Refund Abuse](screenshots/query_result_6.png)

## Patterns Detected

1. **Velocity Fraud** — 30 or more transactions by a user on one calendar day.
2. **Round-Amount Clustering** — 15 or more transactions at exact round amounts.
3. **Card Testing** — 30 or more transactions below Rs 10 on one day.
4. **Failed-Then-Succeeded** — repeated FAILED transactions followed within two minutes by a SUCCESS transaction for the same amount.
5. **Odd-Hour Concentration** — at least 30 transactions with 80% or more occurring between 02:00 and 04:59.
6. **Mule Accounts** — repeated CREDIT transactions followed within 30 minutes by a DEBIT worth at least 70% of the credit amount.
7. **Refund Abuse** — users with at least 20 transactions where more than 40% are REFUND transactions.
8. **Merchant Collusion** — merchants where the top five users contribute more than 60% of total transaction value.
9. **Just-Under-Threshold / Structuring** — at least 10 transactions at exactly Rs 9,999.
10. **Dormant-Then-Active** — a 90+ day transaction gap followed by at least 15 transactions.
11. **Velocity Spike** — a user's peak monthly transaction count is at least five times their six-month average, with a peak of at least 20 transactions.
12. **Geographic Impossibility** — consecutive transactions in different cities within 60 minutes.

## Final Detection Summary

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

## Tech Stack

- **Database:** MySQL 8.x
- **Language:** SQL
- **Dataset:** PayFast synthetic transactions, January–June 2024
- **Core SQL techniques:** `GROUP BY`, `HAVING`, `CASE`, `EXISTS`, correlated subqueries, `TIMESTAMPDIFF`, date/time functions, CTEs, `LAG()`, `ROW_NUMBER()`, aggregations, and window functions.

## Dataset Verification

- **Transactions:** 200,594
- **Distinct users:** 14,755
- **Distinct merchants:** 800
- **Earliest transaction:** 2024-01-01 00:05:26
- **Latest transaction:** 2024-06-28 23:59:20

## Project Files

- `README.md` — project documentation and query-result screenshots
- `screenshots/` — screenshots of the SQL query results
- `RedFlag_Abhishek_Kumar.sql` — final fraud detection queries

## How to Use

1. Create/load the `redflag` database and transaction dataset.
2. Run the SQL file in **MySQL 8.x**.
3. Review the output of the 12 fraud-detection queries.
4. Compare the detected users, merchants, and suspicious transaction patterns with the project findings.
