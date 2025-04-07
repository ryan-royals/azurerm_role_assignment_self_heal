terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26"
    }
  }
}

variable "scope" {
  type        = string
  description = "The scope at which the Role Assignment applies to, such as /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333, /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup, or /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup/providers/Microsoft.Compute/virtualMachines/myVM, or /providers/Microsoft.Management/managementGroups/myMG. Changing this forces a new resource to be created."
  nullable    = false
}

variable "role_definition_id" {
  type        = string
  description = "The Scoped-ID of the Role Definition. Changing this forces a new resource to be created."
  nullable    = true
  default     = null
}

variable "role_definition_name" {
  type        = string
  description = "The name of a built-in Role. Changing this forces a new resource to be created."
  nullable    = true
  default     = null
}

variable "principal_id" {
  type        = string
  description = "The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. Changing this forces a new resource to be created."
  nullable    = false
}
variable "limit_at_scope" {
  type        = bool
  description = "Whether to limit the result exactly at the specified scope and not above or below it. Defaults to false."
  default     = false
}

data "azurerm_role_assignments" "current" {
  scope          = var.scope
  limit_at_scope = var.limit_at_scope
  principal_id   = var.principal_id
}
data "azurerm_role_definition" "name_to_id" {
  count = var.role_definition_name != null ? 1 : 0
  name  = var.role_definition_name
}
locals {
  target_role_definition_id = var.role_definition_id != null ? var.role_definition_id : element(split("/", data.azurerm_role_definition.name_to_id[0].id), -1)
  current_role_definitions = distinct([
    for o in data.azurerm_role_assignments.current.role_assignments : element(split("/", o.role_definition_id), -1)
  ])
}

resource "azurerm_role_assignment" "assignment" {
  count = !contains(local.current_role_definitions, local.target_role_definition_id) ? 1 : 0

  role_definition_id = local.target_role_definition_id
  principal_id       = var.principal_id
  scope              = var.scope
}
