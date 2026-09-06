-- =====================================================================
-- RedFlag — Fraud Detection Submission
-- Student: Abhishek Kumar | Batch: DA-DS-1
-- Project: Minor Project 3 — The Fraud Files
-- Database: MySQL 8.x
-- Dataset: PayFast synthetic transactions, Jan-Jun 2024
-- =====================================================================
-- IMPORTANT:
-- 1. Run redflag_transactions.sql first.
-- 2. This submission file contains only the final detection queries.
-- 3. The findings below were checked against the supplied dataset.
-- =====================================================================

USE redflag;


-- =====================================================================
-- PATTERN 1 · VELOCITY FRAUD
-- What I'm looking for:
-- A user making 30 or more transactions on one calendar day.
-- This can indicate automation, account takeover, or transaction churning.
-- Expected result: about 45-55 suspect user-days.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS daily_txn_count
FROM transactions
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_txn_count DESC, user_id;

-- =====================================================================
-- PATTERN 2 · ROUND-AMOUNT CLUSTERING
-- What I'm looking for:
-- Users making 15 or more transactions at exact round amounts commonly
-- associated with laundering/structuring behaviour.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS round_amount_txns,
    SUM(amount) AS round_amount_value
FROM transactions
WHERE amount IN (100.00, 200.00, 500.00, 1000.00, 2000.00, 5000.00, 10000.00)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_txns DESC, user_id;

-- =====================================================================
-- PATTERN 3 · CARD TESTING
-- What I'm looking for:
-- A user making 30 or more transactions below Rs 10 on one day.
-- Concentrated tiny payments are a common card-testing signature.
-- =====================================================================

SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS tiny_txn_count
FROM transactions
WHERE amount < 10.00
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_txn_count DESC, user_id;

-- FINDINGS:
-- 20 suspect user-days were flagged.
-- Examples:
-- user 14556 -> 60 tiny transactions on 2024-05-28
-- user 14569 -> 60 tiny transactions on 2024-04-03
-- user 14566 -> 59 tiny transactions on 2024-03-15
-- =====================================================================


-- =====================================================================
-- PATTERN 4 · FAILED-THEN-SUCCEEDED
-- Tier 1 | 6 marks
-- What I'm looking for:
-- Users with repeated FAILED transactions that are followed within two
-- minutes by a SUCCESS transaction for the same amount.
-- This is the advanced version of the card-testing retry pattern.
-- =====================================================================

SELECT
    f.user_id,
    COUNT(*) AS failed_success_pairs
FROM transactions AS f
WHERE f.status = 'FAILED'
  AND EXISTS (
      SELECT 1
      FROM transactions AS s
      WHERE s.user_id = f.user_id
        AND s.status = 'SUCCESS'
        AND s.amount = f.amount
        AND s.txn_time > f.txn_time
        AND TIMESTAMPDIFF(SECOND, f.txn_time, s.txn_time) <= 120
  )
GROUP BY f.user_id
HAVING COUNT(*) >= 20
ORDER BY failed_success_pairs DESC, f.user_id;

-- =====================================================================
-- PATTERN 5 · ODD-HOUR CONCENTRATION
-- What I'm looking for:
-- Users with at least 30 transactions where 80% or more occur between
-- 02:00 and 04:59. This can indicate automated overseas fraud activity.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END
    ) AS odd_hour_txns,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS odd_hour_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(
       CASE
           WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
           ELSE 0
       END
   ) / COUNT(*) >= 0.80
ORDER BY odd_hour_percentage DESC, total_txns DESC, user_id;


-- =====================================================================
-- PATTERN 6 · MULE ACCOUNTS
-- What I'm looking for:
-- A user with at least 5 instances where a CREDIT is followed within
-- 30 minutes by a DEBIT worth at least 70% of the credit amount.
-- This models rapid movement of suspicious incoming funds.
-- =====================================================================

SELECT
    c.user_id,
    COUNT(*) AS credit_debit_matches
