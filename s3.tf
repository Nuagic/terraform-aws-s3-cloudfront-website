resource "aws_s3_bucket" "main" {
  provider = "aws.main"
  bucket   = "${var.fqdn}"
  acl      = "private"
  policy   = "${data.aws_iam_policy_document.bucket_policy.json}"

  website {
    index_document = "${var.index_document}"
    error_document = "${var.error_document}"
    routing_rules  = "${var.routing_rules}"
  }

  force_destroy = "${var.force_destroy}"

  tags = "${merge("${var.tags}",map("Name", "${var.fqdn}"))}"
}

data "aws_iam_policy_document" "bucket_policy" {
  provider = "aws.main"

  statement {
    sid = "AllowedAWSaccountRW"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:GetBucketLocation",
      "s3:GetBucketWebsite",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
      "arn:aws:s3:::${var.fqdn}",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:userId"

      values = [
        "${var.allowed_iam_account_rw}"
      ]
    }

    principals {
      type = "*"
      identifiers = ["*"]
    }

  }

  statement {
    sid = "AllowedIPReadAccess"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"

      values = [
        "${var.allowed_ips}"
      ]
    }

    principals {
      type = "*"
      identifiers = ["*"]
    }

  }

  statement {
    sid = "AllowCFOriginAccess"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.fqdn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:UserAgent"

      values = [
        "${var.refer_secret}"
      ]
    }

    principals {
      type = "*"
      identifiers = ["*"]
    }

  }

}
