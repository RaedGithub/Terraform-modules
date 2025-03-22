# store the terraform state file in s3
terraform {
  backend "s3" {
    bucket    = "raed-terraform-remote-state"
    key       = "ecs-website.tfstate"
    region    = "us-east-1"
    profile   = "terraform-user"
  }
}