FROM transactions AS c
WHERE c.txn_type = 'CREDIT'
  AND EXISTS (
      SELECT 1
      FROM transactions AS d
      WHERE d.user_id = c.user_id
        AND d.txn_type = 'DEBIT'
        AND d.txn_time > c.txn_time
        AND TIMESTAMPDIFF(MINUTE, c.txn_time, d.txn_time) <= 30
        AND d.amount >= 0.70 * c.amount
  )
GROUP BY c.user_id
HAVING COUNT(*) >= 5
ORDER BY credit_debit_matches DESC, c.user_id;


-- =====================================================================
-- PATTERN 7 · REFUND ABUSE
-- What I'm looking for:
-- Users with at least 20 transactions and more than 40% of their
-- transactions recorded as REFUND.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS total_txns,
    SUM(
        CASE
            WHEN txn_type = 'REFUND' THEN 1
            ELSE 0
        END
    ) AS refund_txns,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN txn_type = 'REFUND' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS refund_percentage
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(
       CASE
           WHEN txn_type = 'REFUND' THEN 1
           ELSE 0
       END
   ) / COUNT(*) > 0.40
ORDER BY refund_percentage DESC, refund_txns DESC, user_id;


-- =====================================================================
-- PATTERN 8 · MERCHANT COLLUSION
-- What I'm looking for:
-- Merchants where the top five users by transaction value contribute
-- more than 60% of the merchant's total transaction value.
-- =====================================================================

WITH user_merchant_volume AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_volume
    FROM transactions
    GROUP BY merchant_id, user_id
),
ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_volume,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_volume DESC
        ) AS user_rank
    FROM user_merchant_volume
),
top_five AS (
    SELECT
        merchant_id,
        SUM(user_volume) AS top5_volume
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
),
merchant_totals AS (
    SELECT
        merchant_id,
        SUM(amount) AS merchant_volume
    FROM transactions
    GROUP BY merchant_id
)
SELECT
    t.merchant_id,
    t.top5_volume,
    m.merchant_volume,
    ROUND(100.0 * t.top5_volume / m.merchant_volume, 2) AS top5_share_percentage
FROM top_five AS t
JOIN merchant_totals AS m
    ON m.merchant_id = t.merchant_id
WHERE t.top5_volume / m.merchant_volume > 0.60
ORDER BY top5_share_percentage DESC, t.merchant_id;

-- =====================================================================
-- PATTERN 9 · JUST-UNDER-THRESHOLD / STRUCTURING
-- What I'm looking for:
-- Users making at least 10 transactions at exactly Rs 9,999.00.
-- This models deliberate structuring just below the Rs 10,000 threshold.
-- =====================================================================

SELECT
    user_id,
    COUNT(*) AS threshold_avoidance_txns,
    SUM(amount) AS total_structured_value
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_avoidance_txns DESC, user_id;

-- =====================================================================
-- PATTERN 10 · DORMANT-THEN-ACTIVE
-- What I'm looking for:
-- A user with a 90+ day gap between consecutive transactions, followed
-- by at least 15 transactions after the dormant period.
-- =====================================================================

WITH ordered_txns AS (
    SELECT
        txn_id,
        user_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
),
dormant_points AS (
    SELECT
        user_id,
        previous_txn_time,
        txn_time AS reactivation_time
    FROM ordered_txns
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(DAY, previous_txn_time, txn_time) >= 90
),
post_gap_activity AS (
    SELECT
        d.user_id,
        d.previous_txn_time,
        d.reactivation_time,
        COUNT(t.txn_id) AS post_gap_txns
    FROM dormant_points AS d
    JOIN transactions AS t
      ON t.user_id = d.user_id
     AND t.txn_time >= d.reactivation_time
    GROUP BY
        d.user_id,
        d.previous_txn_time,
        d.reactivation_time
)
SELECT
    user_id,
    previous_txn_time,
    reactivation_time,
    post_gap_txns
FROM post_gap_activity
WHERE post_gap_txns >= 15
ORDER BY post_gap_txns DESC, user_id;


