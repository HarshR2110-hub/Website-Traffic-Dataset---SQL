create database Final_project;
use Final_project;
create table if not exists Device(
Device_key int(10),
Device_name varchar(50),
Content_segment varchar(100),
Device_browser varchar(500));

SET SESSION sql_mode = ' ';

load data infile
"D:\Device_Lookup.csv"
into table Device
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from Device;

create table if not exists Geo(
Location_key int(50),
Location_name varchar(100),
Location_country varchar(100),
Location_region varchar(100),
Location_city varchar(100));


load data infile
"D:\Geo_Lookup.csv"
into table Geo
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;



create table if not exists Source(
Source_key int(50),
Source_name varchar(50),
Source_type varchar(50),
Source_campaign varchar(100));

load data infile
"D:\Source_Lookup.csv"
into table source
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;



create table if not  exists Website_traffic_data(
Session_id int(100),
Sate_key varchar(500),
source_key int(100),
Device_key int(100),
Location_key int(100),
Session_duration int(100),
page_view_per_session int(100));

load data infile
"D:\Website_Traffic_Data.csv"
into table Website_traffic_data
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from Device;
select  * from Geo;
select * from source;
select * from Website_traffic_data;


#### Query = 01 ####
--- Session Duration & Page Views - DeviceType ---

select Website_traffic_data.Session_duration,Website_traffic_data.page_view_per_session,
 device.Device_name as  device_type from device inner join Website_traffic_data on
 device.device_key = 
 Website_traffic_data.device_key;
 
 ### How to get Bounce Rate ###
 SELECT 
    COUNT(CASE WHEN page_view_per_session = 1 THEN 1 END) * 1.0 / COUNT(*) AS bounce_rate
FROM 
    Website_traffic_data;
 
 #### Query = 02 ####
--- Bounce Rate by Content Segment ---
 
SELECT
    d.Device_name,  -- Device used by the user
    COUNT(DISTINCT wtd.Session_id) AS total_sessions,  -- Total number of sessions
    COUNT(DISTINCT CASE WHEN wtd.page_view_per_session = 1 THEN wtd.Session_id END)
    AS bounced_sessions,  -- Bounced sessions (only 1 page view)
    (COUNT(DISTINCT CASE WHEN wtd.page_view_per_session = 1 THEN wtd.Session_id END) / COUNT(DISTINCT wtd.Session_id))
    * 100 AS bounce_rate_percentage  -- Bounce rate percentage
FROM
    Website_traffic_data wtd
LEFT JOIN
    Device d ON wtd.Device_key = d.Device_key  -- Joining the Device table to get the Device_name
LEFT JOIN
    Geo g ON wtd.Location_key = g.Location_key  -- Optionally, join the Geo table if you want location data
LEFT JOIN
    Source s ON wtd.source_key = s.Source_key  -- Optionally, join the Source table if you want source data
GROUP BY
    d.Device_name;  -- Grouping by Device_name (this can be changed to other segments)


### Query = 03 ###
--- Session Duration and Page Views- Traffic Source ---

select Website_traffic_data.session_duration, Source.source_name from source inner join
Website_traffic_data on Website_traffic_data.Session_id = Source.Source_key;


### Query = 04 ###
--- Bounce Rate by Device Type ---

SELECT 
  d.Device_name,
  COUNT(*) AS total_sessions,
  SUM(CASE WHEN w.page_view_per_session = 1 THEN 1 ELSE 0 END) AS bounced_sessions,
  ROUND(
    100.0 * SUM(CASE WHEN w.page_view_per_session = 1 THEN 1 ELSE 0 END) / COUNT(*), 
    2
  ) AS bounce_rate_percentage
FROM Website_traffic_data w
JOIN Device d ON w.Device_key = d.Device_key
GROUP BY d.Device_name;

--------------------------- with window functionn------------------------------------------

SELECT 
  d.Device_name,
  w.Session_id,
  w.page_view_per_session,
  CASE WHEN w.page_view_per_session = 1 THEN 'Bounce' ELSE 'Engaged' END AS session_type,
  COUNT(*) OVER (PARTITION BY d.Device_name) AS total_sessions_per_device
FROM Website_traffic_data w
JOIN Device d ON w.Device_key = d.Device_key;


##### Query - 5 ######
--- Bounce Rate by Website Traffic Source ---

SELECT 
    s.Source_name,
    s.Source_type,
    s.Source_campaign,
    COUNT(wtd.Session_id) AS total_sessions,
    COUNT(CASE WHEN wtd.page_view_per_session = 1 THEN 1 END) * 1.0 / COUNT(wtd.Session_id) AS bounce_rate
FROM 
    Website_traffic_data wtd
JOIN 
    Source s ON wtd.Source_key = s.Source_key
GROUP BY 
    s.Source_name, s.Source_type, s.Source_campaign
ORDER BY 
    bounce_rate DESC;
    
    
### Query - 6 ###
--- Bounce Rate by Different Browser ---

SELECT Device.Device_browser,
    COUNT(CASE WHEN page_view_per_session = 1 THEN 1 END) * 1.0 / COUNT(*) AS bounce_rate
