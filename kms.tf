locals {
  create_kms_key = local.config.kms_key == null ? 1 : 0
  kms_key        = local.config.kms_key != null ? local.config.kms_key : one(aws_kms_key.this).arn
}

data "aws_iam_policy_document" "kms" {
  statement {
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
    }
  }

  statement {
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type = "AWS"
      # identifiers = [aws_iam_role.this.arn]
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "Allow CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region_name}.amazonaws.com"]
    }

    # condition {
    #   test     = "ArnEquals"
    #   variable = "kms:EncryptionContext:aws:logs:arn"
    #   values   = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/codebuild/${local.name_prefix}*"]
    # }
  }
}

resource "aws_kms_key" "this" {
  count = local.create_kms_key

  description         = "KMS CMK used by ${local.name_prefix}ec2"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}ec2-kms"
  })
}

resource "aws_kms_alias" "this" {
  count = local.create_kms_key

  name          = "alias/${local.name_prefix}ec2-kms"
  target_key_id = aws_kms_key.this[0].key_id
}
