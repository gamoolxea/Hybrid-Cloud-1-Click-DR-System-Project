#!/bin/bash
set -euo pipefail

############################
# Spring Boot 인스턴스 초기 설정
#
# AMI: springboot-app-golden-* (dr-infra-scripts/springboot_app.pkr.hcl로 빌드된
# Rocky Linux 9 + Amazon Corretto 17 기반 Golden AMI)
#
# AMI가 이미 제공하는 것:
#   - /opt/myapp/{app,config,logs} 디렉토리 + myapp 유저
#   - /etc/systemd/system/myapp.service (jar 없으면 안 떠 있음)
#   - /opt/myapp/app/inject_runtime_config.sh (런타임 env 주입 스크립트)
#   - Java 17, firewalld 8080 오픈, Tailscale
#
# 여기서 하는 일:
#   1) jar 다운로드 → /opt/myapp/app/app.jar
#   2) 런타임 env 변수 export
#   3) inject_runtime_config.sh 호출 (AMI가 env 파일 작성 + 서비스 기동 + 헬스체크)
############################

# jar 다운로드 (GitHub Private Release, asset API URL 방식)
curl -L -fsSL \
  -H "Authorization: token ${github_token}" \
  -H "Accept: application/octet-stream" \
  -o /opt/myapp/app/app.jar \
  "${jar_url}"

chown myapp:myapp /opt/myapp/app/app.jar
chmod 750 /opt/myapp/app/app.jar

############################
# 런타임 env 변수 (inject_runtime_config.sh가 읽음)
############################
export SPRING_DATASOURCE_URL="jdbc:mysql://${db_url}:3306/appdb?serverTimezone=Asia/Seoul&useSSL=false&allowPublicKeyRetrieval=true"
export SPRING_DATASOURCE_USERNAME="${db_username}"
export SPRING_DATASOURCE_PASSWORD="${db_password}"
export SPRING_PROFILES_ACTIVE="prod"
export SERVER_PORT=8080

############################
# AMI의 런타임 주입 스크립트 호출
# → env 파일 write + systemctl restart myapp + /actuator/health 대기
############################
bash /opt/myapp/app/inject_runtime_config.sh
