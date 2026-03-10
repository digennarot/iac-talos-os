# Backend configuration for remote state stored in MinIO (S3-compatible).
#
# Credentials are intentionally omitted here and should be supplied at init
# time via environment variables or a -backend-config file, e.g.:
#
#   export AWS_ACCESS_KEY_ID=minioadmin
#   export AWS_SECRET_ACCESS_KEY=minioadmin
#   tofu init -reconfigure
#
# Or via a backend config file (never commit this file):
#   tofu init -backend-config=backend.hcl
terraform {
  backend "s3" {
    endpoint = "http://localhost:9000"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true

    region = "us-east-1"

    bucket               = "terraform-state"
    key                  = "clusters/terraform.tfstate"
    workspace_key_prefix = "clusters"
  }
}
