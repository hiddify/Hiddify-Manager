# Copyright (c) 2019-2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Gets ObjectStorage namespace
data "oci_objectstorage_namespace" "user_namespace" {
  compartment_id = var.compartment_ocid
}

# Randoms
resource "random_string" "deploy_id" {
  length  = 4
  special = false
}
resource "random_string" "guid" {
  length           = 32
  special          = false
  min_upper        = 0
  min_lower        = 0
  min_numeric      = 20
  min_special      = 12
  override_special = "abcdef"
}


### Passwords using random_string instead of random_password to be compatible with ORM (Need to update random provider)
resource "random_string" "autonomous_database_wallet_password" {
  length           = 16
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

resource "random_string" "autonomous_database_admin_password" {
  length           = 16
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

resource "random_string" "catalogue_db_password" {
  length           = 16
  special          = true
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 3
  override_special = "{}#^*<>[]%~"
}

# Check for resource limits
## Check available compute shape
data "oci_limits_services" "compute_services" {
  compartment_id = var.tenancy_ocid

  filter {
    name   = "name"
    values = ["compute"]
  }
}
data "oci_limits_limit_definitions" "compute_limit_definitions" {
  compartment_id = var.tenancy_ocid
  service_name   = data.oci_limits_services.compute_services.services.0.name

  filter {
    name   = "description"
    values = [local.compute_shape_description]
  }
}
data "oci_limits_resource_availability" "compute_resource_availability" {
  compartment_id      = var.tenancy_ocid
  limit_name          = data.oci_limits_limit_definitions.compute_limit_definitions.limit_definitions[0].name
  service_name        = data.oci_limits_services.compute_services.services.0.name
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[count.index].name

  count = length(data.oci_identity_availability_domains.ADs.availability_domains)
}
resource "random_shuffle" "compute_ad" {
  input        = local.compute_available_limit_ad_list
  result_count = length(local.compute_available_limit_ad_list)
}
locals {
  compute_multiplier_nodes_ocpus  = local.is_flexible_instance_shape ? (var.num_nodes * var.instance_ocpus) : var.num_nodes
  compute_available_limit_ad_list = [for limit in data.oci_limits_resource_availability.compute_resource_availability : limit.availability_domain if(limit.available - local.compute_multiplier_nodes_ocpus) >= 0]
  compute_available_limit_check = length(local.compute_available_limit_ad_list) == 0 ? (
  file("ERROR: No limits available for the chosen compute shape and number of nodes or OCPUs")) : 0
}

# Gets a list of supported images based on the shape, operating_system and operating_system_version provided
data "oci_core_images" "compute_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_tenancy" "tenant_details" {
  tenancy_id = var.tenancy_ocid

  provider = oci.current_region
}

data "oci_identity_regions" "home_region" {
  filter {
    name   = "key"
    values = [data.oci_identity_tenancy.tenant_details.home_region_key]
  }

  provider = oci.current_region
}

# Available Services
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Cloud Init
data "cloudinit_config" "nodes" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content      = local.cloud_init
  }
}

## Files and Templatefiles
locals {
  cloud_init = templatefile("${path.module}/cloud-config.template.yaml",
  {
      guid=local.guid
      domain=var.domain_name
      telegram_adtag=var.telegram_adtag
  })
}




# Tags
locals {
  common_tags = {
    Reference = "Created by OCI QuickStart for HiddifyProxy Basic demo"
  }
}

data "oci_core_vcns" "VCN" {
  compartment_id = var.compartment_ocid
  filter {
    name   = "display_name"
    values = ["hiddify-main"]
  }
}

/********** Subnet Accessor **********/
data "oci_core_subnets" "PRIVATESUBNET" {
  compartment_id = var.compartment_ocid
  filter {
    name   = "display_name"
    values = ["hiddify-main"]
  }
}