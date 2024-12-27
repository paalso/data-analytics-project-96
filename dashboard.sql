-- Количество уникальных посетителей
SELECT COUNT(DISTINCT visitor_id) AS total_visitors
FROM sessions;


-- Количество различных источников
SELECT COUNT(DISTINCT source) AS unique_sources
FROM sessions;


-- Количество новых уникальных заявок (лидов)
SELECT COUNT(DISTINCT lead_id) AS total_leads
FROM leads;


-- Основные метрики по акции в целом (продажи через канал non-organic)
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
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(total_cost) AS total_cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(leads_count) * 100.0 / NULLIF(SUM(visitors_count), 0), 0) AS visitor_to_lead_conversion,
    ROUND(SUM(purchases_count) * 100.0 / NULLIF(SUM(leads_count), 0), 0) AS lead_to_purchase_conversion,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0) , 0) AS CPU,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0) , 0) AS CPL,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0) , 0) AS CPPL,
    ROUND((SUM(revenue) - SUM(total_cost)) * 100.0 / NULLIF(SUM(total_cost), 0) , 2) AS ROI
FROM aggregated_campaign_metrics;
-- visitors_count	leads_count	purchases_count	total_cost	revenue	visitor_to_lead_conversion	lead_to_purchase_conversion	cpu	    cpl	    cppl	roi
-- 38567	            706	            83	    4221484	    6271035	        1.8	                            11.8	        109	    5979	50861	0.49


-- Успешные продажи через канал organic
WITH
all_visitor_ids AS (
    SELECT DISTINCT visitor_id
    FROM sessions
),
non_organic_visitor_ids AS (
    WITH combined_ad_costs AS (
        SELECT
            utm_source,
            utm_medium,
            utm_campaign,
            DATE(campaign_date) AS campaign_date,
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
    )
    SELECT DISTINCT s.visitor_id
    FROM sessions AS s
    LEFT JOIN combined_ad_costs AS c
        ON DATE(s.visit_date) = c.campaign_date
        AND s.source = c.utm_source
        AND s.medium = c.utm_medium
        AND s.campaign = c.utm_campaign
    WHERE s.medium != 'organic'
),
organic_visitor_ids AS (
    SELECT visitor_id
    FROM all_visitor_ids
    EXCEPT
    SELECT visitor_id
    FROM non_organic_visitor_ids
),
organic_visitor_session_data AS (
    SELECT
        l.amount,
        s.visitor_id,
        l.lead_id,
        l.closing_reason,
        l.created_at,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.visitor_id IN (SELECT visitor_id FROM organic_visitor_ids)
)
SELECT
  visitor_id,
  lead_id,
  closing_reason,
  status_id,
  created_at,
  amount
FROM
  organic_visitor_session_data
WHERE rn = 1 AND amount > 0
ORDER BY amount DESC NULLS LAST;
-- visitor_id	                                lead_id	    closing_reason	    status_id	created_at	        amount
-- cc67c1f855c7cd738134f65c6b45ce2fdc40cfc1	47589182	Успешная продажа	142	        2023-06-22T08:26:20	268200
-- 883fe40b45518e8eebec57d815caffc4fa2c7993	16809544	Успешная продажа	142	        2023-06-29T13:39:51	265174
-- 6e3beb8fa268d1aab88fd93421814858bc7adee1	52245880	Успешная продажа	142	        2023-06-08T16:14:32	119200
-- 5d2683642dcff98da211cd761f5fdcdd88a4b2cc	75472581	Успешная продажа	142	        2023-06-23T14:04:47	100575
-- f898743145b52d2a52e6cc36ac82e3fa15adfe11	75075058	Успешная продажа	142	        2023-06-21T10:33:22	75684
-- 821429d5676a71d68895e38384286291a2c0d49a	25271105	Успешная продажа	142	        2023-06-29T01:01:08	63000
-- f2b7dca6f6eb7acbfb2a277a60fdbd24bc7778c7	24987160	Успешная продажа	142	        2023-06-21T05:38:28	62997
-- ff3ca2df5010110b6d047f9ab9dc4d6db2d26dcb	25838995	Успешная продажа	142	        2023-06-02T10:23:39	59226
-- b91372e5ceb7b8738ea5c43748fc0c11995e4bb9	52189091	Успешная продажа	142	        2023-06-09T13:42:12	53640
-- 11eb0da7a7819a8ccec93e7184766768db31aef8	23794591	Успешная продажа	142	        2023-06-20T16:07:18	31500
-- c218c073fbd8f2d275d9faaf8cf14824467c5bfd	70531938	Успешная продажа	142	        2023-06-22T00:53:33	9840
-- f139106583273079c5888dabb81c9d76ffc7de45	68203589	Успешная продажа	142	        2023-06-22T15:32:03	1560


