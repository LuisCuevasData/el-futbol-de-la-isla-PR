# ⚽ El Fútbol de La Isla — Puerto Rico International Football Analysis

> As a Puerto Rican sports analyst, I wanted to tell the data story of La Isla's football journey. Using SQL Server and 49,000+ rows of international match data, this project traces Puerto Rico's transformation across eight decades — from the dark days of 1946 to a golden era producing the island's biggest wins and best defensive record ever.

---

## Project Overview

This project uses **SQL Server** to analyze Puerto Rico's international football history within a dataset of **49,287 international matches** spanning from 1872 to 2026. The central question driving this analysis:

> *Has Puerto Rico football genuinely improved — and can data prove it?*

The answer is an unambiguous yes. This project traces that journey through 13 SQL queries using window functions, CASE WHEN aggregations, multi-table JOINs, and decade-based partitioning.

---

## Database Setup

### Data Source
- **Dataset:** [International Football Results 1872–2026](https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017) — Kaggle
- **Format:** CSV files loaded into SQL Server

### Tables

| Table | Rows | Description |
|---|---|---|
| `results` | 49,287 | Match results — date, teams, scores, tournament, venue |
| `goalscorers` | 47,601 | Individual goal records with scorer, minute, penalty/own goal flags |
| `shootouts` | 675 | Penalty shootout outcomes |
| `former_names` | 36 | Historical country name changes |

### Environment
- **Database:** SQL Server (Docker container — `mcr.microsoft.com/azure-sql-edge`)
- **Client:** VS Code with SQL Server extension
- **Container:** SQL Server running on port 1433

### Loading the Data

Since the data was in CSV format and SQL Server was running inside Docker, the files were copied directly into the container before loading:

```bash
docker cp "results.csv" sql_server:/results.csv
docker cp "goalscorers.csv" sql_server:/goalscorers.csv
docker cp "shootouts.csv" sql_server:/shootouts.csv
docker cp "former_names.csv" sql_server:/former_names.csv
```

Tables were created with `VARCHAR` types for score columns to handle `NA` values in the raw data, with `TRY_CAST` used at query time for safe integer conversion:

```sql
CREATE TABLE results (
    date DATE,
    home_team VARCHAR(100),
    away_team VARCHAR(100),
    home_score VARCHAR(10),
    away_score VARCHAR(10),
    tournament VARCHAR(100),
    city VARCHAR(100),
    country VARCHAR(100),
    neutral VARCHAR(50)
);

BULK INSERT results
FROM '/results.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0a');
```

---

## Analysis & Results

### 1. Global Context — All-Time Win Rate by Country (min. 50 matches)

Before zooming in on Puerto Rico, we established a global baseline. Brazil leads all nations with a **71.2% home win rate** across 612 matches, followed by Spain (68.9%) and Argentina (67.2%).

```sql
SELECT 
    home_team AS team,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1 ELSE 0 END) AS wins,
    ROUND(100.0 * SUM(CASE WHEN TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) 
        THEN 1 ELSE 0 END) / COUNT(*), 1) AS win_pct
FROM results
WHERE TRY_CAST(home_score AS INT) IS NOT NULL
GROUP BY home_team
HAVING COUNT(*) >= 50
ORDER BY win_pct DESC;
```

---

### 2. Top 10 Highest Scoring Matches

Australia's **31–0** demolition of American Samoa in 2001 stands as the most lopsided result in international football history.

```sql
SELECT TOP 10
    date, home_team, away_team, home_score, away_score,
    TRY_CAST(home_score AS INT) + TRY_CAST(away_score AS INT) AS total_goals,
    tournament
FROM results
WHERE TRY_CAST(home_score AS INT) IS NOT NULL
  AND TRY_CAST(away_score AS INT) IS NOT NULL
ORDER BY total_goals DESC;
```

---

### 3. Top 10 All-Time International Goalscorers

