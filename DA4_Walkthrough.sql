-- 1. What range of years for baseball games played does the provided database cover?
SELECT yearid
FROM (SELECT a.yearid, t.yearid AS o_year
	 FROM appearances AS a
	 INNER JOIN teams as t
	 ON a.yearid = t.yearid
	) sub
GROUP BY yearid
ORDER BY yearid

SELECT
	MIN(span_first) AS first_date,
	MAX(span_first)	AS last_date
FROM homegames

SELECT MIN(yearid),MAX(yearid)
FROM appearances


-- 2. Find the name and height of the shortest player in the database. How many games 
--    did he play in? What is the name of the team for which he played?
SELECT DISTINCT p.namegiven, p.height, a.g_all, t.name
FROM people AS p
LEFT JOIN appearances AS a
ON p.playerid = a.playerid
LEFT JOIN teams AS t
ON a.teamid = t.teamid AND a.yearid = t.yearid
ORDER BY height

SELECT 
	DISTINCT namefirst,
 	namelast,
 	p.playerid,
	g_all,
	a.teamid,
	name
FROM people as p
INNER JOIN appearances as a
ON a.playerid = p.playerid
INNER JOIN teams as t
ON t.teamid = a.teamid
WHERE height =
(
	SELECT min(height) 
	FROM people
);

SELECT p.namelast, p.namefirst, p.height, a.teamid, a.g_all, t.franchname
FROM people AS p
LEFT JOIN appearances AS a
ON p.playerid = a.playerid
LEFT JOIN teamsfranchises AS t
ON a.teamid = t.franchid
WHERE a.teamid = 'SLA'
ORDER BY P.height;

SELECT p.namefirst, p.namelast, COUNT(*) AS num_games, t.name
FROM appearances AS a
LEFT JOIN people AS p
USING (playerid)
LEFT JOIN teams AS t
USING (teamid)
WHERE p.playerid = (
	SELECT playerid
	FROM people
	WHERE height IS NOT NULL
	ORDER BY height
	LIMIT 1)
GROUP BY p.namefirst, p.namelast, t.name

SELECT *
FROM teams
WHERE teamid = 'SLA'

WITH lil_guy (name, height, games, team) AS
				(SELECT DISTINCT p.namegiven AS name, p.height, a.g_all AS games, t.name AS team
				FROM people AS p
				LEFT JOIN appearances AS a
				ON p.playerid = a.playerid
				LEFT JOIN teams AS t
				ON a.teamid = t.teamid)

SELECT name, height, games, team
FROM lil_guy
ORDER BY height


-- 3. Find all players in the database who played at Vanderbilt University. Create a list 
--    showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--    Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most 
--    money in the majors?
WITH Vanderbilt_Players AS
			(SELECT DISTINCT c.schoolid, s.schoolname ,c.playerid
			 FROM collegeplaying AS c
			 JOIN schools AS s
		     ON c.schoolid = s.schoolid
			 WHERE schoolname = 'Vanderbilt University'),
     TTL_sal AS 
			(select sum(salary) as Total_salary, playerid
			from salaries
			group by playerid)
select p.namelast, p.namefirst, p.namegiven,ts.Total_salary
from Vanderbilt_Players AS vp
inner join TTL_sal as ts
on vp.playerid = ts.playerid
inner join people as p
on vp.playerid = p.playerid
order by ts.Total_salary desc;

Select p.namefirst, p.namelast, s.schoolname, SUM(salary.salary) AS total_earned
FROM people as p
LEFT JOIN (SELECT DISTINCT playerid, schoolid 
		   FROM collegeplaying) as c
	ON p.playerid=c.playerid
LEFT JOIN schools as s
	ON c.schoolid=s.schoolid
LEFT JOIN salaries as salary
	ON p.playerid=salary.playerid
WHERE s.schoolname='Vanderbilt University'
GROUP BY p.namefirst, p.namelast, s.schoolname
ORDER BY total_earned DESC;

SELECT DISTINCT p.namefirst, p.namelast, SUM(salary)
FROM people AS p
INNER JOIN collegeplaying AS cp
ON p.playerid = cp.playerid
INNER JOIN salaries AS s
ON s.playerid = p.playerid
WHERE schoolid = 'vandy'
GROUP BY p.namefirst, p.namelast
ORDER by SUM(salary) DESC;



