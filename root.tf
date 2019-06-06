# Data inputs
data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_s3_bucket" "build_in_out" {
    bucket = "${var.build_bucket_name}"
    acl = "private"
}

resource "aws_s3_bucket_object" "object" {
    bucket = "${aws_s3_bucket.build_in_out.bucket}"
    key = "source.zip"
    source = "applications/ubuntu/source.zip"
    etag = "${md5(file("applications/ubuntu/source.zip"))}"
}

resource "aws_iam_role" "default" {
    name = "example"

    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["codebuild.amazonaws.com", "events.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "packer" {
    role = "${aws_iam_role.default.name}"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action" : [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.build_in_out.arn}",
        "${aws_s3_bucket.build_in_out.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codebuild_project" "packer" {
    name = "packer"
    description = "Packer AMI builder prototype"
    build_timeout = "30"
    service_role = "${aws_iam_role.default.arn}"

    cache {
        type = "LOCAL"
        modes = ["LOCAL_CUSTOM_CACHE"]
    }

    artifacts {
        type = "S3"
        location = "${aws_s3_bucket.build_in_out.bucket}"
    }

    environment {
        compute_type = "BUILD_GENERAL1_SMALL"
        image = "hashicorp/packer:latest"
        type = "LINUX_CONTAINER"

        environment_variable {
            name = "BASE_AMI"
            value = "${data.aws_ami.ubuntu.id}"
            type = "PLAINTEXT"
        }
    }

    source {
        type = "S3"
        location = "${aws_s3_bucket.build_in_out.bucket}/source.zip"
        buildspec = "${file("applications/ubuntu/buildspec.yml")}"
    }
}

resource "aws_cloudwatch_event_target" "codebuild" {
    count = "${var.enable_scheduled_builds}"

    target_id = "codebuild-packer-amis-test"
    rule = "${aws_cloudwatch_event_rule.codebuild.name}"
    arn = "${aws_codebuild_project.packer.arn}"
    role_arn = "${aws_iam_role.default.arn}"
}

resource "aws_cloudwatch_event_rule" "codebuild" {
    count = "${var.enable_scheduled_builds}"

    name = "trigger-codebuild-packer"
    description = "Trigger a codebuild packer AMI run"
    role_arn = "${aws_iam_role.default.arn}"

    schedule_expression = "rate(5 minutes)"
}