FROM 
    Website_traffic_data left join Device on Device.Device_Key = Website_traffic_data.source_key
    group by Device.Device_browser ;

##### Query - 7 #####
--- Total Session Duration (Hrs) - Trend for Device Types ---

SELECT Device_name,
    SUM(wtd.Session_duration) / 3600.0 AS total_session_duration_hours
FROM 
    Website_traffic_data wtd
JOIN 
    Device d ON wtd.Device_key = d.Device_key
    group by Device_name
ORDER BY 
     d.Device_name;
     
#### Query 8  ####
---- Total Session Duration (Hrs) - Trend for Website Traffic Source ---- 

SELECT
    s.Source_name,
    s.Source_type,
    s.Source_campaign,
    SUM(wtd.Session_duration) / 3600.0 AS total_session_duration_hours
FROM 
    Website_traffic_data wtd
JOIN 
    Source s ON wtd.Source_key = s.Source_key
GROUP BY 
    s.Source_name, s.Source_type, s.Source_campaign
ORDER BY 
    total_session_duration_hours DESC;
    
    
###### Query 9 #####
---- Average Session Duration (Hrs) - Overall Trend -----

SELECT 
    AVG(Session_duration) / 3600.0 AS average_session_duration_hours
FROM 
    Website_traffic_data;

----  If we want to get avg session duration for Campaign -----
SELECT
    s.Source_campaign,
    AVG(wtd.Session_duration) / 3600.0 AS average_session_duration_hours
FROM 
    Website_traffic_data wtd
JOIN 
    Source s ON wtd.Source_key = s.Source_key
GROUP BY 
    s.Source_campaign
ORDER BY 
    average_session_duration_hours DESC;


#### Query 10 ####
----   Bounce Rate - Monthly Trend  -----

### Add a session_date Column  ####
ALTER TABLE Website_traffic_data
ADD session_date DATE;

### Populate session_date with Sample Dates  ###
UPDATE Website_traffic_data
SET session_date = DATE_ADD('2020-03-01', INTERVAL FLOOR(RAND() * 365) DAY);


### Query for Monthly Bounce Rate Trend  ###
SELECT 
    DATE_FORMAT(session_date, '%Y-%m') AS month,
    COUNT(CASE WHEN page_view_per_session = 1 THEN 1 END) * 100.0 / COUNT(*) AS bounce_rate_percentage
FROM 
    Website_traffic_data
GROUP BY 
    DATE_FORMAT(session_date, '%Y-%m')
ORDER BY 
    month;


###  Query 11  ###
--- Bounce Rate - Daily Trend ---

SELECT 
    session_date,
    COUNT(CASE WHEN page_view_per_session = 1 THEN 1 END) * 100.0 / COUNT(*) AS bounce_rate_percentage
FROM 
    Website_traffic_data
GROUP BY 
    session_date
ORDER BY 
    session_date;
    
    
### Query 12 ###
--- Total Page Views - Regionwise ---

SELECT
    g.Location_region,
    SUM(wtd.page_view_per_session) AS total_page_views
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_region
ORDER BY
    total_page_views DESC;


### Query 13 ###
--- Total Session Duration - Regionwise  ---

SELECT
    g.Location_region,
    SUM(wtd.Session_duration) / 3600.0 AS total_session_duration_hours
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_region
ORDER BY
    total_session_duration_hours DESC;


### Query 14 ###
---- Bounce Rate - Regionwise----

SELECT
    g.Location_region,
    COUNT(CASE WHEN wtd.page_view_per_session = 1 THEN 1 END) * 100.0 / COUNT(*) AS bounce_rate_percentage
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_region
ORDER BY
    bounce_rate_percentage DESC;
    
    
#### Query 15 ####
---- Total Number of Sessions - Top 5 Cities ---

SELECT
    g.Location_city,
    COUNT(wtd.Session_id) AS total_sessions
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_city
ORDER BY
    total_sessions DESC
LIMIT 5;


#### Query 16 ####
--- Total Session Duration - Top 5 Cities ---

SELECT
    g.Location_city,
    SUM(wtd.Session_duration) / 3600.0 AS total_session_duration_hours
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_city
ORDER BY
    total_session_duration_hours DESC
LIMIT 5;

#### Query 17 ####
---  Total Page Views -Top 5 Cities  ---
SELECT
    g.Location_city,
    SUM(wtd.page_view_per_session) AS total_page_views
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_city
ORDER BY
    total_page_views DESC
LIMIT 5;

### Query 18 ###
---- Bounce Rate - Top 5 Cities  ---- 
SELECT
    g.Location_city,
    COUNT(CASE WHEN wtd.page_view_per_session = 1 THEN 1 END) * 100.0 / COUNT(*) AS bounce_rate_percentage
FROM
    Website_traffic_data wtd
JOIN
    Geo g ON wtd.Location_key = g.Location_key
GROUP BY
    g.Location_city
ORDER BY
    bounce_rate_percentage DESC
LIMIT 5;











