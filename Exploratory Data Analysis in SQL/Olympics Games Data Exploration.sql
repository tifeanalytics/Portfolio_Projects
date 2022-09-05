
--- General overview of the data
SELECT *
FROM Projects..athlete_events

SELECT * 
FROM Projects..noc_regions

--1.	How many olympics games have been held?

SELECT COUNT(DISTINCT Games) AS no_games
FROM Projects..athlete_events

--2.	List all Olympics games held so far.

SELECT DISTINCT Year, Season, City
FROM Projects..athlete_events
ORDER BY Year

--3.	Mention the total no of nations that participated in each olympics game?

SELECT Year, COUNT(DISTINCT region) AS no_of_country
FROM Projects..athlete_events AS a
JOIN Projects..noc_regions AS n
ON a.NOC = n.NOC
GROUP BY Year
ORDER BY Year

--4.	Which year saw the highest and lowest no of countries participating in olympics?

WITH t1 AS(SELECT TOP 1 Games AS lowest_country, 
			COUNT(DISTINCT region) AS lowest_no_of_country
FROM Projects..athlete_events AS a
JOIN Projects..noc_regions AS n
ON a.NOC = n.NOC
GROUP BY Games
ORDER BY Games ASC),

t2 AS(SELECT TOP 1 Games AS highest_country,
	COUNT (DISTINCT region) AS highest_no_country
	FROM Projects..athlete_events AS a
JOIN Projects..noc_regions AS n
ON a.NOC = n.NOC
GROUP BY Games
ORDER BY Games DESC)

SELECT CONCAT (lowest_country, ' ', lowest_no_of_country) AS lowest_game_country,
	  CONCAT (highest_country, ' ', highest_no_country) AS highest_game_country
FROM t1, t2

--5.	Which nation has participated in all of the olympic games?

SELECT region, COUNT(DISTINCT Games) AS no_of_games
FROM Projects..athlete_events AS a
JOIN Projects..noc_regions AS n
ON a.NOC = n.NOC
GROUP BY region
HAVING COUNT(DISTINCT Games) = 51

--6.	Identify the sport which was played in all summer Olympics.

-- Fist find total number of Summer Olympic games
SELECT COUNT(DISTINCT Games) as total_summer_games
FROM Projects..athlete_events
WHERE Season = 'Summer'
	
-- Total Summer games = 29

SELECT s.Sport, COUNT (s.Sport) AS no_sport
FROM (SELECT DISTINCT Sport, Year
	 FROM Projects..athlete_events
	 WHERE Season = 'Summer' ) s
GROUP BY s.Sport
HAVING COUNT(s.Sport) = 29

--7.	Which Sports were just played only once in the olympics?

SELECT s.Sport, COUNT (s.Sport) AS no_sport
FROM (SELECT DISTINCT Sport, Year
	  FROM Projects..athlete_events ) s
GROUP BY s.Sport
HAVING COUNT(s.Sport) = 1

--8.	Fetch the total number of sports played in each olympic game

SELECT Games, COUNT(DISTINCT Sport) AS no_sport
FROM Projects..athlete_events
GROUP BY Games
ORDER BY no_sport DESC

--9. 	Fetch details of the oldest athletes to win a gold medal.

SELECT *
FROM (SELECT *, DENSE_RANK() OVER(ORDER BY age DESC) AS rnk
	  FROM Projects..athlete_events
	  WHERE medal = 'Gold') s
WHERE rnk = 1

--10.	Find the Ratio of male and female athletes participated in all olympic games.

WITH t1 (class)
	AS(
		SELECT CAST (s.male_count AS float) / CAST(s.female_count AS float) AS div
		FROM (SELECT COUNT(DISTINCT Games) AS count_games,
				SUM(CASE WHEN Sex = 'M' THEN 1 ELSE 0 END) AS male_count,
				SUM(CASE WHEN Sex = 'F' THEN 1 ELSE 0 END) AS female_count
			 FROM Projects..athlete_events) s)

SELECT CONCAT ('1 : ', round(class, 2)) AS gender_ratio
FROM t1

--11.	Fetch the top 5 athletes who have won the most gold medals

WITH t1(Name, medal_count) AS 
	(SELECT Name, COUNT(Medal) AS medal_count
	FROM Projects..athlete_events
	WHERE Medal = 'Gold'
	GROUP BY Name),

t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY medal_count DESC) as rank
	FROM t1)

SELECT Name, medal_count, rank
FROM t2
WHERE rank <= 5
ORDER BY rank;

--12.	Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

WITH t1(Name, medal_count) AS 
	(SELECT Name, COUNT(Medal) AS medal_count
	FROM Projects..athlete_events
	WHERE Medal IN ('Gold', 'Silver', 'Bronze')
	GROUP BY Name),

