resource "aws_wafv2_ip_set" "blacklist" {
  name               = "${var.app_name}-blacklist-${var.env}"
  description        = "Blacklist IP set"
  scope              = var.is_cloudfront ? "CLOUDFRONT" : "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.blacklist
  tags               = var.tags
}

resource "aws_wafv2_web_acl" "acl" {
  name        = "${var.app_name}-web-acls"
  description = "Web ACLs"
  scope       = var.is_cloudfront ? "CLOUDFRONT" : "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "default"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.app_name}-${var.env}-default-rule-metric"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "blocklist"
    priority = 2

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "${var.app_name}-${var.env}-blocklist-rule-metric"
      sampled_requests_enabled   = false
    }
  }

  tags = tags

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                =  "${var.app_name}-${var.env}-metric"
    sampled_requests_enabled   = false
  }
}
