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

-- Create table for WAF v2 log structure.
-- Partition on date, based on format yyyy/MM/dd/HH/mm, so you can query by minute.
--
-- INSTRUCTIONS
--
-- On LOCATION line, replace <YOUR-BUCKET-NAME>, <YOUR-ACCOUNT-ID>, <YOUR-REGION> and <YOUR-WEBACL-NAME> with your bucket name, account ID, region name and WebACL name, respectively.
-- On 'storage.location.template' line, replace <YOUR-BUCKET-NAME>, <YOUR-ACCOUNT-ID>, <YOUR-REGION> and <YOUR-WEBACL-NAME> with your bucket name, account ID, region name and WebACL name, respectively.
-- On 'projection.date.range' line, replace '2023/07/06/00/00' with your desired start date and time. Attention, it must be in format yyyy/MM/dd/HH/mm. Do not remove NOW.

CREATE EXTERNAL TABLE `waf_logs`(
  `timestamp` bigint,
  `formatversion` int,
  `webaclid` string,
  `terminatingruleid` string,
  `terminatingruletype` string,
  `action` string,
  `terminatingrulematchdetails` array <
                                    struct <
                                        conditiontype: string,
                                        sensitivitylevel: string,
                                        location: string,
                                        matcheddata: array < string >
                                          >
                                     >,
  `httpsourcename` string,
  `httpsourceid` string,
  `rulegrouplist` array <
                      struct <
                          rulegroupid: string,
                          terminatingrule: struct <
                                              ruleid: string,
                                              action: string,
                                              rulematchdetails: array <
                                                                   struct <
                                                                       conditiontype: string,
                                                                       sensitivitylevel: string,
                                                                       location: string,
                                                                       matcheddata: array < string >
                                                                          >
                                                                    >
                                                >,
                          nonterminatingmatchingrules: array <
                                                              struct <
                                                                  ruleid: string,
                                                                  action: string,
                                                                  overriddenaction: string,
                                                                  rulematchdetails: array <
                                                                                       struct <
                                                                                           conditiontype: string,
                                                                                           sensitivitylevel: string,
                                                                                           location: string,
                                                                                           matcheddata: array < string >
                                                                                              >
                                                                                       >
                                                                    >
                                                             >,
                          excludedrules: string
                            >
                       >,
`ratebasedrulelist` array <
                         struct <
                             ratebasedruleid: string,
                             limitkey: string,
                             maxrateallowed: int
                               >
                          >,
  `nonterminatingmatchingrules` array <
                                    struct <
                                        ruleid: string,
                                        action: string,
                                        rulematchdetails: array <
                                                             struct <
                                                                 conditiontype: string,
                                                                 sensitivitylevel: string,
                                                                 location: string,
                                                                 matcheddata: array < string >
                                                                    >
                                                             >,
                                        captcharesponse: struct <
                                                            responsecode: string,
                                                            solvetimestamp: string
                                                             >
                                          >
                                     >,
  `requestheadersinserted` array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
  `responsecodesent` string,
  `httprequest` struct <
                    clientip: string,
                    country: string,
                    headers: array <
                                struct <
                                    name: string,
                                    value: string
                                      >
                                 >,
                    uri: string,
                    args: string,
                    httpversion: string,
                    httpmethod: string,
                    requestid: string
                      >,
  `labels` array <
               struct <
                   name: string
                     >
                >,
  `captcharesponse` struct <
                        responsecode: string,
                        solvetimestamp: string,
                        failureReason: string
                          >
)
PARTITIONED BY (
  `date` string
)
ROW FORMAT SERDE      'org.openx.data.jsonserde.JsonSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT          'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION              's3://<YOUR-BUCKET-NAME>/AWSLogs/<YOUR-ACCOUNT-ID>/WAFLogs/<YOUR-REGION>/<YOUR-WEBACL-NAME>/'
TBLPROPERTIES(
  'projection.enabled' = 'true',
  'projection.date.type' = 'date',
  'projection.date.range' = '2023/07/06/00/00,NOW',
  'projection.date.format' = 'yyyy/MM/dd/HH/mm',
  'projection.date.interval' = '1',
  'projection.date.interval.unit' = 'MINUTES',
  'storage.location.template' = 's3://<YOUR-BUCKET-NAME>/AWSLogs/<YOUR-ACCOUNT-ID>/WAFLogs/<YOUR-REGION>/<YOUR-WEBACL-NAME>/${date}/'
)
