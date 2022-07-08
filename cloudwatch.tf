resource "aws_cloudwatch_log_group" "awslogs" {
  name              = "/aws/ec2/asg/${local.name_prefix}asg"
  retention_in_days = 7
  kms_key_id        = local.kms_key

  tags = local.default_tags
}

data "aws_iam_policy_document" "awslogs_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = ["${aws_cloudwatch_log_group.awslogs.arn}:*"]
  }
}
