pipeline {
    agent any

    // 관리자가 UI에서 선택할 수 있는 파라미터 정의
    parameters {
        choice(name: 'DR_ACTION', 
               choices: ['Select Action', 'Phase 2 (Failover)', 'Phase 3 (Failback)'], 
               description: '수행할 재해 복구(DR) 단계를 선택하세요.')
    }

    stages {
        // 1. 선택 검증 단계
        stage('Validation') {
            steps {
                script {
                    if (params.DR_ACTION == 'Select Action') {
                        error("수행할 DR 단계를 선택해야 합니다. 파이프라인을 중단합니다.")
                    }
                    echo "선택된 작업: ${params.DR_ACTION}"
                }
            }
        }

        // 2. Phase 2 (Failover) 실행 단계
        stage('Execute Phase 2 (Failover to AWS)') {
            when { 
                expression { params.DR_ACTION == 'Phase 2 (Failover)' } 
            }
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

        // 3. Phase 3 (Failback) 실행 단계
        stage('Execute Phase 3 (Failback to On-Premise)') {
            when { 
                expression { params.DR_ACTION == 'Phase 3 (Failback)' } 
            }
            steps {
                echo '===================================================='
                echo '[Phase 3 시작] 온프레미스 환경으로 Failback을 준비합니다.'
                echo '===================================================='
                
                // Ansible 코드가 있는 디렉토리로 이동하여 실행
                dir('Ansible') {
                    script {
                        try {
                            echo "▶ Ansible Playbook(site.yml)을 통한 온프레미스 프로비저닝 시작"
                            
                            // 실제 Ansible 실행 명령어
                            sh '''
                            ansible-playbook -i inventories/on-premise/hosts.yml playbooks/site.yml
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
}