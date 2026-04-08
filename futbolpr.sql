-- Puerto Rico all-time record
SELECT
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN TRY_CAST(home_score AS INT) = TRY_CAST(away_score AS INT) THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) < TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) < TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS losses,
    COUNT(*) AS total_matches
FROM results
WHERE home_team = 'Puerto Rico' OR away_team = 'Puerto Rico';

-- Puerto Rico results by tournament
SELECT
    tournament,
    COUNT(*) AS matches,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins
FROM results
WHERE home_team = 'Puerto Rico' OR away_team = 'Puerto Rico'
GROUP BY tournament
ORDER BY matches DESC;

-- Puerto Rico's top scorers
SELECT TOP 10
    scorer,
    COUNT(*) AS goals
FROM goalscorers
WHERE team = 'Puerto Rico'
  AND own_goal = 'False'
GROUP BY scorer
ORDER BY goals DESC;

-- Puerto Rico home vs away performance
SELECT
    CASE WHEN home_team = 'Puerto Rico' THEN 'Home' ELSE 'Away' END AS venue,
    COUNT(*) AS matches,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
             AND TRY_CAST(home_score AS INT) = TRY_CAST(away_score AS INT) THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) < TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) < TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS losses,
    ROUND(AVG(CASE WHEN home_team = 'Puerto Rico' THEN TRY_CAST(home_score AS FLOAT)
                   ELSE TRY_CAST(away_score AS FLOAT) END), 2) AS avg_goals_scored,
    ROUND(AVG(CASE WHEN home_team = 'Puerto Rico' THEN TRY_CAST(away_score AS FLOAT)
                   ELSE TRY_CAST(home_score AS FLOAT) END), 2) AS avg_goals_conceded
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
GROUP BY CASE WHEN home_team = 'Puerto Rico' THEN 'Home' ELSE 'Away' END;

-- Puerto Rico performance by competition type
SELECT
    CASE 
        WHEN tournament = 'Friendly' THEN 'Friendly'
        WHEN tournament LIKE '%qualification%' THEN 'Qualification'
        WHEN tournament LIKE '%Cup%' THEN 'Cup'
        ELSE 'Other'
    END AS competition_type,
    COUNT(*) AS matches,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
             AND TRY_CAST(home_score AS INT) = TRY_CAST(away_score AS INT) THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) < TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) < TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS losses,
    ROUND(AVG(CASE WHEN home_team = 'Puerto Rico' THEN TRY_CAST(home_score AS FLOAT)
                   ELSE TRY_CAST(away_score AS FLOAT) END), 2) AS avg_goals_scored
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
GROUP BY 
    CASE 
        WHEN tournament = 'Friendly' THEN 'Friendly'
        WHEN tournament LIKE '%qualification%' THEN 'Qualification'
        WHEN tournament LIKE '%Cup%' THEN 'Cup'
        ELSE 'Other'
    END
ORDER BY matches DESC;

-- Puerto Rico performance by decade
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

-- Puerto Rico's biggest wins ever
SELECT TOP 10
    date,
    home_team,
    away_team,
    home_score,
    away_score,
    tournament,
    CASE WHEN home_team = 'Puerto Rico' 
         THEN TRY_CAST(home_score AS INT) - TRY_CAST(away_score AS INT)
         ELSE TRY_CAST(away_score AS INT) - TRY_CAST(home_score AS INT)
    END AS goal_difference
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
  AND (CASE WHEN home_team = 'Puerto Rico' 
            THEN TRY_CAST(home_score AS INT) - TRY_CAST(away_score AS INT)
            ELSE TRY_CAST(away_score AS INT) - TRY_CAST(home_score AS INT)
       END) > 0
ORDER BY goal_difference DESC;

-- Puerto Rico's worst defeats ever
SELECT TOP 10
    date,
    home_team,
    away_team,
    home_score,
    away_score,
    tournament,
    CASE WHEN home_team = 'Puerto Rico' 
         THEN TRY_CAST(away_score AS INT) - TRY_CAST(home_score AS INT)
         ELSE TRY_CAST(home_score AS INT) - TRY_CAST(away_score AS INT)
    END AS goals_lost_by
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
  AND (CASE WHEN home_team = 'Puerto Rico' 
            THEN TRY_CAST(away_score AS INT) - TRY_CAST(home_score AS INT)
            ELSE TRY_CAST(home_score AS INT) - TRY_CAST(away_score AS INT)
       END) > 0
ORDER BY goals_lost_by DESC;

-- Puerto Rico's most common opponents and record against them
SELECT
    CASE WHEN home_team = 'Puerto Rico' THEN away_team ELSE home_team END AS opponent,
    COUNT(*) AS matches,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) > TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) > TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
             AND TRY_CAST(home_score AS INT) = TRY_CAST(away_score AS INT) THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN home_team = 'Puerto Rico' AND TRY_CAST(home_score AS INT) < TRY_CAST(away_score AS INT) THEN 1
             WHEN away_team = 'Puerto Rico' AND TRY_CAST(away_score AS INT) < TRY_CAST(home_score AS INT) THEN 1 ELSE 0 END) AS losses
FROM results
WHERE (home_team = 'Puerto Rico' OR away_team = 'Puerto Rico')
  AND TRY_CAST(home_score AS INT) IS NOT NULL
GROUP BY CASE WHEN home_team = 'Puerto Rico' THEN away_team ELSE home_team END
ORDER BY matches DESC;