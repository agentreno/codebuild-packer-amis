# codebuild-packer-amis

## Description

A prototype system for producing AMIs on a schedule using Codebuild to run
Packer, triggered by a Cloudwatch Cron rule.

## Install

Run `terraform init` and create a terraform.tfvars file in the root with the
following format:

```
profile = "<aws profile from credentials file to use>"
build_bucket_name = "<name of S3 bucket to store packer output for debugging>"
enable_scheduled_builds = "<0|1>"
```

The run `terraform apply`, trigger a build manually (or wait for the schedule
if it's enabled), and observe the effects:

- Output file in S3
- Codebuild in AWS console will show builds
- AMI will be stored in the account

## Contributing

If you change `project/packer-gocd-master.json` make sure you run
`./project/build.sh` to rebuild the source and run another terraform apply to
upload it to S3.
