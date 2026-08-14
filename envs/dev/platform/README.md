# envs/dev/platform

dev 환경의 Azure 인프라와 Databricks workspace를 만드는 root 모듈. 독립 state 단위다.

workspace를 **만드는** 계층이다. workspace 안을 **설정하는** 것은 `envs/dev/workspace/` 소관이다. 같은 apply에서 둘을 하면 아직 존재하지 않는 workspace URL로 provider를 채우게 되어 실패한다.

## 소유하는 것

| 리소스 | 이름 · 비고 |
|---|---|
| `azurerm_resource_group` × 3 | `INFU-DEV-NETWORK-RG-CAC`, `INFU-DEV-DATABRICKS-RG-CAC`, `INFU-DEV-PLATFORM-RG-CAC` |
| `azurerm_virtual_network` | `INFU-DEV-DATABRICKS-VNET-CAC` (`10.10.0.0/16`) |
| `azurerm_subnet` × 3 | `...-PUBLIC-SNET` (`10.10.1.0/24`), `...-PRIVATE-SNET` (`10.10.2.0/24`) — Databricks 위임. `...-PRIVATELINK-SNET` (`10.10.3.0/24`) — 위임 없음, PE 전용 |
| `azurerm_network_security_group` | `INFU-DEV-DATABRICKS-NSG-CAC` + association × 2 (Databricks 서브넷만) |
| `azurerm_private_dns_zone` × 2 | `privatelink.dfs.core.windows.net`, `privatelink.blob.core.windows.net` + VNet link × 2 |
| `azurerm_storage_account` | `infudevadlscac` — ADLS Gen2(HNS), 공용 접근 차단, 공유 키 해제 |
| `azurerm_private_endpoint` × 2 | `...-ADLS-DFS-PE-CAC`, `...-ADLS-BLOB-PE-CAC` — subresource당 하나 |
| `azurerm_storage_container` | `managed` — catalog managed storage용 filesystem |
| `azurerm_databricks_access_connector` | `INFU-DEV-DATABRICKS-AC-CAC` — UC storage credential용 관리 ID |
| `azurerm_role_assignment` | Access Connector에 `Storage Blob Data Contributor` (SA 범위로 한정) |
| `azurerm_databricks_workspace` | `INFU-DEV-DATABRICKS-WS-CAC` (premium, VNet injection) |
| `databricks_metastore_assignment` | account 계층의 metastore를 이 workspace에 연결 |
| `databricks_mws_permission_assignment` | account 계층의 `INFU-DEV-WS-ADMINS` 그룹을 이 workspace에 `ADMIN`으로 바인딩 |

`INFU-DEV-DATABRICKS-MANAGED-RG-CAC`는 Terraform이 만들지 않는다. workspace 생성 시 Databricks가 만들고 관리한다.

## 리소스 그룹을 셋으로 나눈 이유

| RG | 담는 것 | 기준 |
|---|---|---|
| `NETWORK` | VNet, 서브넷, NSG, DNS 영역, PE | 여러 대상이 공유하는 네트워크 객체. PE와 그 NIC도 네트워크 소속 |
| `DATABRICKS` | workspace | 워크로드 단위 |
| `PLATFORM` | ADLS, Access Connector, (예정) Key Vault | 플랫폼 스토리지. 네트워크·workspace와 수명 주기 분리 |

- 리소스 그룹 이름은 리소스 ID에 박힌다 — 나중에 옮기면 파괴 후 재생성
- **세 그룹 모두 이 계층의 같은 state다.** 나눠서 얻는 것은 RBAC 범위와 포털 실수 방지. 진짜 분리가 필요하면 별도 root 모듈로 만든다

## 의도적으로 정한 값

