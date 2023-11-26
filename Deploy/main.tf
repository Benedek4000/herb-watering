variable "project" {}
variable "region" {}

locals {
  defaultTags = {
    project = var.project
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.defaultTags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "northVirginia"

  default_tags {
    tags = local.defaultTags
  }
}
