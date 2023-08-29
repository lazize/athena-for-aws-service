# Amazon Athena for AWS Service

## Welcome

This repository contains instructions on how to use Amazon Athena to query logs from AWS services configured to send logs to S3 bucket.


## Pre-requisites

* [Athena engine version 3](https://docs.aws.amazon.com/athena/latest/ug/engine-versions-reference-0003.html)


## Usage

Each AWS service will have its own folder inside this repository. You will find instructions to create table and some example queries.

When possible it will use Athena partition projection, which can reduce query runtime and automate partition management by using the Athena partition [projection feature](https://docs.aws.amazon.com/athena/latest/ug/partition-projection.html). Partition projection automatically adds new partitions as new data is added. This removes the need for you to manually add partitions by using `ALTER TABLE ADD PARTITION`.

If you have requirement for a different partition, please open an issue and let's talk about it.


> **ATTENTION**  
> You will not find instructions on how to enable log on determined AWS service.  
> To enable it, check AWS service documentation.

* [AWS WAF v2](/wafv2/)
* [Route 53 Resolver](/route53-resolver/)


## Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.


## License

This library is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file.


## Disclaimer

The opinions expressed in this repository and code are my own and not necessarily those of my employer (past, present and future).