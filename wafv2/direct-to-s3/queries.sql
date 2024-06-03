-- Permission is hereby granted, free of charge, to any person obtaining a copy of this
-- software and associated documentation files (the "Software"), to deal in the Software
-- without restriction, including without limitation the rights to use, copy, modify,
-- merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
-- PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- For LICENSE information, plese check the source repository:
-- https://github.com/lazize/athena-for-aws-service
--
-- The opinions expressed in this repository and code are my own and not necessarily those of my employer (past, present and future).

--------------------------------------------------------------------------------------

-- More examples on link below
-- https://docs.aws.amazon.com/athena/latest/ug/waf-logs.html#query-examples-waf-logs
--
-- Presto SELECT documentation
-- https://prestodb.io/docs/current/sql/SELECT.html
--
-- Trino functions
-- https://trino.io/docs/current/functions.html
-- 
-- MUST use table with partition based on pattern 'yyyy/MM/dd/HH/mm'
--
-- ATTENTION: Please make sure you are using Athena engine version 3
-- #############################################################


-- Client IP requests inside a time range
SELECT
  COUNT(*) AS count,
  httprequest.clientip
FROM waf_logs
WHERE (date >= '2023/01/06/00/00' and date <= '2023/06/06/23/59')
GROUP BY httprequest.clientip
ORDER BY count DESC, httprequest.clientip ASC


-- Use CIDR to filter
-- Function from Trino, works fine with Athena version 3
SELECT httprequest.clientip
FROM waf_logs
WHERE (date >= '2023/06/01' AND date <= '2023/06/14')
  AND contains('18.68.1.0/24', CAST(httprequest.clientip AS IPADDRESS))


-- Specific Request ID
SELECT *
FROM waf_logs
WHERE httprequest.requestid='1-62d363b0-782fbba84b18907e79a06698'
ORDER BY timestamp DESC


-- Possible actions
SELECT distinct(action)
FROM waf_logs


-- Possible Terminating Rule Types
SELECT distinct(terminatingruletype)
FROM waf_logs


-- BLOCKed requests
-- It is case-sensitive
SELECT *
FROM waf_logs
WHERE action = 'BLOCK'
ORDER BY timestamp DESC


-- Latest N logs
SELECT from_unixtime(timestamp / 1000) AS unixtime,
       *
FROM waf_logs
ORDER BY timestamp DESC
LIMIT 100


-- Count Client IP FROM all logs
SELECT httprequest.clientip, 
       count(httprequest.clientip) AS count
FROM waf_logs
GROUP BY httprequest.clientip
ORDER BY count DESC


-- Count Client IP by Date FROM all logs
SELECT date,
       httprequest.clientip,
       count(httprequest.clientip) AS count
FROM waf_logs
GROUP BY date, httprequest.clientip
ORDER BY date DESC, count DESC


-- Count requests grouped by Termination Rule ID
SELECT terminatingruleid,
       count(*) AS count
FROM waf_logs
GROUP BY terminatingruleid
ORDER BY count DESC


-- From specific IP and action
SELECT *
FROM waf_logs
WHERE httprequest.clientip = '18.68.1.83'
  AND action = 'BLOCK'
ORDER BY timestamp


-- BLOCKed request that were terminated by managed rule group
-- Show the rule ID from rule group that terminated the request
SELECT from_unixtime(timestamp/1000) AS timestamp,
       terminatingruletype,
       terminatingruleid,
       filter(rulegrouplist, x -> x.terminatingrule IS NOT NULL)[1].terminatingrule.ruleid AS ruleid,
       httprequest.clientip AS clientip,
       httprequest.uri AS uri,
       httprequest.args AS args
FROM waf_logs
WHERE action = 'BLOCK'
  AND terminatingruletype = 'MANAGED_RULE_GROUP'
ORDER BY timestamp


-- Requests that matches 'rate-limit-count' rule and counted it,
-- as it is a rate based rule it will only count if the amount of requests
-- are higher than the defined limit.
SELECT ACTION, COUNT(*)
FROM (
    SELECT from_unixtime(timestamp/1000) AS unixtime,
           terminatingruleid,
           terminatingruletype,
           action,
           terminatingrulematchdetails,
           ratebasedrulelist,
           nonterminatingmatchingrules,
           requestheadersinserted,
           responsecodesent,
           httprequest,
           labels
    FROM waf_logs
    WHERE date = '2023/06/27'
      AND any_match(nonterminatingmatchingrules, x -> (x.ruleid = 'rate-limit-count') AND (x.action = 'COUNT'))
    ORDER BY timestamp DESC
)
GROUP BY action
ORDER BY action


-- IPs from 5 minutes interval
SELECT format_datetime(from_unixtime((timestamp/1000) - ((minute(from_unixtime(timestamp / 1000))%5) * 60)),'yyyy-MM-dd HH:mm') AS timerange,
       httprequest.clientip,
       COUNT(*) AS ip_count
FROM waf_logs
WHERE date >= '2023/06/01/00/00' AND date < '2023/06/31/23/59'
GROUP BY 1, httprequest.clientip
ORDER BY ip_count DESC


-- IPs from 1 minute interval
SELECT date_trunc('minute', from_unixtime(timestamp / 1000)) AS timerange,
       httprequest.clientip,
       COUNT(*) AS ip_count
FROM waf_logs
WHERE date >= '2023/06/01/00/00' AND date < '2023/06/31/23/59'
GROUP BY 1, httprequest.clientip
ORDER BY ip_count DESC
