-- Извлекает информацию о последних визитах пользователей с источниками трафика
-- (utm_source, utm_medium, utm_campaign), которые привели к созданию сделок (leads).
-- Для каждого лида (lead_id) выбирается последний визит (сортировка по дате визита)
-- и связанная информация о сделке, такой как дата создания (created_at), сумма сделки (amount),
-- причина закрытия сделки (closing_reason) и статус сделки (status_id).
-- Запрос исключает визиты с источником 'organic' и использует ROW_NUMBER() для того, чтобы
-- оставить только последний визит для каждого лида.
-- Результат отсортирован по сумме сделки (amount), затем по дате визита (visit_date),
-- источникам (utm_source, utm_medium, utm_campaign)
WITH ranked_sessions AS (
    SELECT
        s.visitor_id,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.lead_id,
        l.created_at,
        l.amount,
        l.closing_reason,
        l.status_id,
        s.visit_date,
        ROW_NUMBER() OVER (
            PARTITION BY l.lead_id
            ORDER BY s.visit_date DESC
        ) AS row_num
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id
    WHERE s.medium != 'organic'
)

SELECT
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
FROM ranked_sessions
WHERE row_num = 1
ORDER BY
    amount DESC NULLS LAST, visit_date ASC, utm_source ASC, utm_medium ASC, utm_campaign ASC;