Cristiano Ronaldo leads all-time international scorers with **143 goals**. Followed closely by Lionel Messi with **116**
```sql
SELECT TOP 10
    scorer, team, COUNT(*) AS goals
FROM goalscorers
WHERE own_goal = 'False'
GROUP BY scorer, team
ORDER BY goals DESC;
```

---

### 4. Ronaldo's Career Goal Timeline (Window Function)

Using a window function to build a running total of Ronaldo's international goals match by match — his first recorded goal came against Greece on **June 12, 2004**.

```sql
SELECT 
    date, home_team, away_team,
    COUNT(*) AS goals_in_match,
    SUM(COUNT(*)) OVER (ORDER BY date) AS running_total
FROM goalscorers
WHERE scorer = 'Cristiano Ronaldo' AND own_goal = 'False'
GROUP BY date, home_team, away_team
ORDER BY date;
```

---

## 🇵🇷 The Puerto Rico Deep Dive

### The Central Finding

Puerto Rico football has undergone a **dramatic and measurable transformation** over eight decades. The data tells a clear story of a footballing nation that struggled for generations before finding its identity in the modern era.

---

### 5. All-Time Record

| Wins | Draws | Losses | Total Matches |
|---|---|---|---|
| 41 | 26 | 95 | 162 |

Puerto Rico has played 162 international matches — a 25.3% win rate overall. But that headline number hides the real story, which only emerges when you break it down by era.

---

### 6. Performance by Decade — The Core Finding

This is the centerpiece of the project. The improvement is not marginal — it is structural and sustained.

| Decade | Matches | Wins | Avg Goals Scored | Avg Goals Conceded |
|---|---|---|---|---|
| 1940s | 13 | 0 | 0.46 | 5.69 |
| 1960s | 10 | 0 | 0.60 | 4.50 |
| 1970s | 12 | 2 | 0.67 | 2.33 |
| 1980s | 6 | 0 | 0.33 | 2.33 |
| 1990s | 24 | 6 | 0.96 | 2.21 |
| 2000s | 17 | 3 | 1.00 | 2.24 |
| 2010s | 44 | 12 | 1.41 | 1.84 |
| **2020s** | **36** | **18** | **2.25** | **1.28** |

```sql
SELECT
    CONCAT(CAST((YEAR(date) / 10) * 10 AS VARCHAR), 's') AS decade,
    COUNT(*) AS matches,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins,
    ROUND(AVG(CASE WHEN home_team = 'Puerto Rico' THEN TRY_CAST(home_score AS FLOAT)
                   ELSE TRY_CAST(away_score AS FLOAT) END), 2) AS avg_goals_scored,
    ROUND(AVG(CASE WHEN home_team = 'Puerto Rico' THEN TRY_CAST(away_score AS FLOAT)
                   ELSE TRY_CAST(home_score AS FLOAT) END), 2) AS avg_goals_conceded
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
GROUP BY (YEAR(date) / 10) * 10
ORDER BY decade;
```

**Key insight:** In the 1940s Puerto Rico conceded an average of **5.69 goals per game** and won zero matches. In the 2020s they score **2.25 per game** and concede only **1.28** — a complete reversal. The 2020s win total of 18 already exceeds every previous decade combined except the 2010s, with years still remaining.

---

### 7. Home vs Away Performance

| Venue | Matches | Wins | Draws | Losses | Avg Scored | Avg Conceded |
|---|---|---|---|---|---|---|
| Home | 74 | 26 | 15 | 33 | 1.88 | 1.82 |
| Away | 88 | 15 | 11 | 62 | 0.75 | 2.77 |

Puerto Rico's home advantage is significant — they score **2.5x more goals** at home and win at nearly double the rate. This reflects a pattern common among developing football nations where crowd support and familiarity play an outsized role. The Juan Ramón Loubriel effect is real.

---

### 8. Performance by Competition Type

