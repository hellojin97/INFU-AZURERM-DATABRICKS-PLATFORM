# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Azure 위 Databricks 플랫폼을 Terraform으로 프로비저닝하는 IaC 저장소. Account / Workspace 생성, Unity Catalog metastore, Service Principal, Credential 등 **DAB(Databricks Asset Bundles)로는 다룰 수 없는 플랫폼 계층**만 관리한다.

이 저장소는 **CI/CD 전용**이다. 모든 `init`/`plan`/`apply`는 파이프라인에서 실행되며, 로컬 apply는 하지 않는다.

현재 저장소는 비어 있다. 아래는 관찰된 구조가 아니라 앞으로 코드를 추가할 때 지켜야 할 규약이다.

## 소유권 경계 (가장 중요)

Terraform이 소유:

- Azure 리소스: Resource Group, VNet/Subnet(VNet injection), NSG, Storage Account(ADLS Gen2), Key Vault, Private Endpoint
- `azurerm_databricks_workspace`, Access Connector / Managed Identity
- Account 레벨: metastore, metastore assignment, account group/user/service principal, entitlement. 단 group **membership**(사람 배치)은 온보딩·오프보딩 운영 작업이라 Terraform 밖에서 수동 관리한다
- Workspace 레벨 거버넌스: storage credential, external location, catalog/schema 골격, permission/grant, cluster policy, instance pool, secret scope(백엔드 정의)

DAB가 소유 (Terraform으로 만들지 말 것):

- job, pipeline(DLT), notebook 및 코드 아티팩트, app, MLflow experiment, 워크로드 단위 cluster

경계가 겹치면 Terraform은 "정책과 권한", DAB는 "워크로드"를 갖는다. 새 리소스를 추가하기 전에 이 기준으로 판단하고, 애매하면 사용자에게 확인한다.

## Provider 구성 규약

`databricks` provider는 반드시 계층별로 분리하고 alias를 붙인다. 하나의 provider 블록으로 account와 workspace를 함께 다루지 않는다.

- account 레벨: `alias = "account"`, `host = "https://accounts.azuredatabricks.net"`, `account_id` 지정
- workspace 레벨: workspace마다 alias 하나, `host`는 해당 workspace URL(`azurerm_databricks_workspace` 출력)
- 인증은 GitHub Actions OIDC federated credential 기반 Service Principal 하나로 통일한다. client secret, PAT, provider 블록 내 리터럴 자격 증명은 쓰지 않는다
- workspace를 만드는 코드와 그 workspace 내부를 설정하는 코드는 서로 다른 apply 단위에 둔다. 같은 apply에서 provider의 `host`를 아직 생성되지 않은 값으로 채우면 실패한다

## 디렉터리 및 환경 분리

```
modules/               재사용 모듈. 환경/이름 하드코딩 금지, provider 블록 금지
account/               계정 전역. metastore, account group/SP, entitlement
envs/<env>/platform/   Azure 인프라 + workspace 생성
envs/<env>/workspace/  workspace 내부 거버넌스
```

- `account/`는 환경별로 나누지 않는다. Databricks account는 테넌트당 하나이고 metastore는 리전당 하나이기 때문이다. 환경 분리는 metastore 안의 카탈로그로 한다
- 환경(`dev`/`prd`) 분리는 **디렉터리 방식**을 쓴다. `terraform workspace`는 쓰지 않는다
- 각 root 모듈 디렉터리가 독립 state 단위다
- 모듈은 `required_providers`만 선언하고 provider 설정은 root에서 주입한다
- 계층 간 참조는 `terraform_remote_state` 또는 data source로 하고, 값을 복사해 붙여넣지 않는다

## State / 명명 / 버전

- State backend는 `azurerm` (Storage Account + container). 환경·계층별로 `key`를 분리하고 로컬 state는 커밋하지 않는다
- 리소스 이름: `<prefix>-<env>-<workload>-<type>` (예: `infu-dev-databricks-ws`). Databricks group/SP 이름도 같은 규칙을 따른다
- 모든 Azure 리소스에 `env`, `owner`, `managed_by = "terraform"` 태그를 붙인다
- State backend는 공유 키를 쓰지 않는다. `use_azuread_auth = true`로 Entra ID 인증한다
- 버전 고정: Terraform `>= 1.15`, provider는 `~>`로 pin, `.terraform.lock.hcl` 커밋
- Terraform 버전은 워크플로에서 명시 고정하고, 로컬 버전과 일치시킨다 (현재 로컬 기준 1.15.6)
- lock 파일은 로컬에서 생성한다. state를 건드리지 않고 Azure 자격 증명도 필요 없다. macOS에서만 생성하면 Linux 러너에서 체크섬 불일치로 실패하므로 두 플랫폼을 함께 넣는다

```bash
terraform init -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

## CI/CD 실행 규약

파이프라인은 GitHub Actions. 워크플로는 root 모듈 디렉터리를 working directory로 잡고, `account` → 환경별 `platform` → `workspace` 순서로 실행한다.

```
PR      : fmt -check -recursive → validate → plan -out=tfplan  (plan 결과를 PR 코멘트로)
merge   : 같은 실행에서 만든 plan 아티팩트에 apply tfplan
env 승격: dev 자동, prd는 GitHub Environment 승인 게이트 필수
```

- 로컬에서는 `fmt`/`validate`/`init -backend=false`/`providers lock`까지만. `apply`는 파이프라인에서만 실행한다
- `apply`는 직전에 생성한 plan 아티팩트에만 적용한다. `-auto-approve` 금지
- `terraform destroy`, state 조작(`state rm`/`state mv`/`import`)은 워크플로에 넣지 않는다. 사용자가 명시적으로 요청할 때 별도 수동 절차로 처리한다
- 하위 계층 output의 이름을 바꾸는 변경과 그것을 참조하는 변경은 같은 PR에 넣지 않는다. `terraform_remote_state`는 이미 저장된 state를 읽는데 PR plan은 상위 계층을 apply하지 않아 `Unsupported attribute`로 실패한다. 앞 계층을 먼저 merge·apply하고 참조를 다음 PR로 올린다
- 리소스의 로컬 이름을 바꿀 때는 `moved` 블록을 함께 넣는다. 주소만 바뀌어도 Terraform은 파괴·재생성으로 처리한다. apply가 끝나면 블록을 지운다
- CI Service Principal은 Azure 구독 `Contributor` + `User Access Administrator` + Databricks Account Admin 권한이 필요하다. 역할 할당을 생성해야 하므로 Contributor만으로는 부족하다
- 식별자는 GitHub repository variable로 주입한다. OIDC를 쓰므로 저장할 secret이 없다. `.tfvars`에 자격 증명을 넣지 않는다
- apply job은 반드시 `environment:`를 선언한다. federated credential subject가 environment 단위라 없으면 인증이 실패한다. 공개 저장소이므로 `pull_request_target`은 쓰지 않는다

## 이 파일의 규약

이 파일은 프로젝트 헌장이다. 갱신할 때도 개요와 규약만 담고 100줄을 넘기지 않는다. 로직 설명, 파일 목록, 모듈별 상세 문서는 넣지 않는다. 그런 내용은 각 모듈의 README나 코드 주석에 둔다.
