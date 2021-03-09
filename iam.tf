resource "aws_iam_role" "wireguard_endpoint" {
  name = "${var.namespace}-wireguard-endpoint"
  assume_role_policy = templatefile("${path.module}/policies/instance-role-policy.json", {})
}

resource "aws_iam_instance_profile" "wireguard_endpoint" {
  name = "wireguard_endpoint"
  role = aws_iam_role.wireguard_endpoint.name
}

resource "aws_iam_policy" "route53_change_records" {
  name        = "${var.namespace}-Route53ChangeHostedZoneRecords"
  description = "Permit the changing of records in the ${var.hosted_zone_id} Hosted Zone"
  policy      = templatefile("${path.module}/policies/route53-change-records.json", {
    hosted_zone_id = var.hosted_zone_id
  })
}

resource "aws_iam_role_policy_attachment" "change_hosted_zone" {
  role       = aws_iam_role.wireguard_endpoint.name
  policy_arn = aws_iam_policy.route53_change_records.arn
}

resource "aws_iam_policy" "route53_read_only" {
  name        = "${var.namespace}-Route53ReadOnly"
  description = "Allows Read and List operations on Route53"
  policy      = templatefile("${path.module}/policies/route53-read-only.json", {})
}

resource "aws_iam_role_policy_attachment" "allow_wireguard_route53_lookups" {
  role       = aws_iam_role.wireguard_endpoint.name
  policy_arn = aws_iam_policy.route53_read_only.arn
}

resource "aws_iam_policy" "ssm_ps_modify_wireguard_path" {
  name        = "${var.namespace}-SsmPsModifyWireguardPath"
  description = "Grant Write and Tagging access to the Wireguard Parameter path in SSM Parameter store."
  policy      = templatefile("${path.module}/policies/ssm-param-wireguard-crud.json", {
    aws_region = var.aws_region
    account_id = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_role_policy_attachment" "wireguard_ssm_ps_modify_path" {
  role       = aws_iam_role.wireguard_endpoint.name
  policy_arn = aws_iam_policy.ssm_ps_modify_wireguard_path.arn
}
