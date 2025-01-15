data "http" "package" {
  url = local.artefact_url
}

data "http" "package_b64sha256" {
  url = local.artefact_url_b64sha256
}

module "artefact_bucket" {
  count  = var.artifact_bucket.create ? 1 : 0
  source = "./s3_bucket"
  name   = local.artefact_bucket["name"]
  tags   = var.tags
}

resource "aws_s3_object" "log_forwarder" {
  bucket         = local.artefact_bucket["name"]
  key            = "${var.name}/${local.filename}"
  content_base64 = data.http.package.response_body_base64
  depends_on     = [module.artefact_bucket]
}
