-- turn duration by session and turn number
SELECT
  q1.sessionid,
  q1.qid AS turn,
  q1.log_q_ts - q2.log_q_ts AS duration
FROM
  player_quests_log AS q1,
  player_quests_log AS q2
WHERE
  q1.qid = q2.qid
  AND q1.sessionid = q2.sessionid
  AND q1.q_s_id < q2.q_s_id
  AND q1.cid = 124
  AND q2.cid = 124
ORDER BY
  q1.sessionid,
  q1.qid ASC;
