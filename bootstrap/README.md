# Bootstrap

Terraform이 돌기 **전에** 사람이 손으로 만들어야 하는 것들의 기록.

이 디렉터리에는 Terraform 코드가 없다. 여기 적힌 리소스는 어떤 state에도 속하지 않으며, 파이프라인이 건드리지 않는다.

닭과 달걀 때문이다. state를 담을 Storage Account는 Terraform state에 넣을 수 없고, CI가 Azure에 로그인하는 데 쓰는 Entra 앱은 CI 자신이 만들 수 없다.

작업일: 2026-08-06 / 리전: Canada Central

이 저장소는 public이므로 아래 표의 식별자는 placeholder로 적는다. 실제 값은 GitHub repository variable에 있고, Azure Portal과 Databricks accounts 콘솔에서 확인할 수 있다.

## 1. Azure 구독

| 항목 | 값 |
|---|---|
| 구독 | 개인 MSDN 구독 |
| 구독 ID | `<AZURE_SUBSCRIPTION_ID>` |
| 테넌트 ID | `<AZURE_TENANT_ID>` |

### 등록한 리소스 공급자

`Microsoft.Databricks` · `Microsoft.ManagedIdentity` · `Microsoft.Storage` · `Microsoft.KeyVault` · `Microsoft.Network`

등록을 빠뜨리면 첫 apply가 `MissingSubscriptionRegistration`으로 실패한다.

## 2. CI용 Service Principal

| 항목 | 값 |
|---|---|
| 앱 이름 | `INFU-AZURE-DATABRICKS-GITHUB-ACTIONS` |
| 클라이언트 ID | `<AZURE_CLIENT_ID>` |
| 클라이언트 암호 | **없음** (OIDC 전용) |

### 페더레이션 자격 증명

issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`

| 이름 | subject |
|---|---|
| `GH-PULL-REQUEST` | `repo:hellojin97@96719728/INFU-AZURERM-DATABRICKS-PLATFORM@1325315048:pull_request` |
| `GH-ENVIRONMENT-DEV` | `...:environment:dev` |
| `GH-ENVIRONMENT-STG` | `...:environment:stg` |
| `GH-ENVIRONMENT-PRD` | `...:environment:prd` |

subject에 붙은 숫자는 GitHub의 immutable subject claim 형식이다. 2026-07-15 이후 생성된 저장소는 이름 대신 owner ID(`96719728`)와 repo ID(`1325315048`)를 쓴다. 저장소를 rename하거나 transfer해도 자격 증명이 깨지지 않는다.

`pull_request`용과 environment용 subject가 다르므로 넷 다 필요하다. plan은 environment 없이 PR에서 돌고, apply는 environment를 거친다.

### 역할 할당

| 범위 | 역할 | 이유 |
|---|---|---|
| 구독 | `Contributor` | Azure 리소스 생성 |
| 구독 | `User Access Administrator` | Access Connector에 `Storage Blob Data Contributor`를 부여해야 함. Contributor 권한으로는 역할 할당을 만들 수 없다 |
| state Storage Account | `Storage Blob Data Contributor` | 공유 키를 껐으므로 Entra ID로 state에 접근 |

## 3. Terraform state backend

| 항목 | 값 |
|---|---|
| 리소스 그룹 | `INFU-TFSTATE-RG-CAC` |
| Storage Account | `infutfstateblobcac` |
| 컨테이너 | `tfstate` (프라이빗) |
| SKU | `Standard_LRS` |
| 삭제 잠금 | `NO-DELETE` (CanNotDelete) |

### 보안 설정

| 설정 | 값 | 이유 |
|---|---|---|
| 스토리지 계정 키 액세스 | **해제** | Entra ID 인증만 허용. 유출될 키 자체를 없앤다 |
| Blob 익명 액세스 | 해제 | |
| 공용 네트워크 액세스 | **사용** | GitHub 호스팅 러너가 공용 인터넷에 있다. Private Endpoint를 붙이면 `terraform init`이 실패한다 |
| 계층 구조 네임스페이스 | 해제 | state는 일반 blob. Unity Catalog용 ADLS Gen2는 별개이며 Terraform이 만든다 |
| 버전 관리 / Blob·컨테이너 일시 삭제 | 사용 (7일) | state 손상 시 복구 |
| 버전 수준 불변성 | 해제 | 켜면 state 덮어쓰기가 막혀 apply가 실패한다 |
| 최소 TLS | 1.2 | |

키 액세스를 껐으므로 backend 설정에 `use_azuread_auth = true`가 필요하다.

`INFU-TFSTATE-RG-CAC`는 Terraform 코드에 절대 등장하지 않는다. 플랫폼용 리소스 그룹은 Terraform이 따로 만든다.

## 4. Databricks Account

| 항목 | 값 |
|---|---|
| Account ID | `<DATABRICKS_ACCOUNT_ID>` |
| 콘솔 | https://accounts.azuredatabricks.net |
| 기존 metastore | 없음 (Terraform이 Canada Central에 생성) |

위 Service Principal을 `User management > Service principals`에 Microsoft Entra ID managed로 추가하고 **Account admin** 역할을 부여했다.

이 단계는 Terraform으로 대체할 수 없다. SP가 자기 자신에게 Account admin을 줄 수 없기 때문이다.

첫 로그인은 Entra ID 전역 관리자 계정으로 해야 한다. 첫 로그인한 전역 관리자가 자동으로 Databricks Account Admin이 된다.

## 5. GitHub

저장소: `hellojin97/INFU-AZURERM-DATABRICKS-PLATFORM` (**public**)

Environment 보호 규칙은 private 저장소에서 Pro 이상을 요구한다. 공개 전환으로 무료 사용.

### Environment

| 이름 | 배포 브랜치 | 필수 승인자 | 자기 승인 |
|---|---|---|---|
| `dev` | `main` | 없음 | — |
| `stg` | `main` | `hellojin97` | 허용 |
| `prd` | `main` | `hellojin97` | 허용 |

1인 저장소이므로 자기 승인을 막으면 apply가 영원히 대기한다.

Environment는 승인 게이트일 뿐 아니라 OIDC 신원이기도 하다. apply job이 `environment:`를 선언하지 않으면 Azure 인증 자체가 실패한다.

### Repository variables

secret이 아니라 variable이다. OIDC를 쓰므로 저장할 비밀값이 없다.

| 이름 | 출처 |
|---|---|
| `AZURE_SUBSCRIPTION_ID` | 1절 |
| `AZURE_TENANT_ID` | 1절 |
| `AZURE_CLIENT_ID` | 2절 |
| `DATABRICKS_ACCOUNT_ID` | 4절 |

plan job은 environment 없이 PR에서 돌기 때문에 environment 변수를 읽지 못한다. 그래서 저장소 레벨에 둔다.

## 재구축 순서

앞 단계의 산출물이 뒤에서 필요하다.

1. 리소스 공급자 등록
2. Entra 앱 등록 → 클라이언트 ID, 테넌트 ID 확보
3. 페더레이션 자격 증명 4개
4. 구독 역할 할당 2개
5. state용 리소스 그룹 + Storage Account + 컨테이너 → SP에 `Storage Blob Data Contributor`
6. 삭제 잠금
7. Databricks accounts 콘솔 → Account ID 확보, SP를 Account Admin 등록
8. GitHub Environment 3개, repository variable 4개

## 주의

- 이 저장소는 public이다. 워크플로 로그와 PR에 붙는 plan 출력이 모두 공개된다
- `pull_request_target`을 쓰지 않는다. 포크에서 온 코드에 저장소 권한을 넘긴다
- 여기 적힌 GUID는 식별자이지 자격 증명이 아니다. 클라이언트 암호는 존재하지 않으며, OIDC 토큰은 이 저장소에 대해서만 발급된다
