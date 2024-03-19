terraform {
  backend "s3" {
    bucket = "remote-backend-statefile-terraform-bucket-1"
    key    = "Terraform_State_File/terraform.tfstate"
    region = "us-east-2"
  }
}
