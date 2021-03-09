resource "aws_security_group" "wireguard_endpoint" {
  name        = "${var.namespace}-wireguard-endpoint"
  vpc_id      = var.vpc_id
  description = "Wireguard public-facing security group"

  tags = {
    Name = "wireguard-endpoint"
  }
}

resource "aws_security_group_rule" "permit_external_wireguard_connections" {
  type              = "ingress"
  security_group_id = aws_security_group.wireguard_endpoint.id

  protocol    = "udp"
  from_port   = 51820
  to_port     = 51820
  cidr_blocks = var.external_allowed_cidr_blocks
}

resource "aws_security_group_rule" "permit_all_outbound_traffic" {
  type              = "egress"
  security_group_id = aws_security_group.wireguard_endpoint.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "permit_all_traffic_from_wireguard_clients" {
  type              = "ingress"
  security_group_id = aws_security_group.wireguard_endpoint.id

  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.client_subnet]
}