| Competition | Matches | Wins | Draws | Losses | Avg Goals Scored |
|---|---|---|---|---|---|
| Qualification | 81 | 19 | 16 | 46 | 1.25 |
| Friendly | 48 | 6 | 9 | 33 | 0.73 |
| Other | 28 | 15 | 0 | 13 | 2.32 |
| Cup | 5 | 1 | 1 | 3 | 0.80 |

Qualification matches are where Puerto Rico performs best in structured competition — 19 wins in 81 matches with a 1.25 goals scored average. Friendlies show a poor record, likely because they are often used as warm-ups against stronger opposition.

---

### 9. Biggest Wins in History

| Date | Home | Away | Score | Tournament |
|---|---|---|---|---|
| 2012-09-09 | Puerto Rico | Saint Martin | 9–0 | CFU Caribbean Cup qualification |
| 2024-06-11 | Puerto Rico | Anguilla | 8–0 | FIFA World Cup qualification |
| 2021-06-02 | Puerto Rico | Bahamas | 7–0 | FIFA World Cup qualification |
| 2022-06-12 | Puerto Rico | British Virgin Islands | 6–0 | CONCACAF Nations League |

**7 of Puerto Rico's top 10 biggest wins have occurred since 2011** — a direct reflection of the modern era improvement.

---

### 10. Worst Defeats in History

| Date | Opponent | Score | Tournament |
|---|---|---|---|
| 1946-12-15 | Cuba | 14–0 | Central American and Caribbean Games |
| 1946-12-10 | Costa Rica | 12–0 | Central American and Caribbean Games |
| 1946-12-13 | Panama | 12–1 | Central American and Caribbean Games |

The 1946 Caribbean Games was a catastrophic tournament — three matches, three heavy defeats, 38 goals conceded in one week. The most recent result in the top 10 worst defeats is **1996**, confirming that those levels of defeat are a thing of the past.

---

### 11. Head-to-Head vs Caribbean Rivals

| Opponent | Matches | Wins | Draws | Losses |
|---|---|---|---|---|
| Dominican Republic | 12 | 3 | 2 | 7 |
| Guadeloupe | 12 | 0 | 1 | 11 |
| Martinique | 11 | 1 | 0 | 10 |
| Haiti | 10 | 0 | 1 | 9 |

**Guadeloupe is Puerto Rico's bogey team** — 0 wins in 12 matches. The Dominican Republic rivalry is the most competitive at 3W 2D 7L. These head-to-head records reflect the reality of Caribbean football hierarchy, and Puerto Rico's recent rise means these numbers will shift in the coming years.

---

## Key Takeaways

1. **The transformation is real and measurable.** Puerto Rico went from averaging 5.69 goals conceded per game in the 1940s to just 1.28 in the 2020s. That is not noise — it is structural improvement.

2. **The 2010s were the turning point.** Match volume nearly tripled (from 17 to 44 games), wins quadrupled, and goals conceded dropped significantly. Increased CONCACAF competition exposure accelerated development.

3. **The 2020s are the best era in Puerto Rican football history.** 18 wins already, best goals scored average ever, best defensive record ever — and the decade isn't finished.

4. **Home advantage matters enormously.** Puerto Rico scores 2.5x more at home and wins at nearly double the rate, underlining the importance of hosting qualification matches.

5. **Guadeloupe remains the unbeaten rival.** 0 wins in 12 matches makes them Puerto Rico's toughest opponent historically.

---

## Tools & Skills Demonstrated

- **SQL Server** — database creation, bulk data loading, query execution
- **Docker** — SQL Server containerization, file copying into containers
- **SQL Techniques** — `TRY_CAST`, `CASE WHEN`, `GROUP BY`, `HAVING`, `UNION ALL`, window functions (`SUM OVER`, `RANK OVER PARTITION BY`), CTEs, subqueries
- **Data Cleaning** — handling `NA` values, encoding issues, VARCHAR-to-INT conversion
- **Analytical Thinking** — decade segmentation, home/away splits, competition type classification
