// Version - mfa-core service
variable "ms_mfacore_image_version" {
    default = "0.0.91"
}

// Main
variable "env" {}
variable "domain" {}
variable "min_size" {}
variable "max_size" {}
variable "cidr_vpc" {}
variable "vpcid" {}
variable "app_subnet_1" {}
variable "app_subnet_2" {}
variable "dmz_subnet_1" {}
variable "dmz_subnet_2" {}
variable "instance_type" {}
variable "key_name" {}

// DynamoDB
variable "read_capacity" {}
variable "write_capacity" {}

// mfa-core ECS service/task
variable "min_capacity_mfacore" {}
variable "max_capacity_mfacore" {}
variable "container_cpu_mfacore" {}
variable "container_memory_mfacore" {}
variable "container_memoryReservation_mfacore" {}
variable "java_xmx_xms_mfacore" {}
variable "appdynamics_key" {}
variable "deployment_minimum_healthy_percent" {}
variable "deployment_maximum_percent" {}

// CloudWatch
variable "log_group" {}
variable "retention_in_days" {}

// ElasticSearch
variable "es_instance_type" {}
variable "es_instance_count" {}
variable "es_master_instance_type" {}
variable "es_master_instance_count" {}