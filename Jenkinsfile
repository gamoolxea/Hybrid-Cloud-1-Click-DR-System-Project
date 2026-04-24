pipeline {
    agent any

    environment {
        REPO        = 'Soldesk-Cloud/hybrid-cloud-dr-infra'
        APP_DIR     = 'app'
        JAR_NAME    = 'logistics-system.jar'
        ARTIFACT    = "artifacts/logistics-system.jar"
    }

    parameters {
        choice(
            name: 'DR_ACTION',
            choices: [
                'Select Action',
                'Build & Release App',
                'Phase 1 (Deploy App to On-Premise)',
                'Phase 2 (Failover)',
                'Phase 3 (Failback)'
            ],
            description: '수행할 작업을 선택하세요.'
        )
    }

    stages {

        // ============================================================
        // 0. 선택 검증
        // ============================================================
        stage('Validation') {
            steps {
                script {
                    if (params.DR_ACTION == 'Select Action') {
                        error("수행할 작업을 선택해야 합니다. 파이프라인을 중단합니다.")
                    }
                    echo "선택된 작업: ${params.DR_ACTION}"
                }
            }
        }

        // ============================================================
        // 1. Spring Boot 빌드 + GitHub Release 생성
        // ============================================================
        stage('Build & Release App') {
            when { expression { params.DR_ACTION == 'Build & Release App' } }
            steps {
                echo '===================================================='
                echo '[Build & Release] Spring Boot 앱 빌드 및 GitHub Release 생성'
                echo '===================================================='

                dir("${env.APP_DIR}") {
                    sh '''
                        set -e
                        java -version
                        chmod +x gradlew
                        ./gradlew clean bootJar
                        ls -la build/libs/
                    '''
                }

                withCredentials([usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'GH_USER',
                        passwordVariable: 'GH_TOKEN')]) {
                    script {
                        def tag = "app-${new Date().format('yyyyMMdd-HHmmss')}-b${env.BUILD_NUMBER}"
                        env.RELEASE_TAG = tag
                    }
                    sh '''
                        set -e
                        echo "▶ Release 생성: ${RELEASE_TAG}"

                        cat > release-payload.json <<EOF
{
  "tag_name": "${RELEASE_TAG}",
  "name": "${RELEASE_TAG}",
  "target_commitish": "main",
  "body": "logistics-system build #${BUILD_NUMBER} (Jenkins)"
}
EOF

                        RESP=$(curl -fsS -X POST \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Accept: application/vnd.github+json" \
                            "https://api.github.com/repos/${REPO}/releases" \
                            --data @release-payload.json)

                        UPLOAD_URL=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['upload_url'].split('{')[0])")
                        RELEASE_ID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")

                        echo "▶ jar 업로드 중... (release_id=${RELEASE_ID})"

                        curl -fsS -X POST \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Content-Type: application/java-archive" \
                            --data-binary @${APP_DIR}/build/libs/${JAR_NAME} \
                            "${UPLOAD_URL}?name=${JAR_NAME}" > upload-resp.json

                        ASSET_URL=$(python3 -c "import json; print(json.load(open('upload-resp.json'))['browser_download_url'])")
                        echo "✅ Release 완료: ${ASSET_URL}"
                    '''
                }
            }
        }

        // ============================================================
        // 1-B. Phase 1 (App Only Deploy to On-Premise)
        //      - 이미 구축된 Phase 1 온프레미스 환경에 jar만 배포
        //      - HAProxy/DB 재프로비저닝 없이 webwas.yml만 실행
        // ============================================================
        stage('Execute Phase 1 (Deploy App to On-Premise)') {
            when { expression { params.DR_ACTION == 'Phase 1 (Deploy App to On-Premise)' } }
            steps {
                echo '===================================================='
                echo '[Phase 1 시작] Phase 1 온프레미스 환경에 앱만 배포합니다.'
                echo '===================================================='

                withCredentials([usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'GH_USER',
                        passwordVariable: 'GH_TOKEN')]) {
                    sh '''
                        set -e
                        mkdir -p artifacts
                        rm -f ${ARTIFACT}

                        echo "▶ 최신 Release 정보 조회..."
                        LATEST=$(curl -fsS \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Accept: application/vnd.github+json" \
                            "https://api.github.com/repos/${REPO}/releases/latest")

                        TAG=$(echo "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
                        ASSET_ID=$(echo "$LATEST" | python3 -c "import sys,json; r=json.load(sys.stdin); xs=[a for a in r['assets'] if a['name']=='${JAR_NAME}']; print(xs[0]['id'] if xs else '')")

                        if [ -z "$ASSET_ID" ]; then
                            echo "❌ ERROR: 최신 Release(${TAG})에 ${JAR_NAME} asset이 없습니다."
                            echo "   먼저 'Build & Release App'을 실행해 주세요."
                            exit 1
                        fi

                        echo "▶ 다운로드: tag=${TAG}, asset_id=${ASSET_ID}"

                        curl -fsSL \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Accept: application/octet-stream" \
                            "https://api.github.com/repos/${REPO}/releases/assets/${ASSET_ID}" \
                            -o ${ARTIFACT}

                        ls -la ${ARTIFACT}
                        echo "✅ 다운로드 완료"
                    '''
                }

                dir('Ansible') {
                    script {
                        try {
                            echo "▶ Ansible Playbook(webwas.yml) 실행 - Phase 1 환경 앱 배포"
                            sh '''
                                ansible-playbook -i inventories/on-premise-phase1/hosts.yml \
                                    playbooks/webwas.yml \
                                    -e "spring_boot_jar_src=${WORKSPACE}/${ARTIFACT}"
                            '''
                            echo "▶ Phase 1 앱 배포 완료"
                        } catch (Exception e) {
                            error("Ansible Playbook 실행 중 오류가 발생했습니다: ${e.message}")
                        }
                    }
                }
            }
        }

        // ============================================================
        // 2. Phase 2 (Failover to AWS)
        //    - Terraform apply로 dr_mode=true 전환 (ALB TG 교체 + ASG 0→N scale up)
        //    - EC2 user_data가 jar 다운로드 + Actuator health 자동화
        //    - ALB에서 타겟 healthy 대기
        //    - RDS 복제 정지 (primary 승격)
        //    - Smoke test
        // ============================================================
        stage('Execute Phase 2 (Failover to AWS)') {
            when { expression { params.DR_ACTION == 'Phase 2 (Failover)' } }
            environment {
                TF_DIR    = 'project-springboot-dev/root/dr'
                AWS_REGION = 'ap-northeast-2'
                TG_NAME   = 'project-springboot-tg'
                CONFIG_DIR = '/etc/hybrid-dr'
            }
            steps {
                echo '===================================================='
                echo '[Phase 2 시작] AWS 환경으로 트래픽 Failover 진행'
                echo '===================================================='

                // 2-1) Terraform init + apply (dr_mode=true, ASG 풀 가동)
                dir("${env.TF_DIR}") {
                    sh '''
                        set -e
                        echo "▶ 1/6: Terraform init + apply (dr-active.tfvars)"
                        terraform init -reconfigure \
                          -backend-config=${CONFIG_DIR}/backend.hcl
                        terraform apply \
                          -var-file=${CONFIG_DIR}/terraform.tfvars \
                          -var-file="dr-active.tfvars" \
                          -auto-approve
                    '''
                }

                // 2-2) ALB에서 ASG 타겟이 healthy가 될 때까지 대기 (최대 10분)
                sh '''
                    set -e
                    echo "▶ 2/6: ALB 타겟 healthy 대기 (EC2 user_data가 jar + actuator health까지 준비)"
                    SPRINGBOOT_TG_ARN=$(aws elbv2 describe-target-groups \
                      --names ${TG_NAME} \
                      --region ${AWS_REGION} \
                      --query 'TargetGroups[0].TargetGroupArn' --output text)
                    echo "TG ARN: $SPRINGBOOT_TG_ARN"

                    HEALTHY=0
                    for i in $(seq 1 60); do
                      HEALTHY=$(aws elbv2 describe-target-health \
                        --target-group-arn "$SPRINGBOOT_TG_ARN" \
                        --region ${AWS_REGION} \
                        --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
                        --output text)
                      echo "[$i/60] Healthy targets: $HEALTHY"
                      if [ "$HEALTHY" -gt "0" ]; then break; fi
                      sleep 10
                    done

                    if [ "$HEALTHY" -eq "0" ]; then
                      echo "❌ ERROR: 10분 내 healthy 타겟 없음. EC2 로그 확인 필요 (user_data 실패 가능)"
                      exit 1
                    fi
                    echo "✅ ASG healthy: $HEALTHY 대"
                '''

                // 2-3) RDS lag=0 확인 (데이터 유실 방지 사전 검증)
                //   RDS의 SHOW SLAVE STATUS로 Seconds_Behind_Master 조회
                //   DB EC2에서 넘어오는 복제가 다 따라잡혔는지 확인
                sh '''
                    set -e
                    echo "▶ 3/6: RDS → DB EC2 복제 lag = 0 확인 (최대 1분 폴링)"

                    cd ${TF_DIR}
                    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
                    cd - > /dev/null

                    DB_PASSWORD=$(grep '^db_password' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    LAG_READY=0
                    for i in $(seq 1 30); do
                      LAG=$(mysql -h "$RDS_ENDPOINT" -u admin -p"$DB_PASSWORD" \
                        -e "SHOW SLAVE STATUS\\G" 2>/dev/null \
                        | grep "Seconds_Behind_Master" | awk '{print $2}')

                      echo "[$i/30] Seconds_Behind_Master = ${LAG:-EMPTY}"

                      if [ "$LAG" = "0" ]; then
                        LAG_READY=1
                        break
                      fi
                      sleep 2
                    done

                    if [ "$LAG_READY" != "1" ]; then
                      echo "❌ RDS lag이 1분 내 0이 되지 않음"
                      echo "   → 페일오버 중단 (데이터 유실 위험). 수동 확인 필요:"
                      echo "   mysql -h $RDS_ENDPOINT -u admin -p\\$DB_PASS -e 'SHOW SLAVE STATUS\\\\G'"
                      exit 1
                    fi
                    echo "✅ RDS lag = 0 확인 (RDS가 DB EC2 상태 완전히 동기화 완료)"
                '''

                // 2-4) DB EC2 격리 — Option B 소프트 페일오버
                //   STOP SLAVE       : 온프렘으로부터 복제 수신 중단
                //   RESET SLAVE ALL  : master 연결 정보 완전 삭제 (standalone 상태)
                //   super_read_only  : 모든 쓰기 차단 (SUPER 권한자 포함) → 스플릿 브레인 방지
                //   → DB EC2는 "frozen read-only snapshot" 상태로 DR 기간 유지
                sh '''
                    set -e
                    echo "▶ 4/6: DB EC2 격리 (STOP SLAVE → RESET SLAVE ALL → super_read_only=ON)"

                    cd ${TF_DIR}
                    DB_EC2_IP=$(terraform output -raw db_ec2_private_ip)
                    cd - > /dev/null

                    DB_PASSWORD=$(grep '^db_password' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    echo "DB EC2: $DB_EC2_IP (user: repl_user)"

                    mysql -h "$DB_EC2_IP" -u repl_user -p"$DB_PASSWORD" 2>&1 | tee /tmp/db_ec2_iso.log <<'SQL' || true
STOP SLAVE;
RESET SLAVE ALL;
SET GLOBAL super_read_only = ON;
SQL

                    # "Slave ... not running" 외의 error만 실패 처리 (이미 stop된 상태는 OK)
                    if grep -i "ERROR" /tmp/db_ec2_iso.log \
                       | grep -vi "Slave.*not running" \
                       | grep -vi "Replica.*not running" > /dev/null; then
                      echo "❌ DB EC2 격리 실패"
                      cat /tmp/db_ec2_iso.log
                      echo ""
                      echo "   → repl_user 권한 부족일 수 있음. DB EC2에서 1회 실행 필요:"
                      echo "   GRANT REPLICATION_SLAVE_ADMIN, SYSTEM_VARIABLES_ADMIN, REPLICATION CLIENT"
                      echo "     ON *.* TO 'repl_user'@'%'; FLUSH PRIVILEGES;"
                      exit 1
                    fi
                    echo "✅ DB EC2 frozen read-only snapshot 완료"
                '''

                // 2-5) RDS 복제 정지 → RDS를 standalone primary로 승격
                sh '''
                    set -e
                    echo "▶ 5/6: RDS replication 정지 (standalone primary 승격)"

                    cd ${TF_DIR}
                    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
                    cd - > /dev/null

                    DB_PASSWORD=$(grep '^db_password' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    mysql -h "$RDS_ENDPOINT" -u admin -p"$DB_PASSWORD" \
                      -e "CALL mysql.rds_stop_replication;" 2>&1 | tee /tmp/rds_stop.log || true

                    # "not running" 이외의 error는 진짜 실패
                    if grep -i "error" /tmp/rds_stop.log | grep -vi "not running" | grep -vi "warning" > /dev/null; then
                      echo "❌ RDS stop_replication 실패"
                      cat /tmp/rds_stop.log
                      exit 1
                    fi
                    echo "✅ RDS 복제 정지 완료 (RDS가 standalone primary로 승격됨)"
                '''

                // 2-6) Smoke test: ALB를 통한 애플리케이션 정상 응답 확인
                sh '''
                    set +e
                    echo "▶ 6/6: Smoke test (ALB → Spring Boot /actuator/health)"
                    DOMAIN=$(grep '^route53_zone_name' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    SUCCESS=0
                    for i in $(seq 1 12); do
                      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$DOMAIN/actuator/health" || echo "000")
                      echo "[$i/12] GET http://$DOMAIN/actuator/health -> $HTTP_CODE"
                      if [ "$HTTP_CODE" = "200" ]; then SUCCESS=1; break; fi
                      sleep 10
                    done

                    if [ "$SUCCESS" = "1" ]; then
                      echo "✅ Smoke test PASSED"
                    else
                      echo "⚠️  WARNING: 2분 내 200 응답 없음"
                      echo "   수동 확인: curl -v http://$DOMAIN/actuator/health"
                      exit 1
                    fi
                '''

                echo '▶ Phase 2 완료'
            }
        }

        // ============================================================
        // 3. Phase 3 (Failback to On-Premise)
        //    3-1. 최신 Release jar 다운로드
        //    3-2. Ansible site.yml (온프렘 3VM 전체 프로비저닝 + jar 배포)
        //    3-3. Jenkins가 RDS에서 mysqldump → ${WORKSPACE}/dump.sql
        //    3-4. Ansible db_failback.yml (dump 복사 + restore + Spring Boot 재시작)
        //    3-5. Terraform apply pilot-light.tfvars (AWS 회수: ASG=0, ALB→haproxy-tg)
        //    3-6. Smoke test (ALB → HAProxy → onprem Spring Boot)
        // ============================================================
        stage('Execute Phase 3 (Failback to On-Premise)') {
            when { expression { params.DR_ACTION == 'Phase 3 (Failback)' } }
            environment {
                TF_DIR     = 'project-springboot-dev/root/dr'
                AWS_REGION = 'ap-northeast-2'
                CONFIG_DIR = '/etc/hybrid-dr'
            }
            steps {
                echo '===================================================='
                echo '[Phase 3 시작] 온프레미스 환경으로 Failback을 진행합니다.'
                echo '===================================================='

                // 3-1) 최신 Release의 jar asset 다운로드
                withCredentials([usernamePassword(
                        credentialsId: 'github-pat',
                        usernameVariable: 'GH_USER',
                        passwordVariable: 'GH_TOKEN')]) {
                    sh '''
                        set -e
                        echo "▶ 1/6: 최신 Release jar 다운로드"
                        mkdir -p artifacts
                        rm -f ${ARTIFACT}

                        LATEST=$(curl -fsS \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Accept: application/vnd.github+json" \
                            "https://api.github.com/repos/${REPO}/releases/latest")

                        TAG=$(echo "$LATEST" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
                        ASSET_ID=$(echo "$LATEST" | python3 -c "import sys,json; r=json.load(sys.stdin); xs=[a for a in r['assets'] if a['name']=='${JAR_NAME}']; print(xs[0]['id'] if xs else '')")

                        if [ -z "$ASSET_ID" ]; then
                            echo "❌ ERROR: 최신 Release(${TAG})에 ${JAR_NAME} asset이 없습니다."
                            echo "   먼저 'Build & Release App'을 실행해 주세요."
                            exit 1
                        fi

                        curl -fsSL \
                            -H "Authorization: token ${GH_TOKEN}" \
                            -H "Accept: application/octet-stream" \
                            "https://api.github.com/repos/${REPO}/releases/assets/${ASSET_ID}" \
                            -o ${ARTIFACT}

                        ls -la ${ARTIFACT}
                        echo "✅ jar 다운로드 완료 (tag=${TAG})"
                    '''
                }

                // 3-2) Ansible site.yml — 온프렘 3VM 전체 프로비저닝
                //   - common, haproxy, tailscale(haproxy만), mysql, springboot
                //   - Spring Boot는 빈 DB 상태로 기동 (Hibernate ddl-auto=update가 스키마 생성)
                //   - 다음 단계에서 RDS 데이터로 덮어쓸 예정
                dir('Ansible') {
                    sh '''
                        set -e
                        echo "▶ 2/6: Ansible site.yml 실행 (온프렘 3VM 재구축)"
                        ansible-playbook -i inventories/on-premise/hosts.yml \
                            playbooks/site.yml \
                            -e "spring_boot_jar_src=${WORKSPACE}/${ARTIFACT}"
                        echo "✅ 온프레미스 프로비저닝 완료"
                    '''
                }

                // 3-3) Jenkins가 RDS에서 mysqldump
                //   - --single-transaction: InnoDB 일관성 스냅샷 (lock 없이)
                //   - --add-drop-table: restore 시 기존 빈 테이블(Hibernate 자동 생성본) 덮어쓰기
                //   - --no-tablespaces: PROCESS 권한 없는 RDS admin 호환
                //   - DB 이름 'appdb'만 지정 (--databases 미사용) → dump 파일에 USE/CREATE 없음
                //     → restore 시 DB명 자유 매핑 가능 (appdb → logistics)
                //   - MYSQL_PWD 환경변수 사용 (ps 목록 비밀번호 노출 방지)
                sh '''
                    set -e
                    echo "▶ 3/6: RDS에서 mysqldump → ${WORKSPACE}/dump.sql"

                    cd ${TF_DIR}
                    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
                    cd - > /dev/null

                    DB_PASSWORD=$(grep '^db_password' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    export MYSQL_PWD="$DB_PASSWORD"

                    mysqldump \
                        -h "$RDS_ENDPOINT" \
                        -u admin \
                        --single-transaction \
                        --add-drop-table \
                        --no-tablespaces \
                        appdb > ${WORKSPACE}/dump.sql

                    unset MYSQL_PWD

                    ls -lh ${WORKSPACE}/dump.sql
                    DUMP_LINES=$(wc -l < ${WORKSPACE}/dump.sql)
                    echo "✅ RDS dump 완료: ${DUMP_LINES} 라인"
                '''

                // 3-4) Ansible db_failback.yml 실행
                //   - dump.sql → onprem DB VM으로 copy (ProxyJump via HAProxy Tailscale)
                //   - mysql logistics < dump.sql (DB 이름 매핑 appdb → logistics)
                //   - WEBWAS Spring Boot 재시작 (HikariCP 커넥션 풀 리프레시)
                //   - /actuator/health 200 대기
                dir('Ansible') {
                    sh '''
                        set -e
                        echo "▶ 4/6: Ansible db_failback.yml (RDS dump → onprem restore)"
                        ansible-playbook -i inventories/on-premise/hosts.yml \
                            playbooks/db_failback.yml \
                            -e "dump_src=${WORKSPACE}/dump.sql"
                        echo "✅ 온프렘 DB 복원 + Spring Boot 재시작 완료"
                    '''
                }

                // 3-5) Terraform apply pilot-light.tfvars — AWS 회수
                //   - dr_mode=false: ALB listener → haproxy-tg (트래픽 온프렘으로)
                //   - ASG min/desired = 0: Spring Boot EC2 스케일 다운
                //     → 이중 처리 방지 + 비용 절감
                //   이 순간 ALB 플립 = 사용자 트래픽이 온프렘으로 전환됨
                dir("${env.TF_DIR}") {
                    sh '''
                        set -e
                        echo "▶ 5/6: Terraform apply pilot-light.tfvars (AWS 회수)"
                        terraform init -reconfigure \
                          -backend-config=${CONFIG_DIR}/backend.hcl
                        terraform apply \
                          -var-file=${CONFIG_DIR}/terraform.tfvars \
                          -var-file="pilot-light.tfvars" \
                          -auto-approve
                        echo "✅ AWS 회수 완료: ALB → haproxy-tg, ASG=0"
                    '''
                }

                // 3-6) Smoke test: ALB → HAProxy → onprem Spring Boot 200 확인
                sh '''
                    set +e
                    echo "▶ 6/6: Smoke test (ALB → HAProxy → onprem Spring Boot)"
                    DOMAIN=$(grep '^route53_zone_name' ${CONFIG_DIR}/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

                    SUCCESS=0
                    for i in $(seq 1 12); do
                      HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$DOMAIN/actuator/health" || echo "000")
                      echo "[$i/12] GET http://$DOMAIN/actuator/health -> $HTTP_CODE"
                      if [ "$HTTP_CODE" = "200" ]; then SUCCESS=1; break; fi
                      sleep 10
                    done

                    if [ "$SUCCESS" = "1" ]; then
                      echo "✅ Phase 3 Failback 완료: 서비스가 온프레미스로 정상 전환됨"
                    else
                      echo "⚠️  WARNING: 2분 내 200 응답 없음"
                      echo "   수동 확인: curl -v http://$DOMAIN/actuator/health"
                      exit 1
                    fi
                '''

                echo '▶ Phase 3 완료'
            }
        }
    }

    post {
        success {
            script {
                if (params.DR_ACTION == 'Build & Release App') {
                    echo "✅ Release 생성 성공: ${env.RELEASE_TAG}"
                }
            }
        }
        cleanup {
            // 민감 파일 정리
            sh 'rm -f release-payload.json upload-resp.json || true'
        }
    }
}
