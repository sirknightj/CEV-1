-- turn duration by session and turn number
SELECT
  ends.sessionid,
  ends.qid AS turn,
  ends.client_ts - starts.client_ts AS duration,
  ends.q_detail as detail
FROM
  (
    SELECT
      qid,
      sessionid,
      client_ts,
      q_detail
    FROM
      player_quests_log
    WHERE
      cid = 124
      AND q_s_id = 0
      AND sessionid NOT IN ('EXCLUDED')
      AND uid NOT IN ('EXCLUDED')
      AND log_q_ts > UNIX_TIMESTAMP('2022-05-16')
  ) AS ends,
  (
    SELECT
      qid,
      sessionid,
      client_ts
    FROM
      player_quests_log
    WHERE
      cid = 124
      AND q_s_id = 1
      AND sessionid NOT IN ('EXCLUDED')
      AND uid NOT IN ('EXCLUDED')
	  AND log_q_ts > UNIX_TIMESTAMP('2022-05-16')
  ) AS starts
WHERE
  ends.qid = starts.qid
  AND ends.sessionid = starts.sessionid
ORDER BY
  ends.sessionid,
  ends.qid ASC;