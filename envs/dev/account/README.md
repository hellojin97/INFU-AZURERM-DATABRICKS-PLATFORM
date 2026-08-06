# dev / account

Databricks account 레벨 root 모듈. 독립 state 단위다.

이 계층은 Azure 리소스를 만들지 않는다. workspace 바깥, 계정 전체에 걸리는 것만 다룬다.

## 현재 상태 — 1단계 (배관 검증)

리소스를 만들지 않는다. GitHub OIDC 인증과 state backend 접근이 실제로 되는지만 확인한다.

`main.tf`에 읽기 전용 data source 하나만 둔다. Terraform은 아무도 참조하지 않는 provider를 초기화하지 않으므로, 리소스가 0개면 인증 자체가 시도되지 않기 때문이다.

**통과 기준** — PR에 plan 코멘트가 붙고 "No changes"로 끝난다. merge 후 apply가 `metastore_ids = {}`를 출력한다. Canada Central에 metastore가 아직 없으므로 빈 map이 정상이다.

## 파일

| 파일 | 역할 |
|---|---|
| `versions.tf` | Terraform·provider 버전 고정, backend 선언 |
| `providers.tf` | `databricks` provider, `alias = "account"` |
| `variables.tf` | 입력 변수 선언 |
| `terraform.tfvars` | 환경 값. secret 없음 |
| `backend.hcl` | backend 부분 설정. `init -backend-config`로 주입 |
| `main.tf` | 리소스 및 data source |
| `outputs.tf` | 다른 계층과 검증에 쓰이는 출력 |
| `.terraform.lock.hcl` | provider 체크섬. `linux_amd64` + `darwin_arm64` |

## 값 주입 경로

| 값 | 경로 | 이유 |
|---|---|---|
| `databricks_account_id` | `TF_VAR_` 환경 변수 | 저장소가 public이라 파일에 두지 않는다 |
| `azure_client_id` | `TF_VAR_` 환경 변수 | 동일 |
| `azure_tenant_id` | `TF_VAR_` 환경 변수 | 동일 |
| `env` `prefix` `location` `owner` | `terraform.tfvars` | 비민감 값 |
| backend 신원 | `ARM_CLIENT_ID` `ARM_TENANT_ID` `ARM_SUBSCRIPTION_ID` | 워크플로가 주입 |

`TF_VAR_*`와 `ARM_*`의 실제 값은 GitHub repository variable에 있다.

## 인증

provider는 `auth_type = "github-oidc-azure"`, backend는 `use_oidc = true`를 쓴다. 둘 다 GitHub Actions 런타임이 발급하는 OIDC 토큰을 Entra ID 토큰으로 교환한다. client secret과 PAT는 존재하지 않는다.

**로컬에서는 인증되지 않는다.** Actions 런타임에만 있는 환경 변수를 읽기 때문이다.

backend에 `use_azuread_auth = true`가 필요하다. state Storage Account의 공유 키 액세스를 껐기 때문이다.

## state

```
컨테이너   tfstate
key        dev/account.tfstate
```

`key`가 겹치면 다른 계층이 같은 state를 덮어쓴다. 환경·계층마다 달라야 한다.

## 로컬에서 할 수 있는 것

```bash
terraform fmt -recursive
terraform init -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
terraform validate
```

`init -backend=false`는 state에 접근하지 않으므로 Azure 자격 증명이 필요 없다. `apply`는 파이프라인에서만 실행한다.

provider 목록이 바뀌면 `providers lock`을 다시 실행하고 결과를 커밋한다. macOS에서만 생성한 lock 파일은 Linux 러너에서 체크섬 불일치로 실패한다.

## 다음 단계에 추가될 것

2단계에서 이 디렉터리에 실제 리소스가 들어온다.

- Unity Catalog metastore (Canada Central). `storage_root` 없이 `region`만 지정한다. 카탈로그별 스토리지를 쓰는 방식이라 이 계층이 Azure 인프라에 의존하지 않고 `account → platform` 순서가 유지된다
- account group, account service principal, entitlement

metastore assignment은 여기 두지 않는다. account 레벨 리소스이지만 workspace ID를 필요로 하므로 `platform` 계층에 둔다.