-- 4. Using the fielding table, group players into three groups based on their position: 
--    label players with position OF as "Outfield", those with position "SS", "1B", "2B", 
--    and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the 
--    number of putouts made by each of these three groups in 2016.
SELECT	position_label, 
		SUM(po) AS putouts,
		total_putouts_2016
FROM(
	SELECT 	playerid, 
		po, 
		pos,
		CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN('P','C') THEN 'Battery'
		WHEN pos IN('SS','1B','2B','3B') THEN 'Infield'
		END AS position_label,
		SUM(po) OVER() AS total_putouts_2016
	FROM fielding
	WHERE yearid = 2016) AS sub
GROUP BY position_label, total_putouts_2016;

select sum(PO), case when pos = 'OF' then 'Outfield'
						when pos in ('SS', '1B', '2B', '3B') then 'Infield'
						when pos = 'P' then 'Battery' 
						when pos = 'C' then 'Battery' else 'na' end as Position
from fielding
where yearid = '2016'
group by Position
order by Position

WITH fielding_group AS (SELECT playerid, 
						yearid, 
						pos,
						CASE WHEN pos IN ('SS','1B','2B','3B') THEN 'Infield'
							 WHEN pos ='OF' THEN 'Outfield'
							 WHEN pos ='P' OR pos='C' THEN 'Battery'
							 END AS pos_groups,
						po
						FROM fielding
					   )
-- SUM the PO  to each POS_group received from CTE					
SELECT fielding_group.pos_groups, sum(po)
FROM fielding_group
WHERE yearid = 2016
GROUP BY fielding_group.pos_groups

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you 
--    report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
SELECT decade, ROUND((decso/decgames), 2) as dec_avg_so, ROUND((dechr/decgames), 2) as dec_avg_hr
	FROM(
		SELECT decade, SUM(games) as decgames, sum(totso) as decso, SUM(tothr) as dechr 
		FROM (
			Select yearid, SUM(g) as games, SUM(so) as totso, SUM(hr) as tothr,
			-- FLOOR(yearid/10)*10 AS decade
			TRUNC(yearid, -1) AS decade
			FROM teams
			WHERE yearid >= 1920
			GROUP BY yearid
			ORDER BY yearid) as sub
		GROUP BY decade
		ORDER BY decade) as sub2

WITH d AS (
SELECT t.so as strike_outs, t.g AS games, t.hr AS home_runs,
CASE WHEN yearid >= 1920 AND yearid <= 1929 THEN '1920s'
WHEN yearid >= 1930 AND yearid<= 1939 THEN '1930s'
WHEN yearid >= 1940 AND yearid<= 1949 THEN '1940S'
WHEN yearid >= 1950 AND yearid<= 1959 THEN '1950S'
WHEN yearid >= 1960 AND yearid<= 1969 THEN '1960s'
WHEN yearid >= 1970 AND yearid<= 1979 THEN '1970s'
WHEN yearid >= 1980 AND yearid<= 1989 THEN '1980s'
WHEN yearid >= 1990 AND yearid<= 1999 THEN '1990s'
WHEN yearid >= 2000 AND yearid<= 2009 THEN '2000s'
WHEN yearid >= 2010 AND yearid<= 2019 THEN '2010s'
WHEN yearid >= 2020 THEN '2020s'
ELSE 'before 1920'
END AS decade
FROM teams t
GROUP BY decade, t.so, t.g, t.hr
)
SELECT DISTINCT decade, 
	ROUND(CAST(SUM(d.strike_outs) AS numeric)/SUM(d.games),2) AS so_per_game,
	ROUND(CAST(SUM(d.home_runs)AS numeric)/SUM(d.games),2) AS hr_per_game
FROM d
WHERE decade <> 'before 1920'
GROUP BY decade
ORDER BY decade;


