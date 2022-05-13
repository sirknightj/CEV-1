-- dropoff graph: turn start, time from start of game, and sessionid
SELECT
  q1.sessionid,
  q1.qid AS turn,
  q1.log_q_ts - q2.log_q_ts as start_ts
FROM
  player_quests_log AS q1
  LEFT JOIN
	player_quests_log as q2
	ON q1.sessionid = q2.sessionid
WHERE
  q1.q_s_id = 1
  AND q2.q_s_id = 1
  AND q2.qid = 1
ORDER BY
  q1.sessionid,
  q1.qid ASC;