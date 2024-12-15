SELECT * FROM sessions
LIMIT 5;

visitor_id                              |visit_date             |landing_page                                               |source  |medium |campaign|content|
----------------------------------------+-----------------------+-----------------------------------------------------------+--------+-------+--------+-------+
6c46bf453b523a09844679863f557198ef8b8359|2023-06-14 15:37:06.006|https://foobar.com/61b59bd26816178a290e497b7d7eab0695e6d574|admitad |cpa    |admitad |442763 |
b8a9c619973434b33109be9a126ab60ebd640516|2023-06-14 16:09:36.593|https://foobar.com/2c4fa528c48567b6d4b9a515723d586a9fe27c56|bing.com|organic|        |       |
76f728ff950cd62469a85799be5ccd09f00e8a40|2023-06-14 18:08:56.758|https://foobar.com/941e0b70c1a90f68e93f34f2b0aa26bbe8850b7a|bing.com|organic|        |       |
74e9f618b7aed1757a5e9a960c6feb7e2c366bb4|2023-06-14 16:29:23.581|https://foobar.com/86fcb2036bd59132cd5860642a462b970a59ddaf|bing.com|organic|        |       |
eb8f4489420ea02653f97b03e602320e7e76386c|2023-06-14 17:31:19.250|https://foobar.com/ba19197344427eddba85eb191ca8bd0f2871fb7e|bing.com|organic|        |       |


count |
------+
233342|


source                                            |
--------------------------------------------------+
partners                                          |
yandex.com                                        |
go.mail.ru                                        |
telegram Этот курс побеждён! 💪💪💪 Было круто! 🚀|
vkontakte                                         |
instagram                                         |
.......

campaign                                                                              |
--------------------------------------------------------------------------------------+
                                                                                      |
base                                                                                  |
na-hekslete-poyavilas-novaya-professiya-v                                             |
freemium-python                                                                       |
prof-fullstack                                                                        |
my-sozdali-kurs-osnovy-redis-pro-rabot                                                |
dod-frontend                                                                          |
python                                                                                |
77386453                                                                              |
grokaem_algoritmy                                                                     |
.........


content                                                 |
--------------------------------------------------------+
habr                                                    |
                                                        |
qa-sisters-it-soobschestva-eto-novye-profsoyuzy         |
rsy_msc.segment_keys.nabor_060623                       |
28854830_4bn9b5                                         |
129852                                                  |
hr.post                                                 |
...........

-- =================================================================================================================================================

SELECT * FROM leads
LIMIT 5;

visitor_id                              |lead_id|amount|created_at             |closing_reason|learning_format|status_id|
----------------------------------------+-------+------+-----------------------+--------------+---------------+---------+
ae38c0e19418ad892d6fbbd28a25d19d178937dd|2385138|     0|2023-06-23 10:46:08.000|Не реализовано|group          |      143|
a7c62730ab31f476e3d50997844a67c1ef15f30d|2441927|     0|2023-06-15 01:58:41.000|Не реализовано|group          |      143|
5f5d05db620866b11f4bf422a179193e6f72fa25|2498716|     0|2023-06-16 16:43:34.000|Не реализовано|group          |      143|
cb6e250f0c10f26c2323cd73082ece332425b616|2555505|     0|2023-06-07 13:30:13.000|Не реализовано|group          |      143|
acd4587c2fcfff951bbf19d65d8e9a6554d6a35a|2612294|     0|2023-06-13 16:24:13.000|Не реализовано|group          |      143|

SELECT COUNT(*) FROM leads;
count
-----
 1300


SELECT COUNT(DISTINCT visitor_id) FROM leads;
count|
-----+
 1300|


SELECT DISTINCT(closing_reason) FROM leads;
closing_reason  |
----------------+
В работе        |
Не реализовано  |
Успешная продажа|


SELECT DISTINCT(learning_format) FROM leads;
learning_format|
---------------+
premium        |
base           |
bootcamp       |
group          |


SELECT DISTINCT(status_id) FROM leads;
status_id|
---------+
      141|
      142|
      143|



-- =================================================================================================================================================

SELECT * FROM vk_ads
LIMIT 5;

