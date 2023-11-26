locals {
  sg = { for sg in local.securityGroupConfig : sg.name => sg }
  sgRules = { for rule in flatten([
    for group in local.securityGroupConfig : [
      for rule in group.rules : merge({ sg = group.name }, rule)
    ]
  ]) : "${rule.sg}_${rule.type}_${rule.target}_${local.portMapping[rule.fromPort]}_${local.portMapping[rule.toPort]}" => rule }
  securityGroupConfig = [
    {
      name        = "iot-test"
      description = "iot test"
      rules = [
        {
          type        = "ingress"
          description = "inbound ssh"
          fromPort    = "portSsh"
          toPort      = "portSsh"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "ingress"
          description = "inbound http traffic"
          fromPort    = "portHttp"
          toPort      = "portHttp"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "ingress"
          description = "inbound https traffic"
          fromPort    = "portHttps"
          toPort      = "portHttps"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "ingress"
          description = "inbound iot traffic"
          fromPort    = "portIot"
          toPort      = "portIot"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "egress"
          description = "outbound http traffic"
          fromPort    = "portHttp"
          toPort      = "portHttp"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "egress"
          description = "outbound https traffic"
          fromPort    = "portHttps"
          toPort      = "portHttps"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
        {
          type        = "egress"
          description = "outbound iot traffic"
          fromPort    = "portIot"
          toPort      = "portIot"
          protocol    = "tcp"
          target      = "cidrAnyone"
        },
      ]
    }
  ]
}

data "local_sensitive_file" "public_key" {
  filename = "${path.cwd}/../herb_watering.pub"
}

resource "aws_key_pair" "key_pair" {
  key_name   = var.project
  public_key = data.local_sensitive_file.public_key.content
}

resource "aws_security_group" "sg" {
  for_each    = local.sg
  name        = "${var.project}-${each.value.name}"
  description = each.value.description
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project}-${each.value.name}"
  }
}

resource "aws_security_group_rule" "sg-rules" {
  for_each                 = local.sgRules
  security_group_id        = aws_security_group.sg[each.value.sg].id
  type                     = each.value.type
  description              = each.value.description
  from_port                = local.portMapping[each.value.fromPort]
  to_port                  = local.portMapping[each.value.toPort]
  protocol                 = each.value.protocol
  cidr_blocks              = substr(each.value.target, 0, 3) != "sg-" ? local.cidrBlocks[each.value.target] : null
  source_security_group_id = substr(each.value.target, 0, 3) == "sg-" ? aws_security_group.sg[substr(each.value.target, 3, length(each.value.target) - 3)].id : null
}