-- Основные метрики в целом (продажи через канал organic)
WITH
all_visitor_ids AS (
    SELECT DISTINCT visitor_id
    FROM sessions
),
non_organic_visitor_ids AS (
    WITH combined_ad_costs AS (
        SELECT
            utm_source,
            utm_medium,
            utm_campaign,
            DATE(campaign_date) AS campaign_date,
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
    )
    SELECT DISTINCT s.visitor_id
    FROM sessions AS s
    LEFT JOIN combined_ad_costs AS c
        ON DATE(s.visit_date) = c.campaign_date
        AND s.source = c.utm_source
        AND s.medium = c.utm_medium
        AND s.campaign = c.utm_campaign
    WHERE s.medium != 'organic'
),
organic_visitor_ids AS (
    SELECT visitor_id
    FROM all_visitor_ids
    EXCEPT
    SELECT visitor_id
    FROM non_organic_visitor_ids
),
organic_visitor_session_data AS (
    SELECT
        l.amount,
        s.visitor_id,
        l.lead_id,
        l.closing_reason,
        l.created_at,
        l.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.visitor_id IN (SELECT visitor_id FROM organic_visitor_ids)
)
SELECT
    COUNT(DISTINCT visitor_id) AS visitors_count,
    COUNT(lead_id) AS leads_count,
    COUNT(CASE WHEN amount > 0 THEN 1 END) AS purchases_count,
    SUM(amount) AS total_revenue,
    ROUND(COUNT(lead_id) * 100.0 / NULLIF(COUNT(DISTINCT visitor_id), 0), 2) AS visitor_to_lead_conversion,
    ROUND(COUNT(CASE WHEN amount > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(lead_id), 0), 2) AS lead_to_purchase_conversion
FROM organic_visitor_session_data
WHERE rn = 1;
-- visitors_count	leads_count	purchases_count	total_revenue	visitor_to_lead_conversion	lead_to_purchase_conversion
-- 130573	        64	        12	            1110596	        0.05	                    18.75



-- Посещения сайта, в зависимости от канала трафика (utm_medium), с учетом organic
SELECT
    s.medium AS utm_medium,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
GROUP BY
    utm_medium
ORDER BY
    count DESC;


-- Посещения сайта, в зависимости от канала трафика (utm_medium) в динамике, с учетом organic по дням
SELECT
    s.medium AS utm_medium,
    EXTRACT(DAY FROM s.visit_date) AS date,
    EXTRACT(DAY FROM s.visit_date) || ' ' || TO_CHAR(s.visit_date, 'Dy') AS day,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
GROUP BY
    utm_medium,
    date,
    day
ORDER BY
    date ASC,
    count DESC;


-- Посещения сайта, в зависимости от канала трафика (utm_medium) в динамике, с учетом organic по неделям
SELECT
    DATE_PART('week', visit_date)::INT AS week,
    s.medium AS utm_medium,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
GROUP BY
    week,
    utm_medium
ORDER BY
    week, count DESC;


-- Посещения сайта, в зависимости от канала трафика (utm_medium), без учета organic
SELECT
    s.medium AS utm_medium,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    utm_medium
ORDER BY
    count DESC;


-- Посещения сайта, в зависимости от источника трафика (utm_source), без учета organic
SELECT
    s.source AS utm_source,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    utm_source
ORDER BY
    count DESC;


-- Посещения сайта, в зависимости от канала трафика (utm_medium) в динамике, без учета organic по дням
SELECT
    s.medium AS utm_medium,
    EXTRACT(DAY FROM s.visit_date) AS date,
    EXTRACT(DAY FROM s.visit_date) || ' ' || TO_CHAR(s.visit_date, 'Dy') AS day,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    utm_medium,
    date,
    day
ORDER BY
    date ASC,
    count DESC;


-- Посещения сайта, в зависимости от источника трафика (utm_source) в динамике, без учета organic по дням
SELECT
    s.source AS utm_source,
    EXTRACT(DAY FROM s.visit_date) AS date,
    EXTRACT(DAY FROM s.visit_date) || ' ' || TO_CHAR(s.visit_date, 'Dy') AS day,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    utm_source,
    date,
    day
ORDER BY
    date ASC,
    count DESC;