-- =====================================================================
-- PATTERN 11 · VELOCITY SPIKE
-- What I'm looking for:
-- A user's peak monthly transaction count is at least five times the
-- six-month average, with a peak of at least 20 transactions.


WITH months AS (
    SELECT '2024-01' AS month_key
    UNION ALL SELECT '2024-02'
    UNION ALL SELECT '2024-03'
    UNION ALL SELECT '2024-04'
    UNION ALL SELECT '2024-05'
    UNION ALL SELECT '2024-06'
),
users AS (
    SELECT DISTINCT user_id
    FROM transactions
),
monthly_counts AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS month_key,
        COUNT(*) AS monthly_txns
    FROM transactions
    GROUP BY user_id, DATE_FORMAT(txn_time, '%Y-%m')
),
six_month_history AS (
    SELECT
        u.user_id,
        m.month_key,
        COALESCE(mc.monthly_txns, 0) AS monthly_txns
    FROM users AS u
    CROSS JOIN months AS m
    LEFT JOIN monthly_counts AS mc
      ON mc.user_id = u.user_id
     AND mc.month_key = m.month_key
),
monthly_profile AS (
    SELECT
        user_id,
        AVG(monthly_txns) AS avg_monthly_txns,
        MAX(monthly_txns) AS peak_monthly_txns,
        SUM(CASE WHEN monthly_txns > 0 THEN 1 ELSE 0 END) AS active_months
    FROM six_month_history
    GROUP BY user_id
)
SELECT
    user_id,
    active_months,
    ROUND(avg_monthly_txns, 2) AS avg_monthly_txns,
    peak_monthly_txns,
    ROUND(peak_monthly_txns / avg_monthly_txns, 2) AS peak_to_average_ratio
FROM monthly_profile
WHERE active_months >= 2
  AND peak_monthly_txns >= 20
  AND peak_monthly_txns / avg_monthly_txns >= 5
ORDER BY peak_to_average_ratio DESC, peak_monthly_txns DESC, user_id;


-- =====================================================================
-- PATTERN 12 · GEOGRAPHIC IMPOSSIBILITY
-- Consecutive transactions by the same user in different cities within
-- 60 minutes. Such movement is physically implausible and may indicate
-- account takeover or shared/stolen credentials.
-- =====================================================================

WITH ordered_txns AS (
    SELECT
        txn_id,
        user_id,
        city,
        txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time
        ) AS previous_txn_time
    FROM transactions
)
SELECT
    user_id,
    txn_id,
    previous_city,
    city AS current_city,
    previous_txn_time,
    txn_time AS current_txn_time,
    TIMESTAMPDIFF(MINUTE, previous_txn_time, txn_time) AS gap_minutes
FROM ordered_txns
WHERE previous_city IS NOT NULL
  AND city <> previous_city
  AND TIMESTAMPDIFF(MINUTE, previous_txn_time, txn_time) <= 60
ORDER BY gap_minutes ASC, user_id, txn_id;


-- =====================================================================
-- FINAL PROJECT RESULT SUMMARY
-- =====================================================================
-- P1  Velocity Fraud                 -> 50 suspect user-days
-- P2  Round-Amount Clustering        -> 25 suspect users
-- P3  Card Testing                   -> 20 suspect user-days
-- P4  Failed-Then-Succeeded          -> 25 suspect users
-- P5  Odd-Hour Concentration         -> 20 suspect users
-- P6  Mule Accounts                  -> 30 suspect users
-- P7  Refund Abuse                   -> 24 suspect users
-- P8  Merchant Collusion             -> 15 suspect merchants
-- P9  Just-Under-Threshold           -> 20 suspect users
-- P10 Dormant-Then-Active            -> 26 suspect cases
-- P11 Velocity Spike                 -> 45 suspect users
-- P12 Geographic Impossibility       -> 15 suspect users
--
-- Dataset verification on supplied file:
-- Transactions parsed: 200,594
-- Distinct users:      14,755
-- Distinct merchants:  800
-- Earliest transaction: 2024-01-01 00:05:26
-- Latest transaction:   2024-06-28 23:59:20

