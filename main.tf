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

  # rule {
  #   name     = "rate"
  #   priority = 1

  #   action {
  #     count {}
  #   }

  #   statement {
  #     rate_based_statement {
  #       limit              = 10000
  #       aggregate_key_type = "IP"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = false
  #     metric_name                = "${var.app_name}-${var.env}-rate-rule-metric"
  #     sampled_requests_enabled   = false
  #   }
  # }

  # rule {
  #   name     = "default"
  #   priority = 2

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesCommonRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = false
  #     metric_name                = "${var.app_name}-${var.env}-default-rule-metric"
  #     sampled_requests_enabled   = false
  #   }
  # }

  rule {
    name     = "blocklist"
    priority = 3

    override_action {
      none {}
    }

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

  tags = var.tags

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${var.app_name}-${var.env}-metric"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "_" {
  for_each     = toset(var.resource_arn_list)
  resource_arn = each.key
  web_acl_arn  = aws_wafv2_web_acl.acl.arn
}
