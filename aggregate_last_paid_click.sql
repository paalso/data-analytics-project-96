WITH
vk_costs AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        DATE(campaign_date) AS campaign_date,
        SUM(daily_spent) AS sum
    FROM vk_ads
    GROUP BY DATE(campaign_date), utm_source, utm_medium, utm_campaign
),
ya_costs AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        DATE(campaign_date) AS campaign_date,
        SUM(daily_spent) AS sum
    FROM ya_ads
    GROUP BY DATE(campaign_date), utm_source, utm_medium, utm_campaign
),
tab AS (
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
        COALESCE(vk_costs.sum, 0) + COALESCE(ya_costs.sum, 0) AS total_cost,
        ROW_NUMBER()
            OVER (
                PARTITION BY s.visitor_id
                ORDER BY s.visit_date DESC
            )
        AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    LEFT JOIN vk_costs
        ON
            DATE(s.visit_date) = DATE(vk_costs.campaign_date)
            AND s.source = vk_costs.utm_source
            AND s.medium = vk_costs.utm_medium
            AND s.campaign = vk_costs.utm_campaign
    LEFT JOIN ya_costs
        ON
            DATE(s.visit_date) = DATE(ya_costs.campaign_date)
            AND s.source = ya_costs.utm_source
            AND s.medium = ya_costs.utm_medium
            AND s.campaign = ya_costs.utm_campaign
    WHERE s.medium != 'organic'
)
SELECT
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    COUNT(DISTINCT visitor_id) AS visitors_count,
    NULLIF(MIN(total_cost), 0) AS total_cost,
    NULLIF(COUNT(DISTINCT lead_id), 0) AS leads_count,
    NULLIF(
        COUNT(DISTINCT lead_id) FILTER (
            WHERE (status_id = 142) OR (closing_reason = 'Успешно реализовано')
        ),
        0
    ) AS purchases_count,
    NULLIF(SUM(amount), 0) AS revenue
FROM tab
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
