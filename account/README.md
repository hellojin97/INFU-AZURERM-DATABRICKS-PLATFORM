# account

Databricks account 레벨 root 모듈. 독립 state 단위다.

**환경별로 나누지 않는다.** Databricks account는 Azure 테넌트당 하나이고, Unity Catalog metastore는 리전당 하나만 존재할 수 있다. `envs/dev/account/`, `envs/stg/account/`로 나누면 같은 계정을 세 번 가리키게 되고, 같은 리전에 metastore를 두 번 만들려다 실패한다.

환경 분리는 이 metastore 안의 카탈로그로 한다.

```
metastore (canadacentral)
├── catalog: infu_dev
├── catalog: infu_stg
└── catalog: infu_prd
```

카탈로그는 `envs/<env>/workspace/` 계층이 만든다.

## 소유하는 것

| 리소스 | 이름 |
|---|---|
| `databricks_metastore` | `infu-uc-metastore-cac` |
| `databricks_group` | `infu-<env>-uc-admins` (환경마다 하나) |

metastore 이름은 계정 전체에서 유일해야 한다. 이 테넌트는 여러 사람이 공유하고 있어 짧은 이름은 충돌 위험이 있다. 접두사 규칙이 그것을 막는다.

metastore에는 리전 약어를 붙이고 그룹에는 붙이지 않는다. metastore는 리전 단위 리소스라 다른 리전에 또 만들면 이름이 구분되어야 하지만, account 그룹은 계정 전역 식별자라 리전에 속하지 않고 여러 리전의 metastore에 동시에 권한을 가질 수 있다.

## 의도적으로 지정하지 않은 인자

| 인자 | 이유 |
|---|---|
| `storage_root` | 카탈로그마다 스토리지를 따로 둔다. Databricks 권장 방식 |
| `force_destroy` | 기본값 `false` 유지. 카탈로그가 있으면 `destroy`가 실패해 리전 유일 리소스를 보호한다 |
| `owner` | CI Service Principal이 속하지 않은 그룹을 소유자로 두면 이후 SP가 metastore를 수정하지 못할 수 있다. grant 구조가 잡힌 뒤 다시 다룬다 |

## 파일

| 파일 | 역할 |
|---|---|
| `versions.tf` | Terraform·provider 버전 고정, backend 선언 |
| `providers.tf` | `databricks` provider, `alias = "account"` |
| `variables.tf` | 입력 변수 선언 |
| `terraform.tfvars` | 환경 값. secret 없음 |
| `backend.hcl` | backend 부분 설정. `init -backend-config`로 주입 |
| `main.tf` | 리소스 |
| `outputs.tf` | 다른 계층이 remote state로 읽는 출력 |
| `.terraform.lock.hcl` | provider 체크섬. `linux_amd64` + `darwin_arm64` |

## 값 주입 경로

| 값 | 경로 |
|---|---|
| `databricks_account_id` `azure_client_id` `azure_tenant_id` | `TF_VAR_` 환경 변수. 저장소가 public이라 파일에 두지 않는다 |
| `prefix` `location` `location_abbreviation` `environments` | `terraform.tfvars` |
| backend 신원 | `ARM_CLIENT_ID` `ARM_TENANT_ID` `ARM_SUBSCRIPTION_ID` |

실제 값은 GitHub repository variable에 있다.

## 인증

provider는 `auth_type = "azure-cli"`를 쓴다. 워크플로의 `azure/login@v2`가 OIDC 교환을 처리하고 남긴 `az` CLI 세션을 이어 쓴다.

provider가 직접 OIDC를 다루는 `github-oidc-azure`는 audience를 `api://AzureADTokenExchange`로 지정하지 않아 실패했다.

backend는 `use_oidc = true`와 `use_azuread_auth = true`를 쓴다. 후자는 state Storage Account의 공유 키 액세스를 껐기 때문에 필요하다.

**로컬에서는 인증되지 않는다.** Actions 런타임에만 있는 환경 변수를 읽는다.

## state

```
컨테이너   tfstate
key        account.tfstate
```

환경 접두사를 붙이지 않는다. 계정이 하나이므로 state도 하나다.

## 로컬에서 할 수 있는 것

```bash
terraform fmt -recursive
terraform init -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
terraform validate
```

`init -backend=false`는 state에 접근하지 않으므로 Azure 자격 증명이 필요 없다. `apply`는 파이프라인에서만 실행한다.

provider 목록이 바뀌면 `providers lock`을 다시 실행하고 결과를 커밋한다. macOS에서만 생성한 lock 파일은 Linux 러너에서 체크섬 불일치로 실패한다.

## 다음에 들어올 것

account service principal과 entitlement는 `envs/<env>/workspace/`의 grant가 생긴 뒤에 추가한다. 소비처가 없는 계정 레벨 식별자를 공유 테넌트에 미리 만들어 두지 않는다.

`databricks_metastore_assignment`은 여기 두지 않는다. account 레벨 리소스이지만 workspace ID를 필요로 하므로 `envs/<env>/platform/`에 둔다.