-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as 
--    the percentage of stolen base attempts which are successful. (A stolen base attempt results either 
--    in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.
WITH bases as (
	SELECT yearID, SB, CS, playerid
FROM batting
WHERE yearID = '2016')
SELECT p.namefirst, p.namelast, p.playerid, 
		SUM(SB+CS) as total_attempts, 
		SUM(SB) as stolen, 
		ROUND(SUM(SB*1.00)/SUM(SB+CS),2) as perc_success 
from people as p
JOIN bases ON bases.playerid = p.playerid
GROUP BY p.playerid
HAVING SUM(SB+CS) <> 0 and SUM(SB+CS) >= 20
ORDER BY perc_success DESC

SELECT b.playerid, p.namefirst, p.namelast, 
		ROUND(100.0 * b.sb / (b.sb + b.cs), 1) AS stealing_perc
FROM batting AS b
INNER JOIN people as p
ON b.playerid = p.playerid
WHERE yearid = 2016 AND b.sb + b.cs >= 20
GROUP BY b.playerid, p.namefirst, p.namelast, stealing_perc
ORDER BY stealing_perc DESC

SELECT 	p.namefirst, 
		p.namelast,
		teamid, 
		sb, 
		cs,
		(sb + cs) AS steal_attempts,
		1.0 * sb as sb_numeric,
		ROUND(100 * sb / (1.0 * sb + cs) , 1) as int_rate,
		ROUND(1.00 * sb / (sb + cs),3) AS stolen_bases_perc					
FROM batting AS b
JOIN people AS p
ON b.playerid = p.playerid
WHERE yearid = 2016 AND sb > 20
ORDER BY stolen_bases_perc DESC



-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--    What is the smallest number of wins for a team that did win the world series? Doing this will 
--    probably result in an unusually small number of wins for a world series champion – determine why 
--    this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was 
--    it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT yearid, teamid, name, w, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y'
ORDER BY w;

with w as (select yearid, max(w) as ww, WSWin
		from teams
		where yearid > 1969
		and yearid != 1981
		and wswin = 'Y'
		group by yearid, wswin
		order by yearid desc),
	l as (select yearid, max(w) as lw, WSWin
		from teams
		where yearid > 1969
		and yearid != 1981
		and wswin = 'N'
		group by yearid, wswin
		order by yearid desc)
select round(sum(case when ww > lw then cast('1.0' as decimal)
			when ww <= lw then cast('0.0' as decimal) end)/
			count(distinct w.yearid), 2)
from w
join l
on w.yearid = l.yearid

WITH winners as	(	SELECT teamid as champ, 
				           yearid, w as champ_w
	  				FROM teams
	  				WHERE 	(wswin = 'Y')
				 			AND (yearid BETWEEN 1970 AND 2016) ),
max_wins as (	SELECT yearid, 
			           max(w) as maxw
	  			FROM teams
	  			WHERE yearid BETWEEN 1970 AND 2016
				GROUP BY yearid)
SELECT 	COUNT(*) AS all_years,
		COUNT(CASE WHEN champ_w = maxw THEN 'Yes' end) as max_wins_by_champ,
		to_char((COUNT(CASE WHEN champ_w = maxw THEN 'Yes' end)/(COUNT(*))::real)*100,'99.99%') as Percent
FROM 	winners LEFT JOIN max_wins
		USING(yearid)
		
WITH max_ws_champ AS
(SELECT yearid,
			MAX(w) AS max_w
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
	GROUP BY yearid
)
SELECT SUM(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END) AS ct_max_is_champ,
		ROUND(100*AVG(CASE WHEN wswin = 'Y' THEN 1 ELSE 0 END), 2) AS perc_max_is_champ
FROM max_ws_champ AS m
INNER JOIN teams AS t
ON m.yearid = t.yearid AND m.max_w = t.w


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the 
--    top 5 average attendance per game in 2016 (where average attendance is defined as total 
--    attendance divided by number of games). Only consider parks where there were at least 10 games played. 
--    Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
SELECT distinct p.Park_name,hg.park, hg.team,t.name, (hg.attendance/hg.games) AS Att_per_game
FROM parks AS P
JOIN homegames AS hg	
ON p.park = hg.park
JOIN teams as t
ON hg.team = t.teamid and hg.year = t.yearid
WHERE year = '2016' AND games>=10
GROUP BY t.name, hg.team,p.park_name,hg.park,hg.attendance,t.teamid ,hg.games
ORDER BY Att_per_game
LIMIT 5;

SELECT park, team,
	CASE WHEN attendance = 0 THEN 0 ELSE attendance/games 
	END AS l_avg_att
FROM homegames
WHERE year = 2016
AND games >= 10
ORDER BY l_avg_att
LIMIT 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) 
--    and the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT a.playerid, a.yearid, a.lgid, p.namefirst, p.namelast, m.teamid
FROM awardsmanagers AS a
LEFT JOIN people AS p
ON a.playerid = p.playerid
LEFT JOIN managers as m
ON a.playerid = m.playerid AND a.yearid = m.yearid
WHERE awardid = 'TSN Manager of the Year' AND a.playerid IN (
SELECT playerid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year' AND lgid = 'NL'
INTERSECT
SELECT playerid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year' AND lgid = 'AL')

WITH nl AS (SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid ILIKE '%TSN%'
AND lgid = 'NL'
ORDER BY playerid),

al AS (SELECT playerid, awardid, yearid, lgid
FROM awardsmanagers
WHERE awardid ILIKE '%TSN%'
-- AND lgid = 'AL'
ORDER BY playerid)

SELECT sub.playerid, sub.yearid, sub.lgid, p.namefirst, p.namelast, m.teamid, t.name
FROM (
	SELECT playerid, awardid, yearid, lgid
	FROM awardsmanagers
	WHERE awardid ILIKE '%TSN%'
	AND playerid IN(
		SELECT playerid
		FROM nl
		INTERSECT
		SELECT playerid
		FROM al)) AS sub
JOIN people AS p
ON sub.playerid = p.playerid
JOIN managers AS m
ON sub.yearid = m.yearid AND sub.playerid = m.playerid
JOIN teams AS t
ON m.yearid = t.yearid AND m.teamid = t.teamid;



-- 10. Analyze all the colleges in the state of Tennessee. Which college has had the most success 
--     in the major leagues. Use whatever metric for success you like - number of players, number of 
--     games, salaries, world series wins, etc.
SELECT DISTINCT schoolname,
		playerid, namefirst, namelast,
		SUM(g_all) OVER(PARTITION BY playerid) AS g_total_player,
		SUM(g_all) OVER(PARTITION BY schoolname) AS g_total_school
FROM appearances AS a
INNER JOIN people AS p
USING (playerid)
INNER JOIN (SELECT DISTINCT playerid, schoolid FROM collegeplaying) AS cp
USING (playerid)
INNER JOIN schools
USING (schoolid)
WHERE schoolstate = 'TN'
ORDER BY g_total_school DESC, g_total_player DESC;

SELECT DISTINCT(sc.schoolid),
	SUM(a.g_all) OVER(PARTITION BY cp.schoolid) AS total_games,
	COUNT(a.playerid) OVER(PARTITION BY cp.schoolid) AS total_players,
	SUM(s.salary) OVER(PARTITION BY cp.schoolid) AS total_salary,
	COUNT(t.wswin) OVER(PARTITION BY cp.schoolid) AS total_wswins
FROM (SELECT DISTINCT playerid, schoolid FROM collegeplaying) AS cp
JOIN  schools AS sc
ON cp.schoolid = sc.schoolid
JOIN appearances AS a
ON cp.playerid = a.playerid
JOIN salaries AS s
ON cp.playerid = s.playerid
JOIN teams AS t
ON t.teamid = a.teamid AND t.yearid = a.yearid
WHERE cp.schoolid IN
	(SELECT schoolid
	FROM schools
	WHERE schoolstate = 'TN')
ORDER BY total_games DESC	--exchange with total_players  total_salary  total_ws_wins

SELECT 
	schoolname, 
	schoolstate, 
	COUNT(DISTINCT p.playerid) AS n_players, 
	SUM(COALESCE(salary,0)) AS total_salaries
FROM schools AS s
LEFT JOIN (SELECT DISTINCT playerid, schoolid FROM collegeplaying) AS cp
ON s.schoolid = cp.schoolid
LEFT JOIN people AS p
ON cp.playerid = p.playerid
LEFT JOIN salaries AS sl
ON p.playerid = sl.playerid
WHERE schoolstate = 'TN'
GROUP BY schoolname, schoolstate
ORDER BY 4 DESC;

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later 
--     to answer this question. As you do this analysis, keep in mind that salaries across the whole 
--     league tend to increase together, so you may want to look on a year-by-year basis.
SELECT t.teamid, t.yearid, 
		t.name,
		SUM(t.w) AS wins_year, CONCAT(ROUND(CAST(s.yearly_salary/1000000.00 AS numeric),2), 'M') AS salary_mil, 
		ROUND(CAST(s.yearly_salary/1000000 AS numeric)/SUM(t.w),2) AS salary_mil_per_win
FROM teams AS t
LEFT JOIN (
	SELECT teamid, yearid, SUM(salary) AS yearly_salary
	FROM salaries
	WHERE yearid >= 2000
	GROUP BY teamid, yearid
	ORDER BY teamid, yearid) AS s
ON t.teamid = s.teamid AND t.yearid = s.yearid
WHERE t.yearid >= 2000
GROUP BY t.teamid, t.yearid, t.name, s.yearly_salary
ORDER BY salary_mil_per_win DESC;

WITH ts AS(
	SELECT yearid,
			teamid,
			SUM(salary) AS team_salary
	FROM salaries
	GROUP BY yearid, teamid
	ORDER BY yearid, teamid
),
sal_w_rk AS(
	SELECT t.yearid,
		t.teamid,
		ts.team_salary,
		t.w,
		RANK() OVER(PARTITION BY t.yearid ORDER BY ts.team_salary DESC) AS team_sal_rk,
		RANK() OVER(PARTITION BY t.yearid ORDER BY t.w DESC) AS team_w_rk
FROM teams AS t
LEFT JOIN ts
USING (yearid, teamid)
WHERE t.yearid >= 2000
ORDER BY t.yearid, t.w DESC
	)
SELECT team_sal_rk,
		ROUND(AVG(team_w_rk), 1) AS avg_w_rk
FROM sal_w_rk
GROUP BY team_sal_rk
ORDER BY team_sal_rk



-- 12. In this question, you will explore the connection between number of wins and attendance.

--      i. Does there appear to be any correlation between attendance at home games and number of wins?
--     ii. Do teams that win the world series see a boost in attendance the following year? 
--         What about teams that made the playoffs? Making the playoffs means either being a 
--         division winner or a wild card winner.
SELECT 
	yearid,
	park, 
	franchid, 
	ROUND(((w*1.0)/(g*1.0)),2) AS win_perc,
	wswin,
	attendance,
	RANK() OVER(PARTITION BY yearid ORDER BY attendance DESC)AS attendance_rank_year
FROM teams
WHERE yearid BETWEEN 1990 AND 2015
ORDER BY win_perc DESC, attendance_rank_year;

--Q12(B)

SELECT 
	park, 
	franchid,
	yearid,
	attendance,
	LEAD(attendance) OVER(PARTITION BY park ORDER BY yearid) AS attendance_following_year,
	LEAD(attendance) OVER(PARTITION BY park ORDER BY yearid) - attendance AS change_in_attendance,
	wswin,
	lgwin,
	divwin,
	wcwin
FROM teams
WHERE yearid BETWEEN 2000 AND 2015
ORDER BY wswin DESC, yearid;

WITH w_att_rk AS (
SELECT yearid,
		teamid,
		w,
		attendance / ghome AS avg_h_att,
		RANK() OVER(PARTITION BY yearid ORDER BY w) AS w_rk,
		RANK() OVER(PARTITION BY yearid ORDER BY attendance / ghome) AS avg_h_att_rk
FROM teams
WHERE attendance / ghome IS NOT NULL
AND yearid >= 1961 						--MLB institutes 162 game season
ORDER BY yearid, teamid
)
SELECT avg_h_att_rk,
		ROUND(AVG(w_rk), 1) AS avg_w_rk
FROM w_att_rk
GROUP BY avg_h_att_rk
ORDER BY avg_h_att_rk


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, 
--     that they are more effective. Investigate this claim and present evidence to either support or 
--     dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed 
--     pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make 
--     it into the hall of fame?
WITH lefties AS (SELECT playerid	 						
			     FROM people
			     WHERE throws = 'L' AND playerid IN
												   (SELECT playerid
							 						FROM pitching)),
    all_pitchers AS (SELECT playerid 
			     FROM people
				 WHERE playerid IN
								 (SELECT playerid
								 FROM pitching))
SELECT COUNT(lefties.*) AS count_lefties, 
		COUNT(all_pitchers.*) AS count_pitchers,
		ROUND(COUNT(lefties.playerid) *100.0/ (COUNT(all_pitchers.playerid)),1) AS percent_lefties
FROM people
LEFT JOIN lefties
ON people.playerid = lefties.playerid
LEFT JOIN all_pitchers
ON people.playerid = all_pitchers.playerid

--likelyhood to win award
-- JOIN awardsplayers 
-- ON awardsplayers.playerid = people.playerid
-- WHERE awardid = 'Cy Young Award'


--likelyhood to enter HoF
WHERE people.playerid IN
						(SELECT playerid
						FROM halloffame)


WITH cy_young AS (
	SELECT *
	FROM awardsplayers
	WHERE awardid = 'Cy Young Award'
	),
left_pitchers AS (
	SELECT *
	FROM people
	WHERE playerid IN
		(SELECT DISTINCT playerid
		FROM pitching
		)
	AND throws = 'L'
	),
right_pitchers AS (
	SELECT *
	FROM people
	WHERE playerid IN
		(SELECT DISTINCT playerid
		FROM pitching
		)
	AND throws = 'R'
	)
SELECT ROUND(AVG(CASE WHEN p.throws = 'L' THEN 1
		  		WHEN p.throws = 'R' THEN 0 END), 4) AS perc_CY_L,
		ROUND(AVG(CASE WHEN p.throws = 'R' THEN 1
		  		WHEN p.throws = 'L' THEN 0 END), 4) AS perc_CY_R
FROM people AS p
INNER JOIN cy_young
USING (playerid)

WITH hof_pitchers AS (
	SELECT *
	FROM halloffame
	INNER JOIN pitching
	USING (playerid)
	WHERE inducted = 'Y'
	)
SELECT ROUND(AVG(CASE WHEN throws = 'L' THEN 1
		  		ELSE 0 END), 4) AS perc_HOF_L_pitch,
		ROUND(AVG(CASE WHEN throws = 'R' THEN 1
		  		ELSE 0 END), 4) AS perc_HOF_R_pitch
FROM hof_pitchers
INNER JOIN people
USING (playerid)




-- 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(yearid) as earliest_year, 
		MAX(yearid) AS latest_year
FROM appearances;

-- 2. Find the name and height of the shortest player in the database. How many games 
--    did he play in? What is the name of the team for which he played?
SELECT p.playerid, p.namefirst, p.namelast, t.name, p.height, app.games_played
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
SELECT s.yearid, s.teamid,
		t.name,
		team_salary,
		t.w as wins
FROM 
(SELECT salaries.yearid, salaries.teamid,
		SUM(salary) as team_salary
FROM salaries
WHERE salaries.yearid >= 2000
GROUP BY salaries.yearid, salaries.teamid) s
LEFT JOIN teams t on s.teamid = t.teamid AND s.yearid = t.yearid
ORDER BY wins DESC;

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
-- From 1967 on because that was first AL/NL Cy Young
SELECT *
FROM awardsplayers
WHERE awardid = 'Cy Young Award' AND
	yearid >= 1967;


with pitchers as (SELECT pitching.playerid,
		people.namefirst, people.namelast,
		people.throws,
		pitching.yearid,
		pitching.teamid, pitching.w,
		pitching.l, pitching.g, pitching.so,
		pitching.era, pitching.IPOUTS
FROM pitching
LEFT JOIN people USING(playerid)
WHERE yearid >= 1967)
SELECT throws,
		COUNT(*) as num_pitchers,
		SUM(g) as games_pitched,
		(SELECT COUNT(*) FROM pitchers) as total_pitchers,
		ROUND(CAST(COUNT(*) as dec) / CAST((SELECT COUNT(*) FROM pitchers) as dec) * 100, 1 ) as pct_throwing_hand,
		COUNT(awardid) as num_cy_youngs,
		(SELECT COUNT(*)
			FROM awardsplayers
			WHERE awardid = 'Cy Young Award' AND
					yearid >= 1967) as total_cy_youngs,
		COUNT(DISTINCT hall.playerid)
FROM pitchers
LEFT JOIN (SELECT *
FROM awardsplayers
WHERE awardid = 'Cy Young Award' AND
	yearid >= 1967) as cy_young USING(playerid, yearid)
LEFT JOIN (
	SELECT DISTINCT playerid, yearid
	FROM halloffame
	WHERE inducted = 'Y'
		AND category = 'Player'
) hall USING (playerid)
GROUP BY throws;

