-- Посещения сайта, в зависимости от канала трафика (utm_medium) в динамике, без учета organic по неделям
SELECT
    DATE_PART('week', visit_date)::INT AS week,
    s.medium AS utm_medium,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    week,
    utm_medium
ORDER BY
    week, count DESC;


-- Посещения сайта, в зависимости от источник трафика (utm_source) в динамике, без учета organic по неделям
SELECT
    DATE_PART('week', visit_date)::INT AS week,
    s.source AS utm_source,
    COUNT(DISTINCT s.visitor_id) AS count
FROM sessions s
LEFT JOIN leads l
    ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
WHERE s.medium != 'organic'
GROUP BY
    week,
    utm_source
ORDER BY
    week, count DESC;


-- Распределение лидов по каналам трафика (utm_medium)
WITH visitor_session_data AS (
    SELECT
        s.medium AS utm_medium,
        l.lead_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_medium,
    COUNT(DISTINCT lead_id) AS leads_count
FROM visitor_session_data
WHERE rn = 1
GROUP BY utm_medium
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY leads_count DESC;


-- Распределение лидов по платным источникам трафика (utm_source)
WITH visitor_session_data AS (
    SELECT
        s.source AS utm_source,
        l.lead_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_source,
    COUNT(DISTINCT lead_id) AS leads_count
FROM visitor_session_data
WHERE rn = 1
GROUP BY utm_source
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY leads_count DESC;


-- Распределение лидов по маркетинговым компаниям
WITH visitor_session_data AS (
    SELECT
        s.campaign AS utm_campaign,
        l.lead_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_campaign,
    COUNT(DISTINCT lead_id) AS leads_count
FROM visitor_session_data
WHERE rn = 1
GROUP BY utm_campaign
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY leads_count DESC;


-- Сравнение посещений и лидов по платным источникам трафика (utm_source), конверсия из (последнего) клика в лид
WITH visitor_session_data AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        s.source AS utm_source,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_source,
    COUNT(DISTINCT s.visitor_id) AS visitors_count,
    COUNT(DISTINCT lead_id) AS leads_count,
    ROUND(
        (COUNT(DISTINCT lead_id) * 100.0) / COUNT(DISTINCT s.visitor_id),
        2
    ) AS conversion_percentage
FROM visitor_session_data s
WHERE rn = 1
GROUP BY utm_source
HAVING COUNT(DISTINCT lead_id) > 0
-- HAVING COUNT(DISTINCT s.visitor_id) > 0
ORDER BY visitors_count DESC;


-- Сравнение лидов и успешных сделок по платным источникам трафика (utm_source), конверсия из лида в оплату
WITH visitor_session_data AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        s.source AS utm_source,
        l.status_id,
        l.closing_reason,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_source,
    COUNT(DISTINCT lead_id) AS leads_count,
    COUNT(DISTINCT lead_id) FILTER (
        WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
    ) AS purchases_count,
    ROUND(
        (COUNT(DISTINCT lead_id) FILTER (
            WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
        ) * 100.0) / COUNT(DISTINCT lead_id),
        2
    ) AS conversion_percentage
FROM visitor_session_data
WHERE rn = 1
GROUP BY utm_source
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY leads_count DESC;


-- Сравнение посещений и лидов по платным источникам трафика (utm_campaign), конверсия из лида в оплату
WITH visitor_session_data AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        s.campaign AS utm_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_campaign,
    COUNT(DISTINCT s.visitor_id) AS visitors_count,
    COUNT(DISTINCT lead_id) AS leads_count,
    ROUND(
        (COUNT(DISTINCT lead_id) * 100.0) / COUNT(DISTINCT s.visitor_id),
        2
    ) AS conversion_percentage
FROM visitor_session_data s
WHERE rn = 1
GROUP BY utm_campaign
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY visitors_count DESC;


-- Сравнение лидов и успешных сделок по компаниям трафика (utm_campaign), конверсия из лида в оплату
WITH visitor_session_data AS (
    SELECT
        s.visitor_id,
        l.lead_id,
        s.campaign AS utm_campaign,
        l.status_id,
        l.closing_reason,
        ROW_NUMBER() OVER (
            PARTITION BY s.visitor_id
            ORDER BY s.visit_date DESC
        ) AS rn
    FROM sessions AS s
    LEFT JOIN leads AS l
        ON s.visitor_id = l.visitor_id AND s.visit_date <= l.created_at
    WHERE s.medium != 'organic'
)
SELECT 
    utm_campaign,
    COUNT(DISTINCT lead_id) AS leads_count,
    COUNT(DISTINCT lead_id) FILTER (
        WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
    ) AS purchases_count,
    ROUND(
        (COUNT(DISTINCT lead_id) FILTER (
            WHERE status_id = 142 OR closing_reason = 'Успешно реализовано'
        ) * 100.0) / COUNT(DISTINCT lead_id),
        2
    ) AS conversion_percentage
FROM visitor_session_data
WHERE rn = 1
GROUP BY utm_campaign
HAVING COUNT(DISTINCT lead_id) > 0
ORDER BY leads_count DESC;


-- Ежедневный отчет о результативности рекламы и посетителях
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
    visit_date
ORDER BY
    visit_date ASC;


-- Расходы и выручка по разным источникам (utm_source) в динамике без учета organic, по дням
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
    WHERE s.medium != organic
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
    COALESCE(SUM(total_cost), 0) AS total_cost,
    COALESCE(SUM(revenue), 0) AS revenue
FROM aggregated_campaign_metrics
GROUP BY
    visit_date,
    utm_source
HAVING COALESCE(SUM(total_cost), 0) + COALESCE(SUM(revenue), 0) > 0
ORDER BY
    visit_date,
    utm_source;


-- Анализ эффективности маркетинга в разрезе utm_source
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
),
aggregated_campaign_metrics AS (
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
    utm_source,
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(total_cost) AS total_cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(leads_count) * 100.0 / NULLIF(SUM(visitors_count), 0), 0) AS visitor_to_lead_conversion,
    ROUND(SUM(purchases_count) * 100.0 / NULLIF(SUM(leads_count), 0), 0) AS lead_to_purchase_conversion,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0) , 0) AS CPU,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0) , 0) AS CPL,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0) , 0) AS CPPL,
    ROUND((SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) , 2) AS ROI
