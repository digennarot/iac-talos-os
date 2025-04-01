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

    # Interpolate the current Terraform workspace to separate state files
    # cluster-a => clusters/cluster-a/terraform.tfstate
    # cluster-b => clusters/cluster-b/terraform.tfstate
    key = "clusters/${terraform.workspace}/terraform.tfstate"

    # If credentials are required
    access_key = "minioadmin"
    secret_key = "minioadmin"
  }
}
