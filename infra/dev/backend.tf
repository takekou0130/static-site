terraform {
  backend "s3" {
    bucket         = "tfstate-takekou-static-site-dev"
    key            = "tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "static-site-terraform-lock-dev"
  }
}
