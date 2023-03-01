-- Creating sample table named Upraised
DROP TABLE IF EXISTS `upraised`;

CREATE TABLE IF NOT EXISTS `upraised` (
  `USER_ID` INT,
  `ASS_ID` INT,
  `ACTION` varchar(30),
  `CREATEDAT` DATETIME
);

INSERT INTO `upraised` VALUES
  (1, 1, 'start', '2023-02-10 16:20:44'),
  (1, 1, 'end', '2023-02-10 17:21:44'),
  (1, 2, 'start', '2023-02-10 18:22:44'),
  (1, 2, 'end', '2023-02-10 19:23:44'),
  (1, 3, 'start', '2023-02-11 06:23:44'),
  (2, 1, 'start', '2023-02-10 15:18:44'),
  (2, 1, 'end', '2023-02-10 18:20:44'),
  (2, 2, 'start', '2023-02-10 16:19:44'),
  (2, 2, 'end', '2023-02-10 18:20:44'),
  (2, 3, 'start', '2023-02-10 20:20:44'),
  (2, 3, 'end', '2023-02-10 22:22:44');
  
  -- Task : 1.	Find the number of users working on an assignment at the current time.
  
WITH user_count AS 
	(
	SELECT *, COUNT(ass_id) OVER(PARTITION BY user_id,ass_id) as ass_count
	FROM upraised
	)
SELECT COUNT(DISTINCT user_id) as users_currently_working
FROM user_count
WHERE ass_count = 1;

-- Task : 2.	Measure the amount of hours spent by each user working on the assignment since the day they started 
-- 				(Accounting for the current period if she/he is working)

WITH CTE1 AS
(
  SELECT n.user_id as user_id, n.ass_id as ass_id,
  n.createdat as begin_time, o.createdat as end_time
  FROM upraised n
  JOIN upraised o
  ON o.user_id = n.user_id AND o.ass_id = n.ass_id 
  WHERE n.action <> o.action AND n.action <> 'end'
  ),
  CTE2 AS
(
SELECT *, COUNT(ass_id) OVER(PARTITION BY user_id,ass_id) as ass_count
FROM upraised
)
SELECT user_id, ass_id, timestampdiff(hour,createdat,current_timestamp())
FROM CTE2
WHERE ass_count = 1
UNION ALL
SELECT user_id, ass_id,
TIMESTAMPDIFF(hour, begin_time, end_time) as comp_time
FROM CTE1;

-- 3.	Identify the assignment that takes the maximum time to complete by the users.
SELECT MAX(timetaken), user_id, ass_id
  FROM (
  WITH CTE1 AS
(
  SELECT n.user_id as user_id, n.ass_id as ass_id,
  n.createdat as begin_time, o.createdat as end_time
  FROM upraised n
  JOIN upraised o
  ON o.user_id = n.user_id AND o.ass_id = n.ass_id 
  WHERE n.action <> o.action AND n.action <> 'end'
  ),
  CTE2 AS
(
SELECT *, COUNT(ass_id) OVER(PARTITION BY user_id,ass_id) as ass_count
FROM upraised
)
SELECT user_id, ass_id, timestampdiff(hour,createdat,current_timestamp()) as timetaken
FROM CTE2
WHERE ass_count = 1
UNION ALL
SELECT user_id, ass_id,
TIMESTAMPDIFF(hour, begin_time, end_time) as comp_time
FROM CTE1
  ) as FINAL;
  
  -- 4.	Write a query to get the following view as output,
-- user_id	assignment_1	assignment_2	assignment_3
-- 			
-- In the above view, rows will contain the user_id and time taken to complete assignment_1, assignment_2, assignment_3. 
-- Note
-- •	If the user has not started/completed the assignment, show empty value.
-- •	Assignment_1 column is where assignment_id=1 and respectively for others.

SELECT  user_id,
CASE WHEN ass_id = 1 THEN TimeTaken END  AS assignment_1,
CASE WHEN ass_id = 2 THEN TimeTaken END  AS assignment_2,
CASE WHEN ass_id = 3 THEN TimeTaken END  AS assignment_3
FROM 
(
	SELECT user_id, ass_id, begin_time,end_time,
	TIMESTAMPDIFF(hour,begin_time,end_time) as TimeTaken
	FROM (
		  SELECT n.user_id as user_id, n.ass_id as ass_id,
		  n.createdat as begin_time, o.createdat as end_time
		  FROM upraised n
		  JOIN upraised o
		  ON o.user_id = n.user_id AND o.ass_id = n.ass_id 
		  WHERE n.action <> o.action AND n.action <> 'end'
	UNION ALL
		  SELECT user_id, ass_id, createdat, NULL
		  FROM (  
				SELECT user_id, ass_id, createdat, NULL
				FROM (
					 SELECT *, COUNT(ass_id) OVER(PARTITION BY user_id,ass_id) as ass_count
					 FROM upraised) temp
                WHERE temp.ass_count = 1
				) temp2
		) temp3
)Final
Order By USER_ID;
