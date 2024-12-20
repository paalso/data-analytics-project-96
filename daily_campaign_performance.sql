/*
Запрос для анализа эффективности рекламных кампаний

Данный запрос объединяет данные из сессий пользователей (sessions), лидов (leads),
и затрат на рекламу (vk_ads и ya_ads). Он рассчитывает ключевые метрики:
 - Количество уникальных посетителей (visitors_count)
 - Затраты на кампанию (total_cost)
 - Количество лидов (leads_count)
 - Количество успешных сделок (purchases_count)
 - Доход (revenue)
 - Конверсии:
   * Посетители → Лиды (visitor_to_lead_conversion)
   * Лиды → Покупки (lead_to_purchase_conversion)

Метрики агрегируются по источникам, кампаниям, медиа и дням.
Дополнительно добавляется информация о неделе года для анализа тенденций.
*/

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
),
aggregated_campaign_metrics AS(
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(DISTINCT visitor_id) AS visitors_count,
        MIN(total_cost) AS total_cost,
        COUNT(DISTINCT lead_id) AS leads_count,
        COUNT(DISTINCT lead_id) FILTER (
            WHERE (status_id = 142) OR (closing_reason = 'Успешно реализовано')
        ) AS purchases_count,
        SUM(amount) AS revenue
    FROM visitor_session_data
    WHERE rn = 1
    GROUP BY
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
)
SELECT
    visit_date,
    DATE_PART('week', visit_date)::INT AS week,
    utm_source,
    utm_medium,
    utm_campaign,
    NULLIF(visitors_count, 0) AS visitors_count,
    NULLIF(total_cost, 0) AS total_cost,
    NULLIF(leads_count, 0) AS leads_count,
    NULLIF(purchases_count, 0) AS purchases_count,
    NULLIF(revenue, 0) AS revenue,
    NULLIF(ROUND(leads_count::NUMERIC / NULLIF(visitors_count, 0), 2), 0) AS visitor_to_lead_conversion,
    NULLIF(ROUND(purchases_count ::NUMERIC / NULLIF(leads_count, 0), 2), 0) AS lead_to_purchase_conversion
FROM aggregated_campaign_metrics
ORDER BY
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign;