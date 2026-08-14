# INFU-AZURERM-DATABRICKS-PLATFORM

Azure 위 Databricks **플랫폼 계층**을 Terraform으로 프로비저닝하는 IaC 저장소.

DAB(Databricks Asset Bundles)로는 만들 수 없는 것 — Account, Workspace, Unity Catalog metastore, Service Principal, Storage Credential — 만 여기서 관리한다.

## 무엇을 관리하나

| | Terraform (이 저장소) | DAB (별도 저장소) |
|---|---|---|
| Azure | Resource Group, VNet/Subnet, NSG, ADLS Gen2, Key Vault, Private Endpoint | — |
| Databricks Account | metastore, account group/user/service principal, entitlement | — |
| Workspace | workspace 생성, storage credential, external location, catalog/schema 골격, grant, cluster policy | — |
| 워크로드 | — | job, pipeline(DLT), notebook, app, MLflow |

한 줄 기준: **Terraform은 정책과 권한, DAB는 워크로드.**

## 구조

```
modules/               재사용 모듈 (provider 블록 없음)
account/               Account 레벨   — metastore, group, SP  (계정 전역)
envs/<env>/platform/   Azure 인프라   — 네트워크, 스토리지, workspace 생성
envs/<env>/workspace/  Workspace 내부 — 거버넌스, 권한
```

- `account/`는 환경별로 나누지 않는다. Databricks account는 테넌트당 하나, metastore는 리전당 하나다. 환경 분리는 metastore 안의 카탈로그로 한다
- `<env>` = `dev` / `prd`. 환경 분리는 디렉터리 방식 (`terraform workspace` 미사용)
- 각 디렉터리가 독립 root 모듈이자 독립 state 단위
- 실행 순서: `account` → `platform` → `workspace`

## 실행

**CI/CD 전용 저장소다. 로컬 apply는 하지 않는다.**

- PR: `fmt -check` → `validate` → `plan` (결과를 PR 코멘트로)
- merge: apply job이 같은 실행에서 `plan`을 새로 만들고 그 `tfplan`에만 `apply`
- `dev`는 자동, `prd`는 GitHub Environment 승인 게이트

로컬에서는 `terraform fmt`, `terraform validate`까지만 돌린다.

## 요구 사항

- Terraform 1.15.x
- CI Service Principal: Azure 구독 Contributor + Databricks Account Admin
- 인증은 GitHub Actions OIDC federated credential. client secret / PAT 미사용
- State backend: `azurerm` (Storage Account + container), 환경·계층별 key 분리

---

작업 규약은 [CLAUDE.md](CLAUDE.md) 참고.
