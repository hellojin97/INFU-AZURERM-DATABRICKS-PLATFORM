resource_group_name  = "INFU-TFSTATE-RG-CAC"
storage_account_name = "infutfstateblobcac"
container_name       = "tfstate"

key = "dev/workspace.tfstate"

use_azuread_auth = true
use_oidc         = true
