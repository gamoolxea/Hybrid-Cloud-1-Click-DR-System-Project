# 2026-05-05 시연 영상 녹화 트러블슈팅 학습 자료

> 오늘 시연 영상 녹화 과정에서 마주친 6가지 이슈의 정리 + 학습 포인트.
> 발표 직전 reference + 인프라 엔지니어 학습 자료.

---

## 이슈 #1: RDS replication 이 반복적으로 STOP ⭐⭐⭐ (가장 큰 이슈)

### 증상
- `SHOW SLAVE STATUS\G` 결과:
  - `Slave_IO_Running: No`
  - `Slave_SQL_Running: No`
  - `Last_Error / Last_IO_Error / Last_SQL_Error`: 모두 비어있음
  - `Seconds_Behind_Master: NULL`
- 빌드의 lag check 가 `[XX/30] Seconds_Behind_Master = NULL` 무한 반복 → timeout 으로 빌드 실패
- 오늘 같은 패턴으로 **3번 반복** (아침 발견 / 시연 후 / 재시연 직전)

### 가설/원인
- 에러 메시지 없이 IO/SQL Running 모두 No = **누군가/무언가 명시적 `STOP SLAVE` 호출**
- 가장 가능성 높은 원인: **Failover/Failback 빌드 스크립트의 cleanup 단계에서 START SLAVE 누락**
  - 빌드 진행 중 RDS 를 master 로 promote 또는 demote 하는 단계에서 STOP SLAVE 호출
  - 빌드 끝날 때 START SLAVE 호출이 누락 또는 실패
- 다른 가설: RDS 자동 maintenance / 백업 작업 시 일시 STOP

### 임시 해결
```bash
mysql -h <RDS endpoint> -u admin -p<password> -e "CALL mysql.rds_start_replication;"
```
→ `Slave_IO_Running: Yes / Slave_SQL_Running: Yes / Seconds_Behind_Master: 0` 즉시 복구

### 검증
```bash
mysql -h <RDS> -e "SHOW SLAVE STATUS\G" | grep -E "Slave_(IO|SQL)_Running|Seconds_Behind_Master"
```
- Yes / Yes / 0 + (혹은 작은 양수, 따라잡는 중)

### 근본 fix (발표 후 작업)
1. **Jenkinsfile 또는 Ansible 의 Failover/Failback 빌드 cleanup 단계 점검**
   - 빌드 완료 시점에 RDS replication 상태 확인 + 자동 START SLAVE 추가
2. **빌드 마지막 단계에 항상**:
   ```bash
   mysql -h <RDS> -e "CALL mysql.rds_start_replication;"
   sleep 5
   mysql -h <RDS> -e "SHOW SLAVE STATUS\G" | grep Slave_IO_Running | grep Yes || exit 1
   ```
3. **CloudWatch Alarm 추가**: `project-rds-replica-lag` 가 NULL 또는 매우 큰 값일 때 발화

### 학습 포인트 ⭐
- **`Seconds_Behind_Master: NULL`** 은 lag 가 아니라 **replication 자체가 작동 안 함** 을 의미
- **에러 없는 STOP** = 누가/무엇이 **명시적으로 STOP 호출함** — 시스템 fault 가 아니라 의도된 동작
- **자동화 빌드의 cleanup 단계 검증이 중요** — apply 만 검증하지 말고 rollback/cleanup 도
- **RDS 의 replication 명령은 `mysql.rds_*` stored procedure 사용** — 일반 MySQL 의 START/STOP SLAVE 와 권한 다름

---

## 이슈 #2: AUTO_INCREMENT reset 시 replication 영향 의심

### 증상
- onprem master 에서 `ALTER TABLE inventory.inventory AUTO_INCREMENT = 11;` 실행 후
- RDS 측에서 `SHOW SLAVE STATUS\G` → IO/SQL Running No (또 STOP)
- 단, Last_SQL_Error 비어있어서 ALTER 가 직접 원인인지는 단정 불가

### 가설/원인
- ALTER TABLE 이 binary log 에 기록 → RDS 에 전파 → RDS admin 권한으로 실행 시 어떤 권한 제약으로 SQL thread 정지 가능
- 또는 그저 우연히 같은 시점에 빌드/외부 요인으로 STOP

### 임시 해결
- 옵션 A: ALTER TABLE 사용 안 함 → DELETE 만으로 정리 (AUTO_INCREMENT 는 그대로 둠)
- 옵션 B: ALTER 실행 후 RDS 측에서 START SLAVE 다시

