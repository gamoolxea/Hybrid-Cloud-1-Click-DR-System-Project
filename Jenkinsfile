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
        // 2. Phase 2 (Failover to AWS)
        // ============================================================
        stage('Execute Phase 2 (Failover to AWS)') {
            when { expression { params.DR_ACTION == 'Phase 2 (Failover)' } }
            steps {
                echo '===================================================='
                echo '[Phase 2 시작] AWS 환경으로 트래픽 Failover를 준비합니다.'
                echo '1. Terraform 설정 및 초기화 (terraform init)'
                echo '2. AWS 리소스 프로비저닝 (terraform apply)'
                echo '3. RDS Primary 승격 등 데이터베이스 작업'
                echo '===================================================='
                // 향후 이곳에 Terraform 실행 쉘 스크립트(sh)가 들어갑니다.
            }
        }

        // ============================================================
        // 3. Phase 3 (Failback to On-Premise)
        //    - 최신 Release asset을 Jenkins 워크스페이스로 다운로드
        //    - Ansible이 로컬 jar을 WEBWAS에 copy
        // ============================================================
        stage('Execute Phase 3 (Failback to On-Premise)') {
            when { expression { params.DR_ACTION == 'Phase 3 (Failback)' } }
            steps {
                echo '===================================================='
                echo '[Phase 3 시작] 온프레미스 환경으로 Failback을 준비합니다.'
                echo '===================================================='

                // 3-1) 최신 Release의 jar asset 다운로드
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

                // 3-2) Ansible 실행 (로컬 jar을 복사 모드로 배포)
                dir('Ansible') {
                    script {
                        try {
                            echo "▶ Ansible Playbook(site.yml) 실행 - jar 복사 배포"
                            sh '''
                                ansible-playbook -i inventories/on-premise/hosts.yml \
                                    playbooks/site.yml \
                                    -e "spring_boot_jar_src=${WORKSPACE}/${ARTIFACT}"
                            '''
                            echo "▶ Phase 3 복구 완료: 서비스가 정상적으로 온프레미스로 전환되었습니다."
                        } catch (Exception e) {
                            error("Ansible Playbook 실행 중 오류가 발생했습니다: ${e.message}")
                        }
                    }
                }
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
