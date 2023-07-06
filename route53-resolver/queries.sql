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
-- https://github.com/lazize/aws-cli-helper
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
-- MUST use table with partition based on pattern 'yyyy/MM/dd'
--
-- ATTENTION: Please make sure you are using Athena engine version 3
-- #############################################################

-- All logs
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
ORDER BY query_timestamp DESC


-- Only requests with ALERT rule configured
-- ATTENTION: It will scan all files!
SELECT firewall_domain_list_id,
       COUNT(*) AS count
FROM r53_rlogs
WHERE firewall_rule_action = 'ALERT'
GROUP BY firewall_domain_list_id
ORDER BY count DESC


-- Only requests with BLOCK rule configured
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
WHERE firewall_rule_action = 'BLOCK'
ORDER BY query_timestamp DESC


-- Request that didn't match any configured rule action
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
WHERE firewall_rule_action is NULL


-- Requests with some specific domain list match. "rslvr-fdl-73a8806427d" is the Firewall Domain List ID.
-- If no rules match, the field 'IS NULL'
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
WHERE firewall_domain_list_id = 'rslvr-fdl-73a8806427d'


-- All request names
-- ATTENTION: It will scan all files!
SELECT query_name, count(*) as count
FROM r53_rlogs
GROUP BY query_name
-- ORDER BY count DESC
ORDER BY query_name ASC


-- All request names originated from some specific instance
-- ATTENTION: It will scan all files!
SELECT query_name, count(*) as count
FROM r53_rlogs
WHERE srcids.instance = 'i-a18e488172db'
GROUP BY query_name
-- ORDER BY count DESC
ORDER BY query_name ASC



-- Requests based on a specified DNS query name pattern
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
WHERE query_name LIKE '%.com.br.'
ORDER BY query_timestamp DESC


-- Requests within specified start and end times
-- ATTENTION: It will scan all files in specified date condition!
SELECT query_timestamp, srcids.instance, srcaddr, srcport, query_name, rcode
FROM r53_rlogs
WHERE (parse_datetime(query_timestamp,'yyyy-MM-dd''T''HH:mm:ss''Z')
         BETWEEN parse_datetime('2023-06-26-15:00:00','yyyy-MM-dd-HH:mm:ss') 
             AND parse_datetime('2023-06-26-15:50:00','yyyy-MM-dd-HH:mm:ss'))
      AND date = '2023/06/26'
ORDER BY query_timestamp DESC


-- Requests from specified dates
-- ATTENTION: It will scan all files in specified date condition!
SELECT query_timestamp, srcids.instance, srcaddr, srcport, query_name, rcode
FROM r53_rlogs
WHERE (date BETWEEN '2023/06/01' AND '2023/06/31')
ORDER BY query_timestamp DESC


-- Requests where action is not null
-- Translate domain list id to its name
-- ATTENTION: It will scan all files!
SELECT *,
       CASE firewall_domain_list_id
           WHEN 'rslvr-fdl-73a8806427d' THEN 'BlockedCountries'
           WHEN 'rslvr-fdl-0443f004ad4' THEN 'AWSManagedDomainsAmazonGuardDutyThreatList'
           WHEN 'rslvr-fdl-12cb7624fd5' THEN 'AWSManagedDomainsBotnetCommandandControl'
           WHEN 'rslvr-fdl-2c0855d49ab' THEN 'AWSManagedDomainsMalwareDomainList'
           WHEN 'rslvr-fdl-eb3ed7a4492' THEN 'AWSManagedDomainsAggregateThreatList'
       END AS domain_list_name
FROM r53_rlogs
WHERE firewall_rule_action IS NOT NULL


-- Requests with no answer
-- ATTENTION: It will scan all files!
SELECT query_timestamp, srcids.instance, srcaddr, srcport, query_name, rcode, answers
FROM r53_rlogs
WHERE cardinality(answers) = 0
ORDER BY query_timestamp DESC


-- Request with a specific answer
-- ATTENTION: It will scan all files!
SELECT query_timestamp, srcids.instance, srcaddr, srcport, query_name, rcode, answer.Rdata
FROM r53_rlogs
CROSS JOIN UNNEST(r53_rlogs.answers) as st(answer)
WHERE answer.Rdata = '52.94.206.147' --ec2messages


-- Request from some specific instance ID
-- ATTENTION: It will scan all files!
SELECT *
FROM r53_rlogs
WHERE srcids.instance = 'i-a685127cbc49'
ORDER BY query_timestamp DESC


-- Check if any file was moved to the wrong folder
-- Field 'vpc_id' MUST never be diffferent from field 'vpc'
-- ATTENTION: It will scan all files!
SELECT vpc_id, vpc
FROM r53_rlogs
WHERE vpc_id != vpc