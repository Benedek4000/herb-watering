locals {
  instance_type = "t2.micro"

  ec2RolePolicies = [
    "AmazonSSMFullAccess",
    "AmazonS3FullAccess",
  ]
}

data "aws_ec2_instance_type" "server" {
  instance_type = local.instance_type
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = data.aws_ec2_instance_type.server.supported_architectures
  }
}

module "ec2-role" {
  source = "git::https://github.com/Benedek4000/terraform-aws-role.git//module?ref=1.0.1"

  roleName             = "${var.project}-ec2-role"
  principalType        = "Service"
  principalIdentifiers = ["ec2.amazonaws.com"]
  policies             = local.ec2RolePolicies
}


resource "aws_iam_instance_profile" "server-profile" {
  name = "${var.project}-profile"
  role = module.ec2-role.role.name
}

data "template_file" "user_data" {
  template = file("${path.root}/user_data.sh")
  vars = {
    IOT_ENDPOINT                  = data.aws_iot_endpoint.endpoint.endpoint_address
    IOT_TEST_CERT_CONTENTS        = aws_iot_certificate.cert.certificate_pem
    IOT_TEST_PRIVATE_KEY_CONTENTS = tls_private_key.key.private_key_pem
  }
}

resource "aws_instance" "raspberry" {
  key_name                    = aws_key_pair.key_pair.key_name
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = local.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  availability_zone           = aws_subnet.public.availability_zone
  vpc_security_group_ids      = [aws_security_group.sg["iot-test"].id]
  iam_instance_profile        = aws_iam_instance_profile.server-profile.name
  user_data                   = data.template_file.user_data.rendered

  lifecycle {
    ignore_changes = all
  }
}