t2 AS 
	(SELECT *, DENSE_RANK() OVER (ORDER BY medal_count DESC) as rank
	FROM t1)

SELECT Name, medal_count, rank
FROM t2
WHERE rank <= 5
ORDER BY rank;

--13.	Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

WITH t1 (region, no_medals, medal_rank)
AS (
SELECT region AS Country, no_medals, DENSE_RANK() OVER(ORDER BY no_medals DESC) AS medal_rank
FROM(SELECT region, SUM (CASE WHEN medal IN ('gold', 'silver', 'bronze') 
							  THEN 1 ELSE 0 END) AS no_medals
	 FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY region
) sub)

SELECT region, no_medals
FROM t1
WHERE medal_rank <= 5

--14.	List total gold, silver and broze medals won by each country.

SELECT region AS Country, SUM (CASE WHEN medal = 'gold' THEN 1 ELSE 0 END) AS gold,
				SUM (CASE WHEN medal = 'silver' THEN 1 ELSE 0 END) AS silver,
				SUM (CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END) AS bronze
FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY region
ORDER BY gold DESC, silver DESC, bronze DESC
	
--15.	List total gold, silver and broze medals won by each country corresponding at each olympic games.

SELECT DISTINCT Games, region AS Country, SUM (CASE WHEN medal = 'gold' THEN 1 ELSE 0 END) AS gold,
				SUM (CASE WHEN medal = 'silver' THEN 1 ELSE 0 END) AS silver,
				SUM (CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END) AS bronze
FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY Games, region
ORDER BY Games, region

--16.	Identify which country won the most gold, most silver and most bronze medals in each olympic games.

WITH t1(Games, region, no_gold, no_silver, no_bronze)
AS(SELECT Games, region, SUM (CASE WHEN medal = 'gold' THEN 1 ELSE 0 END) AS no_gold,
				SUM (CASE WHEN medal = 'silver' THEN 1 ELSE 0 END) AS no_silver,
				SUM (CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END) AS no_bronze
FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY Games, region) 

SELECT Distinct Games,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_gold DESC)), 
		' - ', FIRST_VALUE (no_gold) OVER (PARTITION BY Games ORDER BY no_gold DESC)) AS Max_gold,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_silver DESC)),
		' - ', FIRST_VALUE (no_silver) OVER (PARTITION BY Games ORDER BY no_silver DESC)) AS Max_silver,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_bronze DESC)),
		' - ', FIRST_VALUE (no_bronze) OVER (PARTITION BY Games ORDER BY no_bronze DESC)) AS Max_bronze
FROM t1
ORDER BY games

--17.	Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

WITH t1(Games, region, no_gold, no_silver, no_bronze, total_medal)
AS(SELECT Games, region, SUM (CASE WHEN medal = 'gold' THEN 1 ELSE 0 END) AS no_gold,
				SUM (CASE WHEN medal = 'silver' THEN 1 ELSE 0 END) AS no_silver,
				SUM (CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END) AS no_bronze,
				SUM(CASE WHEN medal IN ('gold', 'silver', 'bronze') THEN 1 ELSE 0 END) AS total_medal
FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY Games, region) 

SELECT Distinct Games,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_gold DESC)), 
		' - ', FIRST_VALUE (no_gold) OVER (PARTITION BY Games ORDER BY no_gold DESC)) AS Max_gold,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_silver DESC)),
		' - ', FIRST_VALUE (no_silver) OVER (PARTITION BY Games ORDER BY no_silver DESC)) AS Max_silver,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY no_bronze DESC)),
		' - ', FIRST_VALUE (no_bronze) OVER (PARTITION BY Games ORDER BY no_bronze DESC)) AS Max_bronze,
CONCAT ((FIRST_VALUE (region) OVER (PARTITION BY Games ORDER BY total_medal DESC)),
		' - ', FIRST_VALUE (total_medal) OVER (PARTITION BY Games ORDER BY total_medal DESC )) AS Total_no_medal
FROM t1
ORDER BY games

--18.	Which countries have never won gold medal but have won silver or bronze medals?

WITH t1 AS(SELECT region as Country, SUM (CASE WHEN medal = 'gold' THEN 1 ELSE 0 END) AS gold,
				SUM (CASE WHEN medal = 'silver' THEN 1 ELSE 0 END) AS silver,
				SUM (CASE WHEN medal = 'bronze' THEN 1 ELSE 0 END) AS bronze
FROM Projects..athlete_events AS o
JOIN Projects..noc_regions AS r
ON o.NOC = r.NOC
GROUP BY region
)

SELECT Country, gold, silver, bronze
FROM t1
WHERE gold = 0 AND (silver > 0 OR bronze > 0)
ORDER BY silver DESC, bronze DESC