ad_id                                   |ad_name                                   |campaign_id                             |campaign_name  |campaign_date          |daily_spent|utm_source|utm_medium|utm_campaign   |utm_content                  |
----------------------------------------+------------------------------------------+----------------------------------------+---------------+-----------------------+-----------+----------+----------+---------------+-----------------------------+
40066cae1fb77ea907928f938dc6a85a232bd305|segm-2.5 | cpc auto | img1 universal+snip1|c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python|2023-06-26 00:00:00.000|        449|vk        |cpc       |freemium-python|traffic_ru.segment_segment-25|
40066cae1fb77ea907928f938dc6a85a232bd305|segm-2.5 | cpc auto | img1 universal+snip1|c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python|2023-06-19 00:00:00.000|        579|vk        |cpc       |freemium-python|traffic_ru.segment_segment-25|
40066cae1fb77ea907928f938dc6a85a232bd305|segm-2.5 | cpc auto | img1 universal+snip1|c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python|2023-06-03 00:00:00.000|        596|vk        |cpc       |freemium-python|traffic_ru.segment_segment-25|
40066cae1fb77ea907928f938dc6a85a232bd305|segm-2.5 | cpc auto | img1 universal+snip1|c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python|2023-06-11 00:00:00.000|        156|vk        |cpc       |freemium-python|traffic_ru.segment_segment-25|
40066cae1fb77ea907928f938dc6a85a232bd305|segm-2.5 | cpc auto | img1 universal+snip1|c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python|2023-06-05 00:00:00.000|        372|vk        |cpc       |freemium-python|traffic_ru.segment_segment-25|

SELECT COUNT(*) FROM vk_ads;
count|
-----+
 1326|


SELECT DISTINCT(ad_name)
FROM vk_ads;
ad_name                                                  |
---------------------------------------------------------+
lal-sub_obsh(250k) | cpc auto | img31 universal+snip2    |
lal-hex | cpc auto | img32 universal+snip2               |
lal-sub_obsh(50k) | cpc auto | img28 universal+snip1     |
keys-potreb | cpc auto | img29 universal+snip1           |
lal_sub_obsh(50k) | cpc hand | img27 universal+snip1     |
...........


SELECT COUNT(DISTINCT(ad_name)) FROM vk_ads;
count|
-----+
  191|


SELECT COUNT(DISTINCT ad_name)
FROM vk_ads;
count|
-----+
  191|


SELECT DISTINCT campaign_id, campaign_name
FROM vk_ads;
campaign_id                             |campaign_name           |
----------------------------------------+------------------------+
30565bc607672f60f57dfe388a3f82732c9cc49d|Профессия Frontend      |
9ee8195b47d1c481b9586349f29dc11f505d872f|Base P                  |
dabe329def305563508e67d5b5aeae8a4a82e0c6|Freemium_Java           |
58ce3c3a4c1d98685cb13bd52e1a9af1bb462118|Freeemium_Frontend      |
e303ed18d75849d947bed7730124d255efd725b7|Профессия Java          |
c51b2d5038aa064bd4f43813d1a46d82b857da19|Freemium_Python         |
ca4ab8c6cc2fb0a15539154f783e0b682fde25ef|Профессия Data Analytics|
ad3092397a674ecdb0044d6fbd03b2143d75db0a|Профессия Python        |


SELECT DISTINCT utm_source FROM vk_ads;
utm_source|
----------+
vk        |


SELECT DISTINCT utm_medium FROM vk_ads;
utm_medium|
----------+
cpc       |
cpm       |


-- =================================================================================================================================================

SELECT * FROM ya_ads
LIMIT 5;

ad_id                                   |campaign_id                             |campaign_name                       |utm_source|utm_medium|utm_campaign             |utm_content               |campaign_date          |daily_spent|
----------------------------------------+----------------------------------------+------------------------------------+----------+----------+-------------------------+--------------------------+-----------------------+-----------+
8155246d768e0f6592d3f03b69f277c69be54842|b47a3f1436ece217553332a7ca2aeb8c23a2ff16|Professions / Retarget (smartbanner)|yandex    |cpc       |prof-professions-retarget|rsy_ru.segment_smartbanner|2023-06-20 00:00:00.000|        546|
8155246d768e0f6592d3f03b69f277c69be54842|b47a3f1436ece217553332a7ca2aeb8c23a2ff16|Professions / Retarget (smartbanner)|yandex    |cpc       |prof-professions-retarget|rsy_ru.segment_smartbanner|2023-06-29 00:00:00.000|        198|
8155246d768e0f6592d3f03b69f277c69be54842|b47a3f1436ece217553332a7ca2aeb8c23a2ff16|Professions / Retarget (smartbanner)|yandex    |cpc       |prof-professions-retarget|rsy_ru.segment_smartbanner|2023-06-19 00:00:00.000|        392|
8155246d768e0f6592d3f03b69f277c69be54842|b47a3f1436ece217553332a7ca2aeb8c23a2ff16|Professions / Retarget (smartbanner)|yandex    |cpc       |prof-professions-retarget|rsy_ru.segment_smartbanner|2023-06-11 00:00:00.000|        815|
8155246d768e0f6592d3f03b69f277c69be54842|b47a3f1436ece217553332a7ca2aeb8c23a2ff16|Professions / Retarget (smartbanner)|yandex    |cpc       |prof-professions-retarget|rsy_ru.segment_smartbanner|2023-06-05 00:00:00.000|        730|
