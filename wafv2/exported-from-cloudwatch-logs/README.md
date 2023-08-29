# WAF Logs exported from CloudWatch Logs to S3

Here is the log pattern flow in this situation:

`WAF --> CloudWatch Logs --> S3`

So, WAF is configured to send logs to CloudWatch Logs and later export CloudWatch Logs to a S3 bucket.

In this situation, CloudWatch Logs inject a timestamp in the format of [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) in the beginning of each log line. See below an example:

`2022-12-11T06:59:52.635Z {"timestamp":1670741992635,"formatVersion":1,"webaclId":"arn:aws:wafv2:sa-east-1:.......}`

In this example above, `2022-12-11T06:59:52.635Z` was injected by CloudWatch Logs during the export process. It means it is not just a JSON log anymore.

In this repository you will see instructions to parse this "exported" log files and remove this extra timestamp. After that it will a standard WAF log.

## Steps

Those are the steps required to handle this kind of log files.

* Create table with just timestamp and original log
* Create another table with just original log data
* Create standard WAF logs table

## Create table with just timestamp and original log

In this step you will create a table with just two columns, the CloudWatch timestamp and the original WAF log.

```sql
CREATE EXTERNAL TABLE waf_logs_from_cw (
    timestamp STRING,
    original_log STRING
)
ROW FORMAT SERDE      'com.amazonaws.glue.serde.GrokSerDe'
WITH SERDEPROPERTIES  ("input.format" = "%{TIMESTAMP_ISO8601:timestamp} %{GREEDYDATA:original_log}")
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT          'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION              's3://<YOUR-BUCKET-NAME>/exported/';
```

## Create another table with just original log data

In this step you will create another table that contains only the original WAF log. In this example it is filtering by a specific date.  
At this point it will copy your log data, so it will increase your bucket storage usage.  
The bucket location where it will store this new files must be an empty location.

This step can take a long time, it will depends on the amount of your data. Keep in mind that Athena has a standard timeout of 30 minutes for queries.

```sql
CREATE TABLE ctas_unpartitioned
WITH (
     format = 'TEXTFILE', 
     external_location = 's3://<YOUR-BUCKET-NAME>/exported-json/'
) AS
SELECT original_log
FROM "waf_logs_from_cw"
WHERE date(from_iso8601_timestamp("timestamp")) = date '2022-12-11'
```

## Create standard WAF logs table

In this step you have a bucket location with files that contains just a plain WAF JSON log. So, you can use the standard process explained on "[direct to S3](/wafv2/direct-to-s3/)" to create Athena table and query your WAF logs.