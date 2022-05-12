-- all actions by turn and session id
SELECT
  aid AS action,
  alog.qid AS turn,
  a_detail AS detail,
  sessionid 
FROM
  player_actions_log AS alog 
  INNER JOIN
    player_quests_log AS qlog 
    ON alog.dqid = qlog.dqid 
WHERE
  qlog.q_s_id = 1 
ORDER BY
  sessionid,
  alog.qid ASC;