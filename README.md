# Terraform Module For A S3 Website With CloudFront, TLS

This module helps you create a S3 website, assuming that:

* it runs HTTPS via Amazon's Certificate Manager ("ACM")
* its domain is backed by a Route53 zone
* and of course, your AWS account provides you access to all these resources necessary.

This module is available on the [Terraform Registry](https://registry.terraform.io/modules/riboseinc/s3-cloudfront-website/aws/).

## Sample Usage

You can literally copy and paste the following example, change the following attributes, and you're ready to go:

* `allowed_ips`: set it to "`0.0.0.0/0`" if it should be publicly accessible
* `fqdn` set to your static website's hostname
* `domain` set to your static website's base domain name (e.g., `xyz.com`)


```go
# AWS Region for S3 and other resources
provider "aws" {
  region = "us-west-2"
  alias = "main"
}

# AWS Region for Cloudfront (ACM certs only supports us-east-1)
provider "aws" {
  region = "us-east-1"
  alias = "cloudfront"
}

# Variables
variable "fqdn" {
  description = "The fully-qualified domain name of the resulting S3 website."
  default     = "mysite.example.com"
}

variable "domain" {
  description = "The domain name / ."
  default     = "example.com"
}
variable "allowed_ips" {
  type = "list"
  default = [ "999.999.999.999/32" ]
}

# Using this module
module "main" {
  source = "../../public-site"

  fqdn = "${var.fqdn}"
  ssl_certificate_arn = "${aws_acm_certificate_validation.cert.certificate_arn}"
  allowed_ips = "${var.allowed_ips}"

  index_document = "index.html"
  error_document = "404.html"

  refer_secret = "${base64sha512("REFER-SECRET-19265125-${var.fqdn}-52865926")}"

  force_destroy = "true"

  providers {
    "aws.main" = "aws.main"
    "aws.cloudfront" = "aws.cloudfront"
  }
}

# ACM Certificate generation

resource "aws_acm_certificate" "cert" {
  provider          = "aws.cloudfront"
  domain_name       = "${var.fqdn}"
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.cloudfront"
  name     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_name}"
  type     = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_type}"
  zone_id  = "${data.aws_route53_zone.main.id}"
  records  = ["${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"]
  ttl      = 60
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = "aws.cloudfront"
  certificate_arn         = "${aws_acm_certificate.cert.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_validation.fqdn}"]
}


# Route 53 record for the static site

data "aws_route53_zone" "main" {
  provider     = "aws.main"
  name         = "${var.domain}"
  private_zone = false
}

resource "aws_route53_record" "web" {
  provider = "aws.main"
  zone_id  = "${data.aws_route53_zone.main.zone_id}"
  name     = "${var.fqdn}"
  type     = "A"

  alias {
    name    = "${module.main.cf_domain_name}"
    zone_id = "${module.main.cf_hosted_zone_id}"
    evaluate_target_health = false
  }
}

# Outputs

output "s3_bucket_id" {
  value = "${module.main.s3_bucket_id}"
}

output "s3_domain" {
  value = "${module.main.s3_website_endpoint}"
}

output "s3_hosted_zone_id" {
  value = "${module.main.s3_hosted_zone_id}"
}

output "cloudfront_domain" {
  value = "${module.main.cf_domain_name}"
}

output "cloudfront_hosted_zone_id" {
  value = "${module.main.cf_hosted_zone_id}"
}

output "cloudfront_distribution_id" {
  value = "${module.main.cf_distribution_id}"
}

output "route53_fqdn" {
  value = "${aws_route53_record.web.fqdn}"
}

output "acm_certificate_arn" {
  value = "${aws_acm_certificate_validation.cert.certificate_arn}"
}
```