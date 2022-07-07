resource "aws_cloudwatch_log_group" "awslogs" {
  name              = "${local.name_prefix}asg-ec2"
  retention_in_days = 7
  #   kms_key_id        = "todo"

  tags = local.default_tags
}

data "aws_iam_policy_document" "awslogs_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = ["${aws_cloudwatch_log_group.awslogs.arn}/*"]
  }
}