| 값 | 이유 |
|---|---|
| `sku = "premium"` | Unity Catalog, cluster policy, 권한 ACL이 premium 전용이다 |
| `no_public_ip = true` | Secure Cluster Connectivity. 클러스터에 공인 IP를 주지 않는다 |
| NSG에 `security_rule` 없음 | workspace 생성 시 Databricks가 필요한 규칙을 직접 넣는다. 인라인으로 적으면 매 plan마다 그것을 지우려 든다 |
| 두 서브넷 모두 `delegation` | `virtual_network_id`를 쓰는 workspace는 두 서브넷 다 `Microsoft.Databricks/workspaces`에 위임되어야 한다 |
| PRIVATELINK 서브넷 분리 | PE는 위임된 서브넷에 못 들어간다. NSG association도 없다 — PE NIC는 Databricks 규칙과 무관 |
| `public_network_access_enabled = false` | ADLS 접근은 PE로만. dev부터 PE — prd와 구성 일치 |
| `shared_access_key_enabled = false` | state SA와 같은 원칙. Entra ID 인증만 허용 |
| `is_hns_enabled = true` | ADLS Gen2 스위치. 생성 후 변경 불가 |
| container에 `storage_account_id` | ARM API로 생성. data-plane API는 공용 접근 차단 SA라 403 |
| PE × 2 (dfs·blob) | PE 하나가 subresource 하나. ADLS는 두 영역 모두 필요 |

`custom_parameters`는 서브넷 ID가 아니라 **NSG 연결 리소스의 ID**를 받는다. 이 참조가 "NSG 연결 먼저, workspace 나중" 순서를 만든다.

## 파일

| 파일 | 역할 |
|---|---|
| `versions.tf` | Terraform·provider 버전 고정, backend 선언 |
| `providers.tf` | `azurerm`(기본), `databricks`(`alias = "account"`) |
| `variables.tf` | 입력 변수 선언 |
| `terraform.tfvars` | 환경 값. secret 없음 |
| `backend.hcl` | backend 부분 설정. `init -backend-config`로 주입 |
| `main.tf` | locals, 리소스 그룹 × 3 |
| `network.tf` | VNet, 서브넷, NSG, 사설 DNS 영역 |
| `storage.tf` | ADLS, PE, Access Connector, 역할 할당, container |
| `workspace.tf` | workspace, metastore assignment, permission assignment |
| `outputs.tf` | workspace 계층이 remote state로 읽는 출력 |
| `.terraform.lock.hcl` | provider 체크섬. `linux_amd64` + `darwin_arm64` |

## 값 주입 경로

| 값 | 경로 |
|---|---|
| `databricks_account_id` `azure_client_id` `azure_tenant_id` | `TF_VAR_` 환경 변수. 저장소가 public이라 파일에 안 둔다 |
| `prefix` `env` `location` `location_abbreviation` `owner` CIDR 3개 | `terraform.tfvars` |
| backend 신원 | `ARM_CLIENT_ID` `ARM_TENANT_ID` `ARM_SUBSCRIPTION_ID` `ARM_USE_OIDC` |

## state

```
컨테이너   tfstate
key        dev/platform.tfstate
```

## account 계층 참조

`data "terraform_remote_state" "account"`가 `account.tfstate`를 읽어 `metastore_id`와 `workspace_admin_group_ids`를 가져온다. 값을 복사해 붙여넣지 않는다.

이 data 블록의 `config`는 root의 `backend` 블록에서 아무것도 물려받지 않는다. 그래서 `account/backend.hcl`과 같은 값을 다시 적는다.

`use_azuread_auth = true`가 여기 필요하다. 대응 환경 변수 `ARM_USE_AZUREAD`를 워크플로가 설정하지 않고, state Storage Account는 공유 키 액세스를 껐다.

`validate`는 data source를 읽지 않는다. 이 블록이 실제로 동작하는지는 CI `plan`에서 처음 확인된다.

## 로컬에서 할 수 있는 것

```bash
terraform fmt -recursive
terraform init -backend=false
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
terraform validate
```

`init -backend=false`는 state에 접근하지 않아 Azure 자격 증명이 필요 없다. `apply`는 파이프라인에서만 실행한다.

## 다음에 들어올 것

| 항목 | 메모 |
|---|---|
| NAT Gateway | `no_public_ip = true` 클러스터의 egress. 없어도 apply는 통과하지만 클러스터 기동은 별개로 확인해야 한다 |
| Key Vault | secret scope 백엔드. PE는 PRIVATELINK 서브넷에 추가 |
