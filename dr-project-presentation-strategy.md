# Hybrid DR 프로젝트 — 발표 전략 가이드

> **작성**: 2026-04-27 (Day 7) by Task 5 팀원
> **대상**: 발표 / 시연 영상 준비를 함께할 5인 팀원 전원
> **목적**: 발표 전체 구조 + 시연 영상 시나리오 + 각자의 역할 정리

---

## 📋 목차

1. [이 문서를 읽는 이유](#1-이-문서를-읽는-이유)
2. [프로젝트 시나리오 핵심](#2-프로젝트-시나리오-핵심)
3. [청중이 답을 알고 싶어하는 3가지 질문](#3-청중이-답을-알고-싶어하는-3가지-질문)
4. [시연 영상 시나리오 — 5~7분 4-Act 구조](#4-시연-영상-시나리오)
5. [각 Task 별 시각자료 가이드](#5-각-task-별-시각자료-가이드)
6. [발표 분담 — 5인 Speaker 배정](#6-발표-분담)
7. [슬라이드 작성 시안 — 실제 1장 예시](#7-슬라이드-작성-시안)
8. [각 팀원의 이번 주 To-Do](#8-각-팀원의-이번-주-to-do)
9. [공통 준비 사항 + 의사결정 필요 항목](#9-공통-준비-사항)

---

## 1. 이 문서를 읽는 이유

발표 자료를 만들기 전에 **전체 그림을 공유**하기 위함입니다.
각 Task 담당자는 본인 영역만 알지만, 발표는 **하나의 흐름**이어야 합니다.

이 문서를 읽고 나면:
- ✅ 우리 발표가 어떤 흐름으로 진행될지 이해
- ✅ 본인 슬라이드가 전체에서 어떤 역할인지 명확
- ✅ 시연 영상에서 어떤 화면이 등장할지 사전 인지
- ✅ 본인이 이번 주 안에 준비해야 할 것이 명확

---

## 2. 프로젝트 시나리오 핵심

```
   ┌─────────────────────────────────────────────────────────┐
   │ Phase 1 — Initial Deploy (정상 운영)                    │
   │                                                         │
   │   온프렘 (VMware) ◄── 사용자 트래픽                     │
   │       │                                                 │
   │       ↓ cascade replication                             │
   │   AWS (Pilot Light)                                     │
   │   ── RDS / DB EC2 / Bastion / Jenkins / HAProxy 만 ON   │
   │   ── SpringBoot EC2 는 OFF (비용 절감)                  │
   └─────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Phase 2 — Failover (온프렘 장애 대응)                   │
   │                                                         │
   │   1. 온프렘 down → CloudWatch alarm 발생                │
   │   2. Jenkins 1-Click → Terraform apply                  │
   │   3. SpringBoot EC2 spinup → ALB 트래픽 라우팅 변경     │
   │   4. 사용자 → AWS 측에서 처리됨                         │
   └─────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Phase 3 — Failback (온프렘 복구)                        │
   │                                                         │
   │   1. 온프렘 환경 정상화                                 │
   │   2. Jenkins 1-Click → mysqldump (RDS) → restore        │
   │   3. SpringBoot 재시작 → 트래픽 다시 온프렘으로         │
   └─────────────────────────────────────────────────────────┘
```

**핵심 메시지**: 사람의 개입을 최소화한 **1-Click DR**.

---

## 3. 청중이 답을 알고 싶어하는 3가지 질문

심사관 / 동기 / 면접관 등 청중은 우리 발표를 들으면서 다음 3가지를 확인하고 싶어합니다:

| # | 질문 | 발표가 답하는 슬라이드 |
|---|------|----------------------|
| 1 | **"왜** 이걸 만들었나?" | 도입부 [3-4] (DR 의 비즈니스 가치, Pilot Light 패턴 선택 이유) |
| 2 | **"어떻게** 만들었나?" | 아키텍처 [6-8] + 각 Task 상세 [10-26] |
| 3 | **"정말 동작하나?"** ⭐ | **시연 영상 [27]** + 결과 metric [5, 31] |

> ⚠️ **중요**: 코드는 청중이 자세히 안 봅니다. **"실제로 동작하는 것"** 을 시각적으로 보여주는 게 백 마디 설명보다 강력합니다.

---

## 4. 시연 영상 시나리오

> **분량**: 5~7분 (PPT 중간에 재생)
> **녹화 환경**: Task 5 팀원의 환경 (Phase 1 머신, AWS 인프라)
> **녹화 일정**: 수요일 (Day 9)

### Act 0 — Opening (15초)

- 아키텍처 다이어그램 fade-in
- 자막: "Hybrid DR — Pilot Light Pattern"
- 시나리오 1줄 안내

---

### Act 1 — Phase 1 Initial Deploy (90초)

> **핵심 메시지**: "1-Click 으로 온프렘 + AWS 양쪽 환경이 동시에 셋업되고, 데이터가 cascade 로 흐른다"

| 시간 | 화면 | 의미 / 멘트 키워드 |
|------|------|-------------------|
| 0:00 | Jenkins UI — "Build with Parameters" 클릭 | 1-Click 의 의미 |
| 0:10 | Stage view — 6 stage 가 차례로 녹색 | DSL 자동화 evidence |
| 0:40 | (sped up) build log 흘러가는 모습 | 진행감 |
| 1:00 | Spring Boot UI 접속 — 빈 inventory 페이지 | 배포 완료 |
| 1:10 | UI 에서 PROD-001 데이터 INSERT | 사용자 데이터 입력 |
| 1:20 | **mysql 콘솔 3 분할 화면** — 온프렘 / DB EC2 / RDS 동시에 SELECT → 모두 도달 | **cascade replication 시각적 증거** ⭐ |

---

### Act 2 — Phase 2 Failover (120초) ⭐ 가장 임팩트

> **핵심 메시지**: "사람이 지켜보지 않아도 — 감지 → 알림 → 자동 대응 → DR 환경 운영 까지 자동"

| 시간 | 화면 | 의미 / 멘트 키워드 |
|------|------|-------------------|
| 0:00 | 온프렘 WEBWAS 콘솔 — `systemctl stop logistics-system` | 장애 시뮬레이션 |
| 0:15 | **Grafana dashboard** — Spring Boot procstat 1 → 0 | 모니터링 즉시 감지 |
| 0:30 | CloudWatch Alarm 콘솔 — `webwas_springboot_down` ALARM 상태 | 자동 탐지 |
| 0:45 | 받은 SNS 이메일 캡처 | 알림 도착 |
| 1:00 | Jenkins UI — Phase 2 build 트리거 | 대응 시작 |
| 1:15 | (sped up) Terraform apply — 자원 생성 진행 | IaC 실행 |
| 1:45 | AWS Console — SpringBoot EC2 가 새로 떠있음 | 자원 spinup |
| 2:00 | Spring Boot UI — **상단 빨간 배너 "DR ACTIVE"** 표시 | DR 모드 시각적 신호 |
| 2:15 | UI 에서 새 데이터 DR-001 INSERT | DR 환경에서 정상 동작 |

---

### Act 3 — Phase 3 Failback (90초)

> **핵심 메시지**: "데이터 손실 0 + 자동 복구"

| 시간 | 화면 | 의미 / 멘트 키워드 |
|------|------|-------------------|
| 0:00 | Jenkins UI — Phase 3 build 트리거 | 복구 시작 |
| 0:15 | (sped up) build log — mysqldump 부분 highlight | RDS 데이터 dump |
| 0:30 | Ansible 출력 — db_failback.yml 의 4 단계 | 자동 restore |
| 0:50 | **온프렘 mysql 콘솔** — Phase 2 에서 INSERT 한 DR-001 데이터 검증 | **데이터 정합성** ⭐ |
| 1:10 | Spring Boot UI — DR 배너 사라짐, 정상 페이지 | 복구 완료 |
| 1:25 | 다시 cascade 시각화 (3-tier 모두 같은 데이터) | 시스템 안정 |

---

### Act 4 — Closing (30초)

- 결과 metric 3개 표시:
  - **Failover 소요 시간** (실제 측정값)
  - **Failback 소요 시간**
  - **데이터 손실 0건**
- 아키텍처 다이어그램 다시 등장
- 자막: "온프렘과 클라우드를 잇는 1-Click DR"

---

## 5. 각 Task 별 시각자료 가이드

> **시연 영상에 코드가 잘 안 보이므로**, 각 Task 의 슬라이드에 시각적 증거를 넣어야 합니다.

### Task 1 — AWS Core Infra (Terraform)

| 시각자료 | 사용 슬라이드 |
|---------|-------------|
| Terraform 디렉토리 트리 (modules/ 구조) | [10] |
| VPC + Subnet + Security Group 다이어그램 | [11] |
| `terraform plan` 출력의 "Plan: X to add" 캡처 | [10] |

---

### Task 2 — Packer AMI + Spring Boot

| 시각자료 | 사용 슬라이드 |
|---------|-------------|
| Packer 빌드 로그 캡처 (몇 줄만) | [13] |
| `application-prod.yml` vs `application-dr.yml` 비교 (highlight) | [14-15] |
| Spring Boot UI 스크린샷 (정상 + DR 배너) | [14] |

---

### Task 3 — Data Sync (Cascade Replication)

| 시각자료 | 사용 슬라이드 |
|---------|-------------|
| **Cascade 3-tier 다이어그램** ⭐ | [16] |
| `SHOW SLAVE STATUS` 출력 (3 노드 분할 화면) | [17] |
| `/api/system/db-status` endpoint 화면 | [18] |

---

### Task 4 — Failover & Monitoring

| 시각자료 | 사용 슬라이드 |
|---------|-------------|
| **CloudWatch Dashboard** 캡처 ⭐ | [20] |
| **Grafana Dashboard** 캡처 ⭐ | [20] |
| 알람 분류표 (온프렘 / 트래픽 / DB) | [20] |
| SNS 이메일 도착 캡처 | [20] |
| IaC 재현성 검증 결과 (별도 환경 dashboard) | [21] |

---

### Task 5 — Jenkins + Ansible + Onprem (Task 5 팀원)

| 시각자료 | 사용 슬라이드 |
|---------|-------------|
| Jenkinsfile snippet (3-phase 구조 visible) | [22] |
| Stage view 스크린샷 | [22] |
| Ansible site.yml 의 role 구조 | [23] |
| **HAProxy-only Tailscale 다이어그램** ⭐ (차별화 포인트) | [24] |
| VMware 6대 토폴로지 | [25] |
| Onprem ↔ Cloud 통신 흐름 종합 | [26] |

---

## 6. 발표 분담

> 32 슬라이드를 5명이 나눕니다. 발표 시간 25-30분 가정.

### 추천 분담안

| 발표자 | 분량 | 담당 슬라이드 | 발표 시간 |
|-------|------|--------------|----------|
| **Speaker 1** (Task 1) | 도입 + AWS 인프라 | [1-3, 10-12] | 4-5분 |
| **Speaker 2** (Task 2 / PPT 담당) | 결과 요약 + 작업 분담 + Spring Boot | [4-5, 9, 13-15] | 4-5분 |
| **Speaker 3** (Task 3) | 아키텍처 + Cascade Replication | [6-7, 16-18] | 4-5분 |
| **Speaker 4** (Task 4) | Monitoring + 시연 영상 도입 | [19-21, 27 도입 멘트] | 3-4분 |
| **Speaker 5** (Task 5) | Tailscale + Task 5 + 트러블슈팅 + 시연 영상 narration + 마무리 | [8, 22-26, 28-32] | 8-10분 |

> Speaker 5 분량이 큽니다. 본인 영역 (Task 5) + 트러블슈팅 (4시간 디버깅 사례) + 시연 영상 narration 까지 본인이 직접 한 일이라 자연스러움.

### 부담 줄이는 옵션

Speaker 5 부담이 너무 크면:
- 트러블슈팅 [28-30] 의 각 사례를 **owner 가 30초씩 분담**
- 마무리 [31-32] 는 **Speaker 1 또는 2** 가
- Speaker 5 분량 → 6-8분으로 감소

---

## 7. 슬라이드 작성 시안

### 시안 — 슬라이드 [24] HAProxy-only Tailscale Architecture

**슬라이드 layout 예시**:

```
┌────────────────────────────────────────────────────────────┐
│ [24] HAProxy-only Tailscale Architecture                  │
│                                                            │
│   [좌측: 일반적 접근]              [우측: 우리 결정]      │
│                                                            │
│   ┌─[VMware 4대]──┐               ┌─[VMware 4대]──┐       │
│   │ HAProxy ★ TS │               │ HAProxy ★ TS │ ← SR  │
│   │ WebWAS  ★ TS │               │ WebWAS        │       │
│   │ DB      ★ TS │               │ DB            │       │
│   │ MGMT    ★ TS │               │ MGMT          │       │
│   └───────────────┘               └───────────────┘       │
│   모든 VM 에 Tailscale            HAProxy 만 + subnet      │
│                                   routing                  │
│                                                            │
│   ★ Tailscale node 4개            ★ node 1개 → 75% 절감   │
│   IP 대역 직접 노출               단일 entry point         │
│                                                            │
│   📌 Trade-off: SNAT 으로 source IP 변환 → mysql           │
│      `_gateway` 인증 실패 → 트러블슈팅 [29] 에서 해결     │
│                                                            │
│   📌 Architectural maturity:                              │
│      운영 단순성 vs 네트워크 투명성 의 의식적 선택        │
└────────────────────────────────────────────────────────────┘
```

**발표 멘트 예시 (30-40초)**:

> "Tailscale 로 hybrid 환경을 연결할 때 가장 흔한 접근은 **모든 VM 에 Tailscale 클라이언트를 설치**하는 것입니다.
>
> 저희도 처음엔 그렇게 시도했는데, 운영 복잡도가 빠르게 늘어나는 걸 발견했습니다. 그래서 **HAProxy 한 대만 Tailscale node 로 두고, subnet router 기능으로 나머지 VM 의 사설 IP 대역을 광고**하는 구조로 단순화했습니다.
>
> 결과: 관리 표면이 75% 줄었고, 단일 entry point 라는 보안적 장점도 생겼습니다.
>
> 다만 SNAT 으로 인한 부작용이 있었는데, 그건 잠시 후 트러블슈팅 슬라이드에서 자세히 설명드리겠습니다."

> 💡 **이 패턴**: (1) 비교 다이어그램 (2) 트레이드오프 명시 (3) 후속 슬라이드 연결 — 가장 효과적입니다.

---

## 8. 각 팀원의 이번 주 To-Do

### Task 1 팀원

- [ ] 슬라이드 [10-12] 본문 작성
- [ ] Terraform 디렉토리 트리 시각자료 캡처
- [ ] VPC 다이어그램 작성 (draw.io / excalidraw)
- [ ] 도입부 [1-3] 협업 (메인 발표 슬라이드 톤 잡기)

### Task 2 팀원 (PPT 담당)

- [ ] 슬라이드 [13-15] 본문 작성
- [ ] [4-5, 9] 협업 슬라이드 작성
- [ ] Packer 빌드 로그 / Spring Boot UI 캡처

### Task 3 팀원

- [ ] 슬라이드 [16-18] 본문 작성
- [ ] **Cascade 3-tier 다이어그램** 작성 (가장 중요)
- [ ] `SHOW SLAVE STATUS` 출력 캡처 (3 노드 분할)
- [ ] `/api/system/db-status` endpoint 화면 캡처
- [ ] [6-7] 아키텍처 슬라이드 협업

### Task 4 팀원

- [ ] **별도 가이드 문서 (`dr-project-task4-monitoring-presentation-guide.md`)** 따라 진행
- [ ] 슬라이드 [19-21] 본문 작성
- [ ] CloudWatch / Grafana dashboard 캡처
- [ ] IaC 재현성 검증 결과 정리
- [ ] 시연 영상 [27] 도입 멘트 (15-20초) 준비

### Task 5 팀원

- [ ] 슬라이드 [8, 22-26] 본문 작성
- [ ] 트러블슈팅 [28-30] narrative 작성 (`!includedir`, `_gateway` SNAT, GTID alignment)
- [ ] HAProxy-only Tailscale 다이어그램 작성
- [ ] **수요일 시연 영상 녹화 + narration**
- [ ] 마무리 [31-32] 작성

---

## 9. 공통 준비 사항


### 9-1. 자주 받을 질문 — 모두가 알아야 할 답변

발표 중 어느 슬라이드에서든 받을 수 있는 공통 질문:

**Q1. "왜 Pilot Light 패턴이에요? Multi-Site 가 더 안전하지 않나요?"**
→ 비용 vs RTO trade-off. Multi-Site 는 24시간 onprem + AWS 풀 운영 → 비용 약 X 배. Pilot Light 는 핵심만 항상 ON → 비용 ↓ + RTO 만 약간 증가.

**Q2. "데이터 정합성은 어떻게 보장하나요?"**
→ Cascade replication (GTID 기반) + Phase 3 의 mysqldump → restore 검증. 시연 영상에서 같은 데이터가 3 tier 모두에 도달하는 모습 확인 가능.

**Q3. "RTO / RPO 구체적인 측정값은요?"**
→ (실제 측정값 정리 필요. 시연 영상 녹화 시 시간 측정해서 명시.)

**Q4. "AI 도구 (ChatGPT / Claude) 를 사용하셨나요?"**
→ "네, Claude AI Code 를 디버깅 / 문서 작성에 활용했습니다. 다만 모든 결정은 직접 검증했고, 트러블슈팅 narrative 처럼 실제 인사이트는 우리가 직접 디버깅한 결과입니다." (솔직 공개 + 검증 강조)

### 9-2. 발표 리허설

- [ ] 일단 PPT 완료하고 다시 논의
- [ ] 각자 본인 슬라이드 **2번 이상 혼자 연습**
- [ ] 시연 영상 **녹화 전 화면 흐름 1번 dry-run**

---

## 📎 부록 — 참고 파일

| 파일 | 내용 |
|------|------|
| `dr-project-presentation-outline-v1.md` | 32 슬라이드 목차 + 슬라이드별 owner |
| `dr-project-task4-monitoring-presentation-guide.md` | Task 4 팀원용 scaffolding 가이드 |
| `dr-project-cascade-replication-manual.md` | Cascade replication 기술 매뉴얼 (cross-team 참고) |
| `dr-project-cheat-sheet-daily-startup.md` | 매일 환경 켜는 방법 |
| `dr-project-review-2026-04-26-day-summary.md` | Day 6 트러블슈팅 narrative source |

---

## 변경 이력

- v1 (2026-04-27): 초안 작성 by 최필재
