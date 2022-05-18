SELECT
    ends.sessionid AS sid,
    ends.qid AS turn,
    ends.log_q_ts - begins.log_q_ts AS duration
FROM
    player_quests_log AS ends
INNER JOIN
    (
        SELECT
            sessionid,
            MAX(qid) AS turn
        FROM
            player_quests_log
        WHERE
            cid = 124
        GROUP BY sessionid
    ) AS maxes
    ON
        ends.sessionid = maxes.sessionid
        AND ends.qid = maxes.turn
INNER JOIN
    (
        SELECT
            sessionid,
            log_q_ts
        FROM
            player_quests_log
        WHERE
            cid = 124
            AND qid = 1
            AND q_s_id = 0
    ) AS begins
    ON
        begins.sessionid = ends.sessionid
WHERE
    ends.sessionid NOT IN ('EXCLUDED')
    AND ends.cid = 124
    AND ends.uid NOT IN ('EXCLUDED')
    AND ends.q_s_id = 1
ORDER BY
    duration DESC
