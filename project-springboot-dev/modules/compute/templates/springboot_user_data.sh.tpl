#!/bin/bash
set -euo pipefail

############################
# Spring Boot 인스턴스 초기 설정
############################

# jar 다운로드 (GitHub Private Release)
curl -L -fsSL \
  -H "Authorization: token ${github_token}" \
  -H "Accept: application/octet-stream" \
  -o /opt/myapp/app/app.jar \
  "${jar_url}"

chown myapp:myapp /opt/myapp/app/app.jar
chmod 750 /opt/myapp/app/app.jar

############################
# DB 환경변수 export
############################
export SPRING_DATASOURCE_URL="jdbc:mysql://${db_url}:3306/appdb?serverTimezone=Asia/Seoul&useSSL=false&allowPublicKeyRetrieval=true"
export SPRING_DATASOURCE_USERNAME="${db_username}"
export SPRING_DATASOURCE_PASSWORD="${db_password}"
export SPRING_PROFILES_ACTIVE="prod"
export SERVER_PORT=8080

############################
# AMI에 이미 있는 런타임 설정 스크립트 호출
############################
bash /opt/myapp/app/inject_runtime_config.sh