### 근본 fix
- 운영 DB 에서 ALTER TABLE AUTO_INCREMENT 같은 DDL 은 신중하게 — staging 환경에서 검증 후 운영 적용
- replication topology 의 모든 노드에서 동일 권한 보장
- 또는 application 레벨 ID 관리 (시퀀스 테이블 등) 로 DB AUTO_INCREMENT 의존도 ↓

### 학습 포인트
- **DDL (ALTER TABLE) 은 binary log 통해 replication 전파됨** — 모든 노드에서 같은 권한 + 같은 동작 가능해야 안전
- **DELETE 는 AUTO_INCREMENT 를 reset 안 함** — MySQL 의 InnoDB 동작
- **AUTO_INCREMENT 는 max_id 보다 작은 값으로 reset 안 됨** — DELETE 먼저 → ALTER 가 필수
- **RDS 의 권한 모델은 self-hosted MySQL 과 다름** — admin 도 일부 명령 제한

---

## 이슈 #3: OBS 화면 짤림 — 캡쳐 영역 잘못 설정

### 증상
- OBS 로 녹화한 영상에서 화면 일부 짤려 보임 (소스가 캔버스 밖으로 나감)

### 가설/원인
- **OBS 캔버스 해상도 ≠ 모니터 해상도**
- **Windows 디스플레이 스케일링 (125% / 150%)** 로 인한 좌표 어긋남
- 디스플레이 캡처 소스의 transform 잘못

### 해결
1. OBS → 파일 → 설정 → 비디오
2. 기본 (캔버스) 해상도 = 본인 모니터 해상도
3. 메인 화면에서 디스플레이 캡처 소스 클릭 → `Ctrl + F` (Fit to screen)
4. (필요 시) Windows 스케일링 100% 로 임시 변경
5. **5초 테스트 녹화** → 영상 확인 → 본 녹화

### 학습 포인트
- **OBS 의 캔버스 = 출력 영상의 frame** — 소스가 캔버스 밖으로 나가면 짤림
- **항상 짧은 테스트 녹화 후 본 녹화** — 시간 절약
- **디스플레이 스케일링 vs 캡처 좌표** — 노트북 + 외부 모니터 환경에서 자주 발생

---

## 이슈 #4: SSH 세션 끊김 (Failover 진행 중)

### 증상
- 시나리오 빌드 트리거 시 onprem master 에 접속한 SSH 세션 끊김
- watch 쿼리 화면이 멈춤 또는 에러
- 시연 영상에 영향 (당황해서 alt-tab)

### 가설/원인
- Failover 빌드 = onprem master 를 demote 하는 과정
- 그 와중에 mysqld 재시작, Tailscale subnet router 재구성 등 발생
- mysql client connection / SSH 세션 일시 끊김 = **시스템 정상 동작**

### 해결
1. **tmux 안에 watch 쿼리 띄우기**:
   ```bash
   tmux new -s demo
   watch -n 2 "mysql ..."
   ```
   → SSH 끊겨도 tmux 세션 살아있음. `tmux attach -t demo` 로 복귀.
2. **양쪽 (onprem + RDS) watch 쿼리 동시 운영**:
   - onprem 끊기면 RDS 측 화면으로 전환 (시연에서)
3. **시연 영상에서 DB watch 자체를 빼는 것도 옵션** — 페이지 측 (사용자 시각) 정합성 시각화로 대체

### 학습 포인트
- **Failover 의 본질 = 노드 역할 변경** — 그 노드에 의존하는 connection 은 끊어짐을 가정해야 함
- **tmux 의 가치** — SSH 끊겨도 작업 유지. 운영 환경에서 자주 사용
- **시연 영상 = 위험 회피 우선** — 실제 정상 동작이라도 청중에게 어색해 보이면 안 보여주는 게 나음
- **사용자 시각 vs 엔지니어 시각** — DB 테이블보다 페이지가 직관적 (Pre-Sales 톤에 더 적합)

---

## 이슈 #5: Grafana 위젯 "ERROR" 표시

### 증상
- ALB ELB 5XX Count 위젯에 빨간 "ERROR ERROR" 표시
- 실제 메트릭 값 (12.4, 18 등) 정상 받고 있음

### 가설/원인
- Grafana 위젯의 **Value Mappings 설정 오류**
- `Null` 또는 특정 값을 "ERROR" 텍스트로 매핑한 잘못된 설정

### 해결 (시연용 임시)
1. 위젯 Edit 모드 진입
2. 우측 패널 → Value Mappings 섹션
3. 모든 매핑 항목 삭제
4. (선택) Threshold 값 조정 (1 → 100 등)
5. Save dashboard

