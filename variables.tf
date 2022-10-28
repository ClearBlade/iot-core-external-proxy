variable "project_id" {
  description = "Provide project id where loadbalancer with haproxy will be deployed"
  type        = string
}

variable "region" {
  description = "Provide region where resources will be deployed"
  type        = string
}

variable "clearblade_ip" {
  description = "Clearblade endpoint"
  type        = string
}

variable "clearblade_mqtt_ip" {
  description = "Clearblade MQTT endpoint"
  type = string
}