-- Извлекает последние визиты пользователей, которые привели к сделкам.
-- Для каждого лида выбирается последний визит, сортировка по дате.
-- Информация о сделке включает
-- дату создания, сумму, причину закрытия и статус.
-- Визиты с источником 'organic' исключены. Используется ROW_NUMBER() для
-- выбора последнего визита. Результат отсортирован по сумме сделки, дате
-- визита и источникам трафика (utm_source, utm_medium, utm_campaign).
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
    amount DESC NULLS LAST,
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
