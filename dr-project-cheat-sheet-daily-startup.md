# DR Project — Daily Startup Cheat Sheet

> 매일 아침 학원 도착 후 작업 시작 루틴. 매번 까먹지 않으려고 정리.

**Last updated**: 2026-04-26

---

## A. AWS EC2 시작 (콘솔)

브라우저 → [AWS Console → EC2 → Instances](https://console.aws.amazon.com/ec2/home?region=ap-northeast-2#Instances:)

**시작 순서** (Bastion 먼저!):

1. ✅ `project-bastion` → Start instance
2. (1~2분 대기 후) `project-jenkins` → Start instance
3. `project-haproxy` → Start instance
4. `project-db-ec2` → Start instance

> 💡 **WHY Bastion 먼저**: Jenkins / HAProxy / DB EC2 는 private subnet 이라 Bastion 거쳐야 SSH 가능. Bastion 이 켜져있어야 다른 인스턴스에 도달.

---

## B. Bastion 의 현재 IP 확인 (필수)

EC2 stop/start 하면 Bastion 의 Public IP 가 **바뀝니다** (EIP 미할당 상태).

AWS Console 에서 `project-bastion` 클릭 → **`Public IPv4 address`** 복사.

> 예: `43.200.254.28` (어제 IP. 오늘 다를 수 있음)

---

## C. SSH config 업데이트 (IP 바뀌었으면)

```powershell
# [SESSION: Windows PowerShell | at 아무 디렉토리]
notepad C:\Users\cpj32\.ssh\config
```

`Host bastion` 아래 `HostName` 만 새 IP 로 교체 → 저장 → 닫기:

```
Host bastion
    HostName <새 IP 박기>     ← 이 부분만 수정
    User ec2-user
    IdentityFile C:\sshkeys\my_key.pem
```

> ⚠️ Jenkins, db-ec2 는 `ProxyJump bastion` 으로 박혀있어서 자동으로 새 IP 따라감. **Bastion HostName 한 줄만** 수정하면 됨.

---

## D. SSH 세션 띄우기 (PowerShell 창 3개 추천)

### 창 1 — Jenkins SSH (작업용)

```powershell
# [SESSION: Windows PowerShell #1 | at 아무 디렉토리]
ssh jenkins
```

### 창 2 — Jenkins UI port forward (브라우저용)

```powershell
# [SESSION: Windows PowerShell #2 | at 아무 디렉토리]
ssh -L 8080:10.0.41.31:8080 bastion
```

이 창은 **닫지 말고 그대로 유지**. 닫으면 터널 끊김.

### 창 3 — DB EC2 SSH (필요 시)

```powershell
# [SESSION: Windows PowerShell #3 | at 아무 디렉토리]
ssh db-ec2
```

---

## E. 브라우저 — Jenkins UI 접속

```
http://localhost:8080
```

(또는 Step D 에서 8080 포워드했으면 `http://localhost:8080`)

---

## F. 작업 끝나고 — AWS EC2 종료 (밤)

AWS Console 에서 4대 모두 **Stop instances**:

- `project-jenkins`
- `project-haproxy`
- `project-db-ec2`
- `project-bastion` (← 마지막)

> 💰 **WHY Stop 만**: Terminate 하면 인스턴스 삭제됨. Stop 은 디스크 (EBS) 만 유지하고 컴퓨팅 비용 멈춤. 다음 날 Start 하면 동일 디스크 기반으로 다시 가동.

---

## G. ⚠️ 공통 트러블

| 증상 | 원인 | 해결 |
|---|---|---|
| `ssh bastion` → `Connection timed out` | Bastion IP 바뀜 | Step B, C 로 IP 갱신 |
| `ssh jenkins` → `Connection refused` | Jenkins 아직 부팅 중 | 1~2분 대기 |
| `Permission denied` | 키 파일 경로 틀림 | `C:\sshkeys\my_key.pem` 존재 확인 |
| 브라우저 `localhost:8080` 접속 안 됨 | 터널 창 (Step D 창 2) 닫힘 | 창 다시 열기 |
| `bind [127.0.0.1]:8080: Permission denied` | 로컬 8080 이미 사용 중 | 9090 같은 다른 포트 사용 |
| `dubious ownership` git 에러 | Jenkins workspace 가 jenkins 유저 소유, ec2-user 로 git 명령 실행 | `sudo -u jenkins git -C /var/lib/jenkins/workspace/<job-name> ...` 사용 |

---

## H. Jenkins 빌드 트리거 — 빠른 참고

브라우저 `localhost:8080` 에서:

1. `hybrid-dr-pipeline` 클릭
2. **`파라미터로 빌드`** 클릭
3. `DR_ACTION` 드롭다운에서 선택:
   - **`Phase 1 (Deploy App to On-Premise)`** — 새 jar 만 webwas 에 배포 (재고관리 앱 업데이트)
   - **`Phase 2 (Failover)`** — AWS 로 Failover (ASG 0→2, ALB → SpringBoot, RDS 승격)
   - **`Phase 3 (Failback)`** — 온프렘 복귀 (Ansible 풀 재구축 + DB 복원 + AWS 회수)
4. **`빌드`** 클릭

---

## I. 자주 쓰는 검증 명령어

### Spring Boot 헬스 체크

```bash
# [SESSION: Windows PowerShell | at 아무 디렉토리]
curl http://soldeskloud.xyz/actuator/health
```

기대: `{"status":"UP",...}`

### DR 모드 상태 (운영 / DR ACTIVE)

```bash
# [SESSION: Windows PowerShell | at 아무 디렉토리]
curl http://soldeskloud.xyz/api/system/status
```

기대 (Phase 1 / Phase 3): `{"appEnv":"prod","drMode":false,"label":"운영","message":""}`
기대 (Phase 2): `{"appEnv":"aws-dr","drMode":true,"label":"DR ACTIVE","message":"현재 AWS DR 환경으로 서비스 중입니다."}`

### CloudWatch 알람 상태

```bash
# [SESSION: Jenkins EC2 SSH]
aws cloudwatch describe-alarms --region ap-northeast-2 --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table
```

### RDS Replication 상태 (cascade 살아있는지)

```bash
# [SESSION: Jenkins EC2 SSH]
RDS_ENDPOINT=$(cd /var/lib/jenkins/workspace/hybrid-dr-pipeline/project-springboot-dev/root/dr && sudo -u jenkins terraform output -raw rds_endpoint)
DB_PASSWORD=$(sudo grep '^db_password' /etc/hybrid-dr/terraform.tfvars | cut -d'=' -f2- | tr -d ' "\r\n')

mysql -h "$RDS_ENDPOINT" -u admin -p"$DB_PASSWORD" -e "SHOW SLAVE STATUS\G" | grep -E "Master_Host|Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_Error"
```

---

## J. 자주 잊는 경로 / 파일

| 파일 / 경로 | 용도 |
|---|---|
| `/etc/hybrid-dr/terraform.tfvars` | Jenkins EC2 의 실제 Terraform 변수 (gitignore 라 push 안 됨) |
| `/etc/hybrid-dr/backend.hcl` | Terraform backend 설정 (S3) |
| `/var/lib/jenkins/workspace/hybrid-dr-pipeline/` | Jenkins workspace (git pull 결과) |
| `C:\sshkeys\my_key.pem` | EC2 keypair 의 private key |
| `C:\Users\cpj32\.ssh\config` | SSH alias (bastion / jenkins / db-ec2) |
| `C:\Users\cpj32\Desktop\프로젝트\Git\` | 인프라 monorepo (로컬) |
| `C:\Users\cpj32\Desktop\프로젝트\inventory-app\` | 앱 소스 (별도 레포 clone) |

---

## K. Phase 3 VM (온프렘) — VMware

발표/시연 시:

- VMware 에서 **`demo-baseline-2026-04-25`** 스냅샷으로 revert (3대 모두)
- Power on 순서: HAProxy → WEBWAS / DB (HAProxy 가 subnet router 라 먼저)
- 부팅 후 1~2분 대기 (Tailscale 자동 재연결)
- Jenkins 에서 Phase 3 빌드 트리거

---

## ✂️ 이 cheat-sheet 의 위치

```
C:\Users\cpj32\Desktop\프로젝트\Git\dr-project-cheat-sheet-daily-startup.md
```

매일 아침 열어서 A~E 만 따라하면 됨.
