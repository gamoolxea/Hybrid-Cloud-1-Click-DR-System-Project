terraform {
  backend "s3" {
    # bucket, key, region, dynamodb_table은 팀원별로 다르므로
    # backend.hcl (gitignore됨) 파일에 정의하고
    # terraform init -backend-config=backend.hcl 로 주입한다.
    encrypt = true
  }
}