### 근본 fix (모니터링 팀원 작업)
- Value Mappings 의 Null 처리: "0" 또는 "OK" 텍스트로 매핑
- 또는 Standard options 의 No Value 에서 fallback 텍스트 설정

### 학습 포인트
- **메트릭 값 ≠ 표시 텍스트** — Grafana 의 Value Mappings 가 사이에 들어감
- **"No data" 와 "에러" 는 다른 상태** — 데이터 포인트 없음 ≠ 시스템 문제
- **시연 영상은 시각적 인상이 중요** — 빨간 "ERROR" 는 청중에게 부정적 인상
- **시연 시간대 적합한 Time Range** — Last 6h 보다 Last 5min 이 시연용으로 더 적합

---

## 이슈 #6: 시연 데이터 오염 — PROD-006/007 누적

### 증상
- 시연 시도 누적으로 ID 가 18부터 시작 (정상은 11)
- PROD-006 이 중복으로 들어가있음

### 가설/원인
- DELETE 만 실행하고 AUTO_INCREMENT reset 안 했음 → 다음 INSERT 시 ID 19, 20 식으로 증가
- 시연 중 실수로 같은 코드 두 번 입력

### 해결
- `DELETE FROM ... WHERE product_code IN ('PROD-006', 'PROD-007');` 만으로 행은 정리
- AUTO_INCREMENT reset 은 옵션 (이슈 #2 가설 때문에 신중)

### 학습 포인트
- **시연 환경의 멱등성** — 시연 시작 전 항상 깨끗한 상태로 복원하는 스크립트 필요
- **DELETE vs TRUNCATE vs ALTER** — 각각의 영향 범위 다름
- **운영 DB 에서 AUTO_INCREMENT 조정은 신중** — replication topology 영향 가능성
- **ID 가 1부터 안 시작해도 OK** — 운영 DB 의 자연스러운 흔적 (시연용으로도 무관)

---

## 종합 — Failover/Failback 시연 / 운영 시 체크리스트

### 시연 직전
- [ ] 9 알람 모두 OK
  ```powershell
  aws cloudwatch describe-alarms --query "MetricAlarms[?starts_with(AlarmName, 'project-')].[AlarmName,StateValue]" --output table --region ap-northeast-2
  ```
- [ ] RDS replication Yes/Yes/0
  ```bash
  mysql -h <RDS> -e "SHOW SLAVE STATUS\G" | grep -E "Slave_(IO|SQL)_Running|Seconds_Behind_Master"
  ```
- [ ] 데이터 깨끗한 상태 (5 PROD 행)
- [ ] 시연 중 사용할 SSH 세션 모두 tmux 안에서 운영
- [ ] 녹화 도구 5초 테스트 후 본 녹화
- [ ] 마이크 음소거
- [ ] 마우스 커서 강조 켜기

### 빌드 cleanup 단계 점검 (장기 fix)
- [ ] 모든 빌드 마지막에 replication 상태 확인 + 자동 복구
- [ ] CloudWatch Alarm 으로 NULL lag 감지
- [ ] 빌드 console output 에 cleanup 결과 명시 출력

### 시연 데이터 정리 (시연 후)
- [ ] 추가한 PROD-* 행 삭제
- [ ] AUTO_INCREMENT 는 신중하게 (replication 영향 가설)

### 모니터링 대시보드
- [ ] Value Mappings 의 Null 처리 확인
- [ ] Threshold 값이 시연 시간대에 적합한지 (예: Last 5min vs Last 6h)
- [ ] 시연 중 빨간색이 청중 시선 끌 만한지 점검

---

## 한 줄 요약

> **오늘 시연 영상은 6가지 이슈를 거치며 완성됐고, 가장 큰 issue 는 RDS replication 이 빌드 cleanup 누락으로 반복 STOP 된 것. 발표 후 근본 fix 의 1순위 = Jenkinsfile / Ansible 빌드 cleanup 단계에 START SLAVE 자동 호출 + 검증 추가.**

---

## 인프라 엔지니어로서 배운 것 (Pre-Sales 톤 X, 학습자 톤)

1. **자동화는 cleanup 까지 검증해야 한다** — apply / rollback 양방향 모두
2. **에러 없는 실패** 는 코드의 가장 어려운 디버깅 — 패턴 인식이 중요
3. **시연 영상 = 위험 회피 우선** — 정상 동작이라도 어색하면 안 보여주는 게 나음
4. **사용자 시각 vs 엔지니어 시각** — 보여줄 청중에 따라 시연 흐름 다르게
5. **운영 DB 의 DDL 은 항상 staging 검증 후** — replication 영향 예측 어려움
