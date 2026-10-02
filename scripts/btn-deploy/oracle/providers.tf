# Copyright (c) 2019-2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "hashicorp/oci"
      version = ">= 4.65.0"
      # https://registry.terraform.io/providers/hashicorp/oci/4.65.0
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0" # Latest version as February 2022 = 2.1.0.
      # https://registry.terraform.io/providers/hashicorp/local/2.1.0
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0" # Latest version as February 2022 = 3.1.0.
      # https://registry.terraform.io/providers/hashicorp/random/3.1.0
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0" # Latest version as February 2022 = 3.1.0.
      # https://registry.terraform.io/providers/hashicorp/tls/3.1.0
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0" # Latest version as February 2022 = 2.2.0.
      # https://registry.terraform.io/providers/hashicorp/tls/3.1.0
    }
  }
}

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  region       = local.region_to_deploy

  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

provider "oci" {
  alias        = "home_region"
  tenancy_ocid = var.tenancy_ocid
  region       = lookup(data.oci_identity_regions.home_region.regions[0], "name")

  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

provider "oci" {
  alias        = "current_region"
  tenancy_ocid = var.tenancy_ocid
  region       = var.region

  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}

locals {
  region_to_deploy = var.use_only_always_free_eligible_resources ? lookup(data.oci_identity_regions.home_region.regions[0], "name") : var.region
}