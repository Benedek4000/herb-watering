data "aws_iot_endpoint" "endpoint" {
  endpoint_type = "iot:Data-ATS"
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "cert" {
  private_key_pem = tls_private_key.key.private_key_pem

  validity_period_hours = 240

  allowed_uses = [
  ]

  subject {
    organization = var.project
  }
}

resource "aws_iot_thing" "raspberry" {
  name = "${var.project}-raspberry"
}

resource "aws_iot_certificate" "cert" {
  certificate_pem = trimspace(tls_self_signed_cert.cert.cert_pem)
  active          = true
}

resource "aws_iot_thing_principal_attachment" "attachment" {
  principal = aws_iot_certificate.cert.arn
  thing     = aws_iot_thing.raspberry.name
}

data "aws_iam_policy" "AWSIotDataAccess" {
  name = "AWSIoTDataAccess"
}

resource "aws_iot_policy" "AWSIotDataAccess" {
  name   = "AWSIotDataAccess"
  policy = data.aws_iam_policy.AWSIotDataAccess.policy
}

resource "aws_iot_policy_attachment" "attachment" {
  policy = aws_iot_policy.AWSIotDataAccess.name
  target = aws_iot_certificate.cert.arn
}
