{{
  config(
    materialized='incremental',
    unique_key=['user_pseudo_id_hashed', 'iap_journey'],
    cluster_by=['user_pseudo_id_hashed', 'iap_journey']
  )
}}

SELECT
    s2.event_date AS login_date,
    s1.user_pseudo_id_hashed,
    STRING_AGG(
        product_id,
        ' > ' ORDER BY s1.event_timestamp
    ) AS iap_journey
FROM {{ ref('stg_in_app_purchase') }} s1
JOIN (SELECT user_pseudo_id_hashed, event_date
    FROM  {{ ref('stg_first_open') }}
    WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY) AND CURRENT_DATE()
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_pseudo_id_hashed ORDER BY event_timestamp DESC
    ) = 1) s2
    ON s1.user_pseudo_id_hashed = s2.user_pseudo_id_hashed
    AND s1.event_date >= s2.event_date
GROUP BY login_date, user_pseudo_id_hashed
