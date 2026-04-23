#!/bin/bash
set -euo pipefail

############################
# Spring Boot 인스턴스 초기 설정 (하이브리드)
#
# 현재 사용 중인 AMI(project-app-golden-v2, AL2023+Tomcat)는 dr-infra-scripts의
# springboot_app_role.sh로 만들어야 하는 구조가 없습니다. 일단 여기서 직접 복제.
#
# 팀원이 dr-infra-scripts의 Packer 스크립트로 Rocky 9 기반 AMI를 빌드하면,
# 이 스크립트는 축소되어 맨 아래 "런타임 주입" 부분만 남으면 됩니다.
############################

APP_USER="myapp"
APP_GROUP="myapp"
APP_HOME="/opt/myapp"
APP_DIR="${APP_HOME}/app"
CONFIG_DIR="${APP_HOME}/config"
LOG_DIR="${APP_HOME}/logs"
JAR_PATH="${APP_DIR}/app.jar"
ENV_FILE="${CONFIG_DIR}/myapp.env"
SERVICE_NAME="myapp"

############################
# [1] AMI에 있는 Tomcat 정리 (포트 8080 해방)
#     - AMI가 AL2023+Tomcat 구성이라 그대로 두면 기본 8080을 Tomcat이 점유해서
#       actuator 404 오류로 헬스체크 실패함.
############################
systemctl stop tomcat 2>/dev/null || true
systemctl disable tomcat 2>/dev/null || true

############################
# [2] myapp 유저/그룹 (springboot_app_role.sh의 [2] 단계와 동일)
############################
if ! getent group "${APP_GROUP}" >/dev/null 2>&1; then
  groupadd -r "${APP_GROUP}"
fi

if ! id "${APP_USER}" >/dev/null 2>&1; then
  useradd -r -g "${APP_GROUP}" -m -d "/home/${APP_USER}" -s /sbin/nologin "${APP_USER}"
fi

############################
# [3] 디렉토리 구조 (springboot_app_role.sh의 [3] 단계와 동일)
############################
mkdir -p "${APP_DIR}" "${CONFIG_DIR}" "${LOG_DIR}"
chown -R "${APP_USER}:${APP_GROUP}" "${APP_HOME}"
chmod 755 "${APP_HOME}" "${APP_DIR}" "${LOG_DIR}"
chmod 750 "${CONFIG_DIR}"

############################
# [4] jar 다운로드 (GitHub Private Release, API URL 방식)
############################
curl -L -fsSL \
  -H "Authorization: token ${github_token}" \
  -H "Accept: application/octet-stream" \
  -o "${JAR_PATH}" \
  "${jar_url}"

chown "${APP_USER}:${APP_GROUP}" "${JAR_PATH}"
chmod 750 "${JAR_PATH}"

############################
# [5] systemd service (springboot_app_role.sh의 [6] 단계와 동일한 형태)
#     AMI의 Java 17 경로를 그대로 쓰되, readlink로 안전하게 추출
############################
JAVA_BIN="$(readlink -f "$(command -v java)")"
JAVA_HOME_DIR="$(dirname "$(dirname "${JAVA_BIN}")")"

cat > /etc/systemd/system/myapp.service <<EOF
[Unit]
Description=MyApp Spring Boot Service
After=network-online.target
Wants=network-online.target
ConditionPathExists=${JAR_PATH}

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${APP_DIR}
Environment=JAVA_HOME=${JAVA_HOME_DIR}
EnvironmentFile=-${ENV_FILE}
ExecStart=/usr/bin/env bash -lc 'exec ${JAVA_HOME_DIR}/bin/java \${JAVA_OPTS:-} -jar ${JAR_PATH}'
SuccessExitStatus=143
Restart=on-failure
RestartSec=10
UMask=0027
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

############################
# [6] 런타임 env 파일 작성 (inject_runtime_config.sh의 [3] 단계와 동일)
############################
cat > "${ENV_FILE}" <<EOF
SPRING_PROFILES_ACTIVE="prod"
SERVER_PORT="8080"
APP_ENV="dr"
SPRING_DATASOURCE_URL="jdbc:mysql://${db_url}:3306/appdb?serverTimezone=Asia/Seoul&useSSL=false&allowPublicKeyRetrieval=true"
SPRING_DATASOURCE_USERNAME="${db_username}"
SPRING_DATASOURCE_PASSWORD="${db_password}"
JAVA_OPTS="-Xms256m -Xmx512m"
EOF

chown "${APP_USER}:${APP_GROUP}" "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

############################
# [7] 서비스 시작 + 헬스체크 (inject_runtime_config.sh의 [4]~[6] 단계 요약)
############################
systemctl daemon-reload
systemctl enable --now "${SERVICE_NAME}"

# ALB가 자체 헬스체크 하므로 여기서 대기는 필수 아님.
# 그래도 부팅 직후 상태를 로그에 남겨두면 디버깅에 유용.
for i in $(seq 1 30); do
  if curl --silent --fail --max-time 3 "http://127.0.0.1:8080/actuator/health" >/dev/null 2>&1; then
    echo "[user_data] actuator/health OK after ${i} attempts"
    break
  fi
  sleep 2
done || true

echo "[user_data] springboot EC2 초기화 완료"
