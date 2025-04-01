// error-guard/main.tf
variable "workspace_name" {}

resource "null_resource" "block_default" {
  provisioner "local-exec" {
    command = "echo 'The default workspace is not allowed!'; exit 1"
    when    = var.workspace_name == "default" ? create : skip
  }
}
