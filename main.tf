terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

variable "region" {
  description = "IBM Cloud region to deploy resources in (e.g., us-south, eu-gb)."
}

variable "resource_name_prefix" {
  description = "Prefix for naming all the resources (e.g., project or environment name)."
}

variable "zone" {
  description = "IBM Cloud availability zone within the selected region (e.g., us-south-1)."
}

variable "mgmt_ip_cidr_range" {
  description = "CIDR range for the management subnet and address prefix (e.g., 10.0.0.0/24)."
}

variable "inside_ip_cidr_range" {
  description = "CIDR range for the inside subnet and address prefix."
}

variable "outside_ip_cidr_range" {
  description = "CIDR range for the outside subnet and address prefix."
}

variable "diag_ip_cidr_range" {
  description = "CIDR range for the diagnostic subnet and address prefix."
}

variable "image_id" {
  description = "ID of the custom image or stock image used for FTDv deployment."
}

variable "profile" {
  description = "IBM Cloud VPC profile type for the virtual server instance (e.g., bx2-4x16)."
}

variable "ssh_key_id" {
  description = "ID of the SSH key to use for instance access."
}

provider "ibm" {
  region = var.region
}

#--------------------------
# VPC Networks
#--------------------------

resource "ibm_is_vpc" "ftdv_vpc" {
  name = "${var.resource_name_prefix}-ftdv-vpc"
}

#--------------------------
# Address Prefixes
#--------------------------
resource "ibm_is_vpc_address_prefix" "mgmt_prefix" {
  name = "${var.resource_name_prefix}-mgmt-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.ftdv_vpc.id
  cidr = var.mgmt_ip_cidr_range
}

resource "ibm_is_vpc_address_prefix" "inside_prefix" {
  name = "${var.resource_name_prefix}-inside-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.ftdv_vpc.id
  cidr = var.inside_ip_cidr_range
}

resource "ibm_is_vpc_address_prefix" "outside_prefix" {
  name = "${var.resource_name_prefix}-outside-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.ftdv_vpc.id
  cidr = var.outside_ip_cidr_range
}

resource "ibm_is_vpc_address_prefix" "diag_prefix" {
  name = "${var.resource_name_prefix}-diag-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.ftdv_vpc.id
  cidr = var.diag_ip_cidr_range
}

#--------------------------
# Subnets
#--------------------------
resource "ibm_is_subnet" "mgmt_subnet" {
  name            = "${var.resource_name_prefix}-mgmt-subnet"
  vpc             = ibm_is_vpc.ftdv_vpc.id
  zone            = var.zone
  ipv4_cidr_block = var.mgmt_ip_cidr_range
  depends_on      = [ibm_is_vpc_address_prefix.mgmt_prefix]
}

resource "ibm_is_subnet" "inside_subnet" {
  name            = "${var.resource_name_prefix}-inside-subnet"
  vpc             = ibm_is_vpc.ftdv_vpc.id
  zone            = var.zone
  ipv4_cidr_block = var.inside_ip_cidr_range
  depends_on      = [ibm_is_vpc_address_prefix.inside_prefix]
}

resource "ibm_is_subnet" "outside_subnet" {
  name            = "${var.resource_name_prefix}-outside-subnet"
  vpc             = ibm_is_vpc.ftdv_vpc.id
  zone            = var.zone
  ipv4_cidr_block = var.outside_ip_cidr_range
  depends_on      = [ibm_is_vpc_address_prefix.outside_prefix]
}

resource "ibm_is_subnet" "diag_subnet" {
  name            = "${var.resource_name_prefix}-diag-subnet"
  vpc             = ibm_is_vpc.ftdv_vpc.id
  zone            = var.zone
  ipv4_cidr_block = var.diag_ip_cidr_range
  depends_on      = [ibm_is_vpc_address_prefix.diag_prefix]
}

#--------------------------
# Security Groups + Rules
#--------------------------

resource "ibm_is_security_group" "mgmt_sg" {
  name = "${var.resource_name_prefix}-ftdv-mgmt-sg"
  vpc  = ibm_is_vpc.ftdv_vpc.id
}

resource "ibm_is_security_group_rule" "mgmt_allow_tcp_22" {
  group     = ibm_is_security_group.mgmt_sg.id
  direction = "inbound"
  remote    = var.mgmt_ip_cidr_range
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "mgmt_allow_tcp_443" {
  group     = ibm_is_security_group.mgmt_sg.id
  direction = "inbound"
  remote    = var.mgmt_ip_cidr_range
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "mgmt_allow_tcp_8305" {
  group     = ibm_is_security_group.mgmt_sg.id
  direction = "inbound"
  remote    = var.mgmt_ip_cidr_range
  tcp {
    port_min = 8305
    port_max = 8305
  }
}

#--------------------------
# FTDv Instance
#--------------------------
resource "ibm_is_instance" "ftdv" {
  name    = "${var.resource_name_prefix}-ftdv-instance"
  zone    = var.zone
  vpc     = ibm_is_vpc.ftdv_vpc.id
  image   = var.image_id
  profile = var.profile
  keys    = [var.ssh_key_id]

  primary_network_interface {
    subnet          = ibm_is_subnet.mgmt_subnet.id
    security_groups = [ibm_is_security_group.mgmt_sg.id]
  }

  network_interfaces {
    subnet = ibm_is_subnet.diag_subnet.id
  }

  network_interfaces {
    subnet = ibm_is_subnet.inside_subnet.id
  }

  network_interfaces {
    subnet = ibm_is_subnet.outside_subnet.id
  }

  tags = ["${var.resource_name_prefix}-ftdv", "${var.resource_name_prefix}-ngfwv"]
}
