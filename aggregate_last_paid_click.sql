-- Рассчитывает ключевые метрики по рекламным кампаниям в разрезе
-- дат, источников, типов трафика и кампаний:  
-- - Уникальные посетители (visitors_count)  
-- - Затраты на рекламу (total_cost)  
-- - Лиды (leads_count)  
-- - Успешные сделки (purchases_count)  
-- - Доход (revenue)  
-- Используется модель Last Paid Click — метрики привязываются к последней
-- сессии перед регистрацией.  
-- Данные о расходах объединяются из источников `vk_ads` и `ya_ads`.  
WITH
combined_ad_costs AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date,
        SUM(daily_spent) AS total_cost
    FROM (
        SELECT
            utm_source,
            utm_medium,
            utm_campaign,
            DATE(campaign_date) AS campaign_date,
            daily_spent
        FROM vk_ads
        UNION ALL
        SELECT
            utm_source,
            utm_medium,
            utm_campaign,
            DATE(campaign_date) AS campaign_date,
            daily_spent
        FROM ya_ads
    ) AS all_ads
    GROUP BY DATE(campaign_date), utm_source, utm_medium, utm_campaign
),
visitor_session_data AS (
    SELECT
        s.visit_date AS original_date,
        s.visitor_id,
        l.lead_id,
        s.source AS utm_source,
        s.medium AS utm_medium,
        s.campaign AS utm_campaign,
        l.amount,
        l.closing_reason,
        l.created_at,
        l.status_id,
        DATE(s.visit_date) AS visit_date,
        combined_ad_costs.total_cost AS total_cost,
        ROW_NUMBER()
            OVER (
                PARTITION BY s.visitor_id
                ORDER BY s.visit_date DESC
            )
        AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    LEFT JOIN combined_ad_costs
        ON
            DATE(s.visit_date) = DATE(combined_ad_costs.campaign_date)
            AND s.source = combined_ad_costs.utm_source
            AND s.medium = combined_ad_costs.utm_medium
            AND s.campaign = combined_ad_costs.utm_campaign
    WHERE s.medium != 'organic'
)
SELECT
    visit_date,
    COUNT(DISTINCT visitor_id) AS visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    NULLIF(MIN(total_cost), 0) AS total_cost,
    NULLIF(COUNT(DISTINCT lead_id), 0) AS leads_count,
    NULLIF(
        COUNT(DISTINCT lead_id) FILTER (
            WHERE (status_id = 142) OR (closing_reason = 'Успешно реализовано')
        ),
        0
    ) AS purchases_count,
    NULLIF(SUM(amount), 0) AS revenue
FROM visitor_session_data
WHERE rn = 1
GROUP BY
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    leads_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;
