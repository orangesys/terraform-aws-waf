resource "aws_wafv2_ip_set" "blacklist" {
  name               = "blacklist"
  description        = "Blacklist IP set"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.blacklist
}
