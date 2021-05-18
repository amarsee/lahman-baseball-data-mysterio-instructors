-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(yearid) as earliest_year, 
		MAX(yearid) AS latest_year
FROM appearances;

-- 2. Find the name and height of the shortest player in the database. How many games 
--    did he play in? What is the name of the team for which he played?
SELECT p.playerid, p.namefirst, p.namelast, t.name, p.height
FROM people p
LEFT JOIN ( SELECT playerid, teamid, SUM(g_all) as games_played
		   	FROM appearances
		  	GROUP BY playerid, teamid) app ON p.playerid = app.playerid
LEFT JOIN (SELECT DISTINCT teamid, name 
		   FROM teams) t on t.teamid = app.teamid
ORDER BY p.height;

-- 3. Find all players in the database who played at Vanderbilt University. Create a list 
--    showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--    Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most 
--    money in the majors?
SELECT   v.schoolname,
		p.playerid, p.namefirst, 
		p.namelast,
		salary.total_earnings
FROM people as p
INNER JOIN (
	SELECT DISTINCT playerid, s.schoolname
	FROM collegeplaying as cp
	INNER JOIN schools as s ON cp.schoolid = s.schoolid
	WHERE schoolname = 'Vanderbilt University'
) as v ON p.playerid = v.playerid
INNER JOIN (
	SELECT playerid, SUM(salary) as total_earnings
	FROM salaries
	GROUP BY playerid
) as salary ON p.playerid = salary.playerid
-- WHERE total_earnings IS NOT NULL
ORDER BY total_earnings DESC;


-- 4. Using the fielding table, group players into three groups based on their position: 
--    label players with position OF as "Outfield", those with position "SS", "1B", "2B", 
--    and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the 
--    number of putouts made by each of these three groups in 2016.
SELECT pos_group, SUM(po) as total_putouts
FROM (
	SELECT CASE 
			WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
			WHEN pos IN ('P', 'C') THEN 'Battery'
			ELSE NULL
		END as pos_group,
		po
	FROM fielding 
	WHERE yearid = 2016
) sub
GROUP BY pos_group
ORDER BY total_putouts DESC;


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you 
--    report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT decade, 
		SUM(so) as so_batter, SUM(soa) as so_pitcher, 
		ROUND(CAST(SUM(so) as dec) / CAST(SUM(g) as dec), 2) as so_per_game,
		ROUND(CAST(SUM(hr) as dec) / CAST(SUM(g) as dec), 2) as hr_per_game
FROM (
	SELECT CASE 
			WHEN yearid >= 2010 THEN '2010s'
			WHEN yearid >= 2000 THEN '2000s'
			WHEN yearid >= 1990 THEN '1990s'
			WHEN yearid >= 1980 THEN '1980s'
			WHEN yearid >= 1970 THEN '1970s'
			WHEN yearid >= 1960 THEN '1960s'
			WHEN yearid >= 1950 THEN '1950s'
			WHEN yearid >= 1940 THEN '1940s'
			WHEN yearid >= 1930 THEN '1930s'
			WHEN yearid >= 1920 THEN '1920s'
			ELSE NULL
		END AS decade,
		so,
		soa,
		hr,
		g
	FROM teams
-- 	WHERE decade IS NOT NULL
) sub
WHERE decade IS NOT NULL
GROUP BY decade
ORDER BY decade DESC;


-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as 
--    the percentage of stolen base attempts which are successful. (A stolen base attempt results either 
--    in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
SELECT p.playerid, p.namefirst, p.namelast,
		player_sb.sb_season, player_sb.cs_season,
		player_sb.sb_attempts_season,
		ROUND(CAST(sb_season as dec) / CAST(sb_attempts_season as dec) * 100.0, 1) as sb_success_rate
FROM (
	SELECT playerid, SUM(sb) as sb_season, SUM(cs) as cs_season, 
			SUM(sb) + SUM(cs) as sb_attempts_season
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
) player_sb
LEFT JOIN people p ON p.playerid = player_sb.playerid
WHERE sb_attempts_season >= 20
ORDER BY sb_success_rate DESC;


-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--    What is the smallest number of wins for a team that did win the world series? Doing this will 
--    probably result in an unusually small number of wins for a world series champion – determine why 
--    this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was 
--    it the case that a team with the most wins also won the world series? What percentage of the time?

-- Most wins to not win World Series
SELECT t.yearid as season,
		t.w as wins,
		t.name as team_name
FROM teams t
WHERE NOT EXISTS (
	SELECT yearid, teamidwinner
	FROM seriespost
	WHERE round = 'WS'
		AND yearid BETWEEN 1970 AND 2016
		AND seriespost.yearid = t.yearid
		AND seriespost.teamidwinner = t.teamid
)
	AND t.yearid BETWEEN 1970 AND 2016
ORDER BY wins DESC;

-- Smallest season wins to win World Series 
SELECT ws.yearid as season, 
		t.w as wins,
		ws.teamidwinner,
		t.name as team_name
FROM (
	SELECT yearid, teamidwinner
	FROM seriespost
	WHERE round = 'WS'
		AND yearid BETWEEN 1970 AND 2016
)ws 
INNER JOIN teams t ON t.teamid = ws.teamidwinner 
				AND t.yearid = ws.yearid
WHERE ws.yearid <> 1981
ORDER BY wins;

-- Most wins and also win WS
WITH winning_ws AS (SELECT ws.yearid as season, 
		t.w as wins,
		ws.teamidwinner,
		t.name as team_name
FROM (
	SELECT yearid, teamidwinner
	FROM seriespost
	WHERE round = 'WS'
		AND yearid BETWEEN 1970 AND 2016
)ws 
LEFT JOIN (
		SELECT j.yearid, j.w,
				j.teamid, j.name
		FROM teams j
		INNER JOIN (
			SELECT yearid, MAX(w) as max_wins
			FROM teams
			WHERE yearid BETWEEN 1970 and 2016
			GROUP BY yearid
		) sub ON j.yearid = sub.yearid AND j.w = sub.max_wins
)t ON t.teamid = ws.teamidwinner 
				AND t.yearid = ws.yearid
WHERE ws.yearid <> 1981
ORDER BY wins)
SELECT COUNT(wins) as times_most_win_won_ws,
		COUNT(*) as num_ws,
		ROUND(CAST(COUNT(wins) as dec) / CAST(COUNT(*) as dec) * 100.0, 1) as win_pct
FROM winning_ws;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the 
--    top 5 average attendance per game in 2016 (where average attendance is defined as total 
--    attendance divided by number of games). Only consider parks where there were at least 10 games played. 
--    Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT h.league, h.team, t.name,
		h.park, p.park_name, h.attendance, h.games,
		ROUND(CAST(h.attendance as dec) / CAST(h.games as dec), 1) as avg_attendance
FROM homegames h
LEFT JOIN parks p ON h.park = p.park
LEFT JOIN (
	SELECT yearid, teamid, name
	FROM teams
) t ON t.yearid = h.year AND h.team = t.teamid
WHERE year = 2016 AND
	h.games >= 10
ORDER BY avg_Attendance DESC;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) 
--    and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT *
FROM awardsmanagers
WHERE awardid ILIKE '%TSN%';

WITH m AS 
(SELECT *
FROM awardsmanagers
WHERE lgid = 'AL'
	AND awardid ILIKE '%TSN%'
	AND playerid IN (
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid ILIKE '%TSN%'
			AND lgid = 'NL'
	)
UNION
SELECT *
FROM awardsmanagers
WHERE lgid = 'NL'
	AND awardid ILIKE '%TSN%'
	AND playerid IN (
		SELECT playerid
		FROM awardsmanagers
		WHERE awardid ILIKE '%TSN%'
			AND lgid = 'AL'
	)
 )
SELECT m.awardid, m.yearid AS award_year, 
		m.lgid AS award_league, 
		p.namefirst, p.namelast,
		t.name
FROM m
LEFT JOIN people p ON p.playerid = m.playerid
LEFT JOIN managers ON managers.playerid = m.playerid
			AND managers.yearid = m.yearid
LEFT JOIN teams t ON t.yearid = managers.yearid AND managers.teamid = t.teamid
ORDER BY p.namelast, m.yearid;


-- 10. Analyze all the colleges in the state of Tennessee. Which college has had the most success 
--     in the major leagues. Use whatever metric for success you like - number of players, number of 
--     games, salaries, world series wins, etc.
WITH cte AS (SELECT   v.schoolname,
		p.playerid, p.namefirst, 
		p.namelast,
		salary.total_earnings,
		g.games_played
FROM people as p
INNER JOIN (
	SELECT DISTINCT playerid, s.schoolname
	FROM collegeplaying as cp
	INNER JOIN schools as s ON cp.schoolid = s.schoolid
	WHERE schoolstate = 'TN'
) as v ON p.playerid = v.playerid
INNER JOIN (
	SELECT playerid, SUM(salary) as total_earnings
	FROM salaries
	GROUP BY playerid
) as salary ON p.playerid = salary.playerid
INNER JOIN (
	SELECT playerid, SUM(g) as games_played
	FROM batting
	GROUP BY playerid
) g on g.playerid = p.playerid
-- WHERE total_earnings IS NOT NULL
ORDER BY total_earnings DESC)
SELECT schoolname,
		COUNT(*) AS num_players,
		SUM(total_earnings) as alumni_total_salary,
		SUM(games_played) as alumni_total_games
FROM cte
GROUP BY schoolname
ORDER BY num_players DESC;

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later 
--     to answer this question. As you do this analysis, keep in mind that salaries across the whole 
--     league tend to increase together, so you may want to look on a year-by-year basis.


-- 12. In this question, you will explore the connection between number of wins and attendance.

--      i. Does there appear to be any correlation between attendance at home games and number of wins?
--     ii. Do teams that win the world series see a boost in attendance the following year? 
--         What about teams that made the playoffs? Making the playoffs means either being a 
--         division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, 
--     that they are more effective. Investigate this claim and present evidence to either support or 
--     dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed 
--     pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make 
--     it into the hall of fame?

















