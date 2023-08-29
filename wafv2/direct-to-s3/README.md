# WAF Logs direct to S3

WAF store logs on S3 with some specific path, which can be used as partitioning attributes to increase Athena performance and reduce costs.

Example:  
`/AWSLogs/123412341234/WAFLogs/sa-east-1/demo/2022/06/02/19/30/123412341234_waflogs_sa-east-1_demo_20220602T1930Z_8d09aa0b.log.gz`

Based on this pattern you can use date in the minute level to partition Athena table.

This repository has instruction to create table using minute level partition schema and example queries.

* [Create table](/wafv2/direct-to-s3/create-table.sql)
* [Query](/wafv2/direct-to-s3/queries.sql)