provider "aws" {
  alias  = "global"
  region = "us-east-1"
}

resource "aws_wafv2_ip_set" "blacklist" {
  name               = "${var.app_name}-blacklist-${var.env}"
  description        = "Blacklist IP set"
  scope              = var.is_cloudfront ? "CLOUDFRONT" : "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.blacklist
  tags               = var.tags
}

resource "aws_wafv2_web_acl" "acl" {
  name        = "${var.app_name}-web-acls-${var.env}"
  description = "Web ACLs"
  scope       = var.is_cloudfront ? "CLOUDFRONT" : "REGIONAL"

  default_action {
    allow {}
  }

  tags = var.tags
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.app_name}-${var.env}-wafv2-metric"
    sampled_requests_enabled   = true
  }

##################################################################
# IPBlocklist
##################################################################
  rule {
    name     = "blocklist"
    priority = 0

    action {
      block {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blacklist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-blocklist-rule-metric"
      sampled_requests_enabled   = true
    }
  }
##################################################################
# Rate-Limit
##################################################################
  rule {
    name     = "rate-limit"
    priority = 1

    action {
      count {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-rate-limit-rule-metric"
      sampled_requests_enabled   = true
    }
  }
##################################################################
# AWSManagedRulesAmazonIpReputationList
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

##################################################################
# AWSManagedRulesAnonymousIpList
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"

        excluded_rule {
          name = "HostingProviderIPList"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-AWS-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }
##################################################################
# AWSManagedRulesCommonRuleSet
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        excluded_rule {
          name = "SizeRestrictions_BODY"
        }
        excluded_rule {
          name = "SizeRestrictions_QUERYSTRING"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

##################################################################
# AWSManagedRulesKnownBadInputsRuleSet
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-bad-input-metric"
      sampled_requests_enabled   = true
    }
  }
##################################################################
# AWSManagedRulesUnixRuleSet
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesUnixRuleSet"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-AWS-AWSManagedRulesUnixRuleSet"
      sampled_requests_enabled   = true
    }
  }
##################################################################
# AWSManagedRulesSQLiRuleSet
##################################################################
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 7

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.app_name}-${var.env}-AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "_" {
  for_each     = var.is_cloudfront ? [] : toset(var.resource_arn_list)
  resource_arn = each.key
  web_acl_arn  = aws_wafv2_web_acl.acl.arn
}

resource "aws_cloudwatch_log_group" "_" {
  name = "aws-waf-logs-${var.app_name}-${var.env}"

  tags = var.tags
  retention_in_days = 30
}

resource "aws_wafv2_web_acl_logging_configuration" "_" {
  log_destination_configs = [aws_cloudwatch_log_group._.arn]
  resource_arn            = aws_wafv2_web_acl.acl.arn
  redacted_fields {
    uri_path {}
  }
}