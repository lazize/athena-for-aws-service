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

-- Create table for Route 53 Resolver query log structure.
-- Partition on date, based on format yyyy/MM/dd, so you can query by day.
--
-- INSTRUCTIONS
--
-- On LOCATION line, replace <YOUR-BUCKET-NAME> and <YOUR-ACCOUNT-ID> with your bucket name and account ID, respectively.
-- On 'storage.location.template' line, replace <YOUR-BUCKET-NAME> and <YOUR-ACCOUNT-ID> with your bucket name and account ID, respectively.
-- On 'projection.vpc.values' line, replace 'vpc-123abc,vpc-456def' with your VPC IDs, separated by a comma.
-- On 'projection.date.range' line, replace '2023/07/06' with your desired start date. Attention, it must be in format yyyy/MM/dd. Do not remove NOW.

CREATE EXTERNAL TABLE r53_rlogs (
  version string,
  account_id string,
  region string,
  vpc_id string,
  query_timestamp string,
  query_name string,
  query_type string,
  query_class string,
  rcode string,
  answers array<
    struct<
      Rdata: string,
      Type: string,
      Class: string>
    >,
  srcaddr string,
  srcport int,
  transport string,
  srcids struct<
    instance: string,
    resolver_endpoint: string
    >,
  firewall_rule_action string,
  firewall_rule_group_id string,
  firewall_domain_list_id string
)
PARTITIONED BY (
  `date` string,
  `vpc` string
)
ROW FORMAT SERDE      'org.openx.data.jsonserde.JsonSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT          'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION              's3://<YOUR-BUCKET-NAME>/AWSLogs/<YOUR-ACCOUNT-ID>/vpcdnsquerylogs/'
TBLPROPERTIES(
  'projection.enabled' = 'true',
  'projection.vpc.type' = 'enum',
  'projection.vpc.values' = 'vpc-123abc,vpc-456def',
  'projection.date.type' = 'date',
  'projection.date.range' = '2023/07/06,NOW',
  'projection.date.format' = 'yyyy/MM/dd',
  'projection.date.interval' = '1',
  'projection.date.interval.unit' = 'DAYS',
  'storage.location.template' = 's3://<YOUR-BUCKET-NAME>/AWSLogs/<YOUR-ACCOUNT-ID>/vpcdnsquerylogs/${vpc}/${date}/'
)
