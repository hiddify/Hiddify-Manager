# Copyright (c) 2019-2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

variable "tenancy_ocid" {}
variable "region" {}
variable "compartment_ocid" {}

variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}

variable "public_ssh_key" {
  default = ""
}

# Compute
variable "num_nodes" {
  default = 1
}
variable "generate_public_ssh_key" {
  default = true
}
variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}
variable "instance_ocpus" {
  default = 2
}
variable "instance_shape_config_memory_in_gbs" {
  default = 12
}
variable "image_operating_system" {
  default = "Canonical Ubuntu"
}
variable "image_operating_system_version" {
  default = "22.04"
}
variable "instance_visibility" {
  default = "Public"
}

variable "lb_compartment_ocid" {
  default = ""
}

variable "network_cidrs" {
  type = map(string)

  default = {
    MAIN-VCN-CIDR                = "10.1.0.0/16"
    MAIN-SUBNET-REGIONAL-CIDR    = "10.1.21.0/24"
    MAIN-LB-SUBNET-REGIONAL-CIDR = "10.1.22.0/24"
    LB-VCN-CIDR                  = "10.2.0.0/16"
    LB-SUBNET-REGIONAL-CIDR      = "10.2.22.0/24"
    ALL-CIDR                     = "0.0.0.0/0"
  }
}

variable "domain_name" {
  default = ""
}

variable "guid_secret" {
  default = ""
}
variable "telegram_adtag" {
  default = ""
}

# Always Free only or support other shapes
variable "use_only_always_free_eligible_resources" {
  default = true
}

# Shapes
locals {
  instance_shape                             = var.instance_shape
  compute_shape_micro = local.compute_platform == "linux/arm64" ? "VM.Standard.A1.Flex" : "VM.Standard.E2.1.Micro"
  compute_flexible_shapes = [
    "VM.Standard.A1.Flex"
  ]
  compute_shape_flexible_descriptions = [
    "Cores for Standard.A1 based VM and BM Instances"
  ]
  compute_arm_shapes = [
    "VM.Standard.A1.Flex",
  ]
  compute_shape_flexible_vs_descriptions = zipmap(local.compute_flexible_shapes, local.compute_shape_flexible_descriptions)
  compute_shape_description              = lookup(local.compute_shape_flexible_vs_descriptions, local.instance_shape, local.instance_shape)
  compute_platform                       = contains(local.compute_arm_shapes, var.instance_shape) ? "linux/arm64" : "linux/amd64"
  lb_shape_flexible                      = "flexible"
  compute_arm_shape_check = local.compute_platform == "linux/arm64" ? (contains(local.compute_arm_shapes, local.instance_shape) ? 0 : (
  file("ERROR: Selected compute shape (${local.instance_shape}) not compatible with HiddifyProxy ${local.compute_platform} stack"))) : 0


  guid=var.guid_secret==""? random_string.guid.result:var.guid_secret

  vcn_existed=length(data.oci_core_subnets.PRIVATESUBNET.subnets)>0
  new_vcn_id=local.vcn_existed ?0:"${oci_core_virtual_network.hiddify_main_vcn[0].id}"
  subnet_ocid = local.vcn_existed ? "${data.oci_core_subnets.PRIVATESUBNET.subnets[0].id}" : "${oci_core_subnet.hiddify_main_subnet[0].id}"

  
  
}