FROM aggregated_campaign_metrics
GROUP BY
    utm_source
HAVING SUM(total_cost) > 0
ORDER BY
    utm_source;
-- utm_source	visitors_count	leads_count	purchases_count	total_cost	revenue	visitor_to_lead_conversion	lead_to_purchase_conversion	cpu	cpl	    cppl	roi
-- vk	            15600	        248	            15	      741947	1021005	        1.59	                    6.05	            48	2992	49463	37.6
-- yandex	        18444	        431	            67	      3479537	5098838	        2.34	                    15.55	            189	8073	51933	46.5



-- Анализ эффективности маркетинга в разрезе utm_medium
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
),
aggregated_campaign_metrics AS (
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
    utm_medium,
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(total_cost) AS total_cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(leads_count) * 100.0 / NULLIF(SUM(visitors_count), 0), 0) AS visitor_to_lead_conversion,
    ROUND(SUM(purchases_count) * 100.0 / NULLIF(SUM(leads_count), 0), 0) AS lead_to_purchase_conversion,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0) , 0) AS CPU,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0) , 0) AS CPL,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0) , 0) AS CPPL,
    ROUND((SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) , 2) AS ROI
FROM aggregated_campaign_metrics
GROUP BY
    utm_medium
HAVING SUM(total_cost) > 0
ORDER BY
    utm_medium;


-- Анализ эффективности маркетинга разрезе utm_campaign
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
),
aggregated_campaign_metrics AS (
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
    utm_campaign,
    SUM(visitors_count) AS visitors_count,
    SUM(leads_count) AS leads_count,
    SUM(purchases_count) AS purchases_count,
    SUM(total_cost) AS total_cost,
    SUM(revenue) AS revenue,
    ROUND(SUM(leads_count) * 100.0 / NULLIF(SUM(visitors_count), 0), 0) AS visitor_to_lead_conversion,
    ROUND(SUM(purchases_count) * 100.0 / NULLIF(SUM(leads_count), 0), 0) AS lead_to_purchase_conversion,
    ROUND(SUM(total_cost) / NULLIF(SUM(visitors_count), 0) , 0) AS CPU,
    ROUND(SUM(total_cost) / NULLIF(SUM(leads_count), 0) , 0) AS CPL,
    ROUND(SUM(total_cost) / NULLIF(SUM(purchases_count), 0) , 0) AS CPPL,
    ROUND((SUM(revenue) - SUM(total_cost)) / NULLIF(SUM(total_cost), 0) , 2) AS ROI
FROM aggregated_campaign_metrics
GROUP BY
    utm_campaign
HAVING COALESCE(SUM(revenue), 0) + COALESCE(SUM(total_cost), 0) > 0
ORDER BY
    revenue DESC NULLS LAST,
    total_cost DESC NULLS LAST;