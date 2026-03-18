# resource "aws_security_group" "ec2nix_security_group" {

#   vpc_id = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   dynamic "ingress" {
#     for_each = var.ingress_ports_udp

#     content {
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "udp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   dynamic "ingress" {
#     for_each = var.ingress_ports

#     content {
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   dynamic "ingress" {
#     for_each = var.ingress_from_to_ports

#     content {
#       from_port   = ingress.value.from
#       to_port     = ingress.value.to
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   ## FOR SSM BE SURE 443 is open
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }


resource "aws_security_group" "ec2nix_security_group" {
  name        = "${var.name}-secgroup"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ec2nix_security_group_ingress_rule" {
  for_each = {
    for rule in var.ingress_rules: 
    rule.name => rule
  } 
  security_group_id = aws_security_group.ec2nix_security_group.id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  source_security_group_id = each.value.source_security_group_id
  cidr_blocks = each.value.cidr_blocks
}

resource "aws_security_group_rule" "ec2nix_security_group_egress_rule" {
  security_group_id = aws_security_group.ec2nix_security_group.id
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

