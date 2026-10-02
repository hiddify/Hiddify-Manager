# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_core_security_list" "hiddify_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = local.new_vcn_id
  display_name   = "hiddify-main-${random_string.deploy_id.result}"
  freeform_tags  = local.common_tags
  count = local.vcn_existed?0:1

  ingress_security_rules {
    protocol  = local.all_protocols
    source    = lookup(var.network_cidrs, "MAIN-SUBNET-REGIONAL-CIDR")
    stateless = true
  }


  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "MAIN-LB-SUBNET-REGIONAL-CIDR")

    tcp_options {
      max = local.microservices_port_number
      min = local.microservices_port_number
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, (var.instance_visibility == "Private") ? "MAIN-VCN-CIDR" : "ALL-CIDR")

    tcp_options {
      max = local.ssh_port_number
      min = local.ssh_port_number
    }
  }


  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs,"ALL-CIDR")

    tcp_options {
      max = local.http_port_number
      min = local.http_port_number
    }
  }
  
  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs,"ALL-CIDR")

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }
  
  egress_security_rules {
    protocol    = local.all_protocols
    destination = lookup(var.network_cidrs, "MAIN-SUBNET-REGIONAL-CIDR")
    stateless   = true
  }

  egress_security_rules {
    protocol    = local.all_protocols
    destination = lookup(var.network_cidrs, (var.instance_visibility == "Private") ? "MAIN-VCN-CIDR" : "ALL-CIDR")
  }

  egress_security_rules {
    protocol         = local.all_protocols
    destination      = lookup(data.oci_core_services.all_services.services[0], "cidr_block")
    destination_type = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "hiddify_lb_security_list" {
  compartment_id = (var.lb_compartment_ocid != "") ? var.lb_compartment_ocid : var.compartment_ocid
  vcn_id         = local.new_vcn_id
  display_name   = "hiddify-lb-${random_string.deploy_id.result}"
  freeform_tags  = local.common_tags
  count = local.vcn_existed?0:1

  ingress_security_rules {
    protocol  = local.all_protocols
    source    = lookup(var.network_cidrs, "ALL-CIDR")
    stateless = true
  }

  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    tcp_options {
      max = local.http_port_number
      min = local.http_port_number
    }
  }

  ingress_security_rules {
    protocol = local.tcp_protocol_number
    source   = lookup(var.network_cidrs, "ALL-CIDR")

    tcp_options {
      max = local.https_port_number
      min = local.https_port_number
    }
  }


  egress_security_rules {
    protocol    = local.all_protocols
    destination = lookup(var.network_cidrs, "ALL-CIDR")
    stateless   = true
  }

  egress_security_rules {
    protocol    = local.tcp_protocol_number
    destination = lookup(var.network_cidrs, "MAIN-SUBNET-REGIONAL-CIDR")

    tcp_options {
      max = local.microservices_port_number
      min = local.microservices_port_number
    }
  }
}

locals {
  http_port_number          = "80"
  https_port_number         = "443"
  microservices_port_number = "80"
  ssh_port_number           = "22"
  tcp_protocol_number       = "6"
  all_protocols             = "all"
}