terraform {
  backend "s3" {
    bucket         = "3team-tfstate-dr-01"
    key            = "project-springboot/dr/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
