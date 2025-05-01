terraform {
  backend "s3" {
    # Point the backend at MinIO
    endpoint                    = "http://localhost:9000"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true

    # "region" can be any valid string when using MinIO
    region = "us-east-1"

    # Your MinIO bucket for storing Terraform states
    bucket = "terraform-state"

    # A *static* default key; Terraform will automatically
    # prefix it per-workspace when you set workspace_key_prefix.
    key = "clusters/terraform.tfstate"

    # This tells the S3 backend to separate each workspace under
    # that “clusters/” prefix:
    workspace_key_prefix = "clusters"

    # If credentials are required
    access_key = "minioadmin"
    secret_key = "minioadmin"
  }
}
