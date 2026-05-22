# 2026-05-05 작업 요약 + 내일 (5/6) 이어서 할 일

> **이 문서 목적**: 5/5 저녁 마무리. 내일 5/6 새 세션에서 AI 가 5분 만에 컨텍스트 따라잡고 destroy 부터 진행하도록 하는 handoff.
>
> **5/6 세션 시작 입력 권장** (그대로 복붙):
> ```
> 안녕하세요. 어제 5/5 저녁에 마무리하고 왔습니다.
> @dr-project-2026-05-05-day-summary.md 읽고 AWS destroy 부터 시작해요.
> ```

---

## 0. 내일 (5/6) 세션 시작 시 — AI 가 먼저 할 일

1. **이 파일 통째로 읽기** — 오늘 한 일 + 내일 큐
2. **MEMORY.md 자동 로드 확인** — 사용자 preference (jargon 회피, 브랜드색 #546FE7, 자연스러운 톤)
3. **참고 파일 위치**:
   - **발표 대본**: `dr-project-presentation-script-final.md` (오늘 신규)
   - **트러블슈팅 학습**: `dr-project-2026-05-05-troubleshooting-learnings.md` (오늘 신규)
   - **시연 스크립트**: `dr-project-2026-05-05-demo-recording-script.md` (오늘 작성, 녹화 끝나서 reference 만)
   - **디자인 핸드오프**: `dr-project-ppt-design-handoff-2026-05-04.md`
   - **발표 멘트 + Q&A**: `dr-project-presentation-talking-points.md` (어제까지의 광범위 자료)
   - **PPT 파일**: `C:\Users\cpj32\Downloads\PPT\260430_ppt.pptx`
   - **시연 영상**: 백업 끝남 (외부 저장)
4. **Terraform 작업 디렉토리**: `c:\Users\cpj32\Desktop\프로젝트\Git\project-springboot\` (또는 `-dev/` — 사용자 확인 필요)

→ 컨텍스트 회복 후 **destroy 진행** (정오쯤)

---

## 1. 오늘 (5/5) 한 일 — 순서대로

### A. 시연 영상 녹화 (대장정) ⭐
- 셋업 점검 (9 알람 OK / DB watch / Grafana fix)
- 1차 녹화 시도 → Phase 2 빌드 실패 (RDS replication STOP)
- 복구 → 2차 녹화 → OBS 화면 짤림 발견
- OBS 설정 fix → 재녹화 → 6분 영상 완성 ✅
- 영상 외부 백업 완료

### B. RDS replication 트러블슈팅
- 오늘 같은 패턴으로 **3번 STOP**
- 매번 `CALL mysql.rds_start_replication;` 으로 복구
- 가설: Failover/Failback 빌드 cleanup 단계의 START SLAVE 누락
- 발표 후 근본 fix 작업 필요

### C. Grafana 위젯 fix (시연용 임시)
- ALB 5XX Count 위젯의 Value Mappings ("ERROR" 잘못된 매핑) 제거
- Threshold 값 조정
- 모니터링 팀원에게 사전 공지 작성 (사용자가 직접 발송 예정)

### D. RTO 실측값 확보
- 시나리오 2 (Failover): **3분 51초**
- 시나리오 3 (Failback): **4분 32초**

### E. PowerPoint [34] Speaker Note 갱신 ⭐
- RTO 실측값 추가
- Failback 계획 다운타임 멘트 추가
- "1-Click 정의 = 자동 감지 + 인간 결정 + 자동 실행" 본인 직접 보강
- split-brain 차단 framing 추가

### F. 신규 학습 자료 3개 작성 (이 세션 마지막)
- `dr-project-presentation-script-final.md` — 발표 대본 최종 학습용
- `dr-project-2026-05-05-troubleshooting-learnings.md` — 오늘 6가지 이슈 학습 자료
- `dr-project-2026-05-05-day-summary.md` — 이 파일

### G. AWS 리소스 destroy 결정
- 오늘 stop 안 함 (모니터링 팀원 캡쳐 시간 확보 위해)
- **내일 5/6 정오 destroy 예정**

---

## 2. 슬라이드별 상태 (변경 없음 — 어제 모두 완료)

| # | 제목 | 상태 |
|---|------|-----|
| 7 | Tailscale Network Topology (챕터 01) | ✅ 어제 완료 |
| 32 | 06 챕터 표지 | ✅ 그대로 |
| 33 | Tailscale BEFORE/AFTER | ✅ 어제 완료 |
| **34** | 한 번의 코드, 세 가지 시나리오 | ✅ **오늘 Speaker Note 갱신** |
| 35 | Jenkinsfile 코드 | ✅ 어제 완료 |
| 36 | Ansible 멱등성 | ✅ 어제 완료 |
| 37 | Terraform 활용 framing | ✅ 어제 완료 |
| 38 | 트러블슈팅 3-column | ✅ 어제 완료 |
| 39 | Closing — Production Readiness | ✅ 어제 완료 |

→ **본인 파트 슬라이드 모두 완성 + [34] Speaker Note 보강 완료**

---

## 3. 수정/생성된 파일 목록 (5/5)

| 파일 | 상태 | 변경 |
|------|------|------|
| **`dr-project-2026-05-05-demo-recording-script.md`** | 🆕 신규 (시연 직전 작성) | 노트앱 복붙용 시연 스크립트 |
| **`dr-project-presentation-script-final.md`** | 🆕 신규 ⭐ | 발표 직전 학습용 최종 대본 |
| **`dr-project-2026-05-05-troubleshooting-learnings.md`** | 🆕 신규 ⭐ | 오늘 6가지 이슈 학습 자료 |
| **`dr-project-2026-05-05-day-summary.md`** | 🆕 신규 | 이 파일 |
| **PowerPoint 파일** (`260430_ppt.pptx`) | 본인 직접 | 슬라이드 [34] Speaker Note 갱신 (RTO + Failback + 1-Click 정의) |
| **시연 영상 (mp4)** | 🆕 신규 ⭐⭐ | 6분 녹화 + 외부 백업 |
| **Grafana 대시보드** | 임시 수정 | ALB 5XX Count 위젯 Value Mappings 제거 + Threshold 조정 |

---

## 4. 내일 (5/6) 할 일 큐 (우선순위 순)

### #1 ⭐ AWS 리소스 destroy (정오쯤)

#### Destroy 전 마지막 체크
- [ ] **Git 마지막 push**:
  ```powershell
  git status
  git add .
  git commit -m "5/5 시연 영상 + [34] Speaker Note 갱신 + 발표 대본/학습 자료"
  git push
  ```
- [ ] **시연 영상 백업 한 번 더 확인** (외부 저장 + 로컬)
- [ ] **Terraform 작업 디렉토리 확인**:
  ```powershell
  cd c:\Users\cpj32\Desktop\프로젝트\Git\project-springboot
  terraform workspace show
  terraform state list
  ```
- [ ] **tfstate backend 확인** (S3 면 자동 백업)

#### Destroy 실행
```powershell
cd c:\Users\cpj32\Desktop\프로젝트\Git\project-springboot   # 또는 -dev/
terraform destroy
# Plan 출력 확인 → "yes" 입력
```

→ 5-15분 소요

#### Destroy 후 잔존 리소스 점검
```powershell
# EBS
aws ec2 describe-volumes --filters "Name=status,Values=available" --output table --region ap-northeast-2
# RDS auto snapshots
aws rds describe-db-snapshots --snapshot-type automated --output table --region ap-northeast-2
# Elastic IPs
aws ec2 describe-addresses --query "Addresses[?AssociationId==null]" --output table --region ap-northeast-2
# S3 buckets (Terraform state bucket 빼고)
aws s3 ls
```

→ 잔존 있으면 콘솔/CLI 수동 삭제 (단, **Terraform state bucket 은 삭제 X**)

#### 비용 확인
- 빌링 대시보드 → 다음날 (5/7) 비용이 0 또는 거의 0 떨어지는지

### #2 디자인 팀원에게 PPT + handoff doc 전달
- 파일: `260430_ppt.pptx` + `dr-project-ppt-design-handoff-2026-05-04.md`
- 채널: Slack / 카톡 / Git push 등 (본인 일정)

### #3 Task 4 모니터링 핸드오프 doc 팀원 전달
- 파일: `dr-project-task4-monitoring-handoff-2026-05-01.md` (5/1 작성, 미전달)
- 모니터링 담당 팀원에게 직접

### #4 모니터링 팀원 destroy 공지 답변 처리
- 어제 보낸 공지에 팀원 답변 받아서 처리
- destroy 전에 캡쳐 자료 받았는지 확인

### #5 (선택) 발표 예행연습
- `dr-project-presentation-script-final.md` 정독
- 거울 보고 본인 파트 8장 한 번 발표
- 시간 측정 (목표: 6-7분)
- 거울 보고 *"건방진 톤"* 안 나오는지 자가 점검

### #6 (선택) talking-points §11 [39] Closing 섹션 추가
- 5/4 부터 미작성 상태
- 발표 예행연습 시 [39] 만의 톤 / Q&A / 마무리 멘트 정리

### #7 5/6 day-summary 작성 (필요 시)

---

## 5. 절대 잊으면 안 되는 사용자 preference

> 자동 로드되는 메모리지만 강조:

- **단순 한국어, jargon 회피** — 슬라이드 + Speaker Note 모두. *"PoC"*, *"Production"*, *"deploy"*, *"자산화"*, *"표준 협업 패턴"* 금지
- **단언 회피** — *"AI 시대 엔지니어의"* / *"~ 이게 답이다"* / *"여기서 배운 건..."* (강제 lesson box) 회피. 본인은 졸업생 톤 유지
- **자연스러운 narrative** — 트러블 슈팅 사례는 stories 로 풀고 인위적 lesson 박지 않기
- **WHY/HOW 설명** — 코드만 던지지 말고 개념 풀어서
- **명령어 형식** — PowerShell vs SSH 세션 + 작업 디렉토리 명시
- **브랜드 색상 #546FE7 (RGB 84, 111, 231)** — 다이어그램 + 슬라이드 박스에 align
- **Pre-Sales 톤은 implicit, not explicit** — 본인이 어떻게 일했는지 보여주는 것 (경험 공유), 보편 진리 단언 X
- **Phase → 시나리오 통일** — 본인 슬라이드 위 텍스트 + 다이어그램 모두

---

## 6. 본인 파트 발표 멘트 / Q&A 참고

내일 발표 예행연습 시 정독 권장:

- **`dr-project-presentation-script-final.md`** ⭐ — 오늘 작성한 최종 학습용 대본
  - §0: 발표 흐름 한눈에 (8장)
  - §1: 톤 원칙 — 발표 직전 마지막 점검
  - §2: 슬라이드별 발표 멘트
  - §3: Q&A 예상 5종 + Failback 톤
  - §4: 데이터 정합성 (Q&A 보완)
  - §5: 발표 직전 30초 체크
- `dr-project-presentation-talking-points.md` — 광범위 reference (어제까지)
- `dr-project-2026-05-05-troubleshooting-learnings.md` — 오늘 트러블슈팅 학습

---

## 7. 한 줄 요약

> **5/5 = 시연 영상 녹화 (대장정 끝에 6분 영상 완성) + RDS replication STOP 3번 트러블슈팅 + [34] Speaker Note RTO/Failback 갱신 + 발표 대본 / 트러블슈팅 학습 자료 / day-summary 신규 3개. 5/6 = AWS destroy (정오) + 디자인 팀원 전달 + Task 4 모니터링 doc 전달 + 발표 예행연습.**

---

오늘 정말 수고 많으셨습니다. 시연 영상까지 가는 길이 험난했지만, 잘 끝냈습니다 🎬
내일은 destroy 부터 차분하게.
