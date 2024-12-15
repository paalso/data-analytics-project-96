SELECT
    s.visitor_id,
    s.visit_date,
    s.source AS utm_source,
    s.medium AS utm_medium,
    s.campaign AS utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
FROM sessions AS s
LEFT JOIN leads AS l
    ON s.visitor_id = l.visitor_id
order BY
    amount DESC NULLS LAST,
    visit_date,
    utm_source, utm_medium, utm_campaign
LIMIT 10;
