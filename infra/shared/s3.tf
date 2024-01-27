resource "aws_s3_bucket" "hosting" {
  bucket = "hosting-takekou-${local.project_name}-${var.env}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.hosting.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}
