#################
### Variables ###
#################

# Project
variable "project" {
  type = string
}

# Instance
variable "instance" {
  type = string
}

# Datacenter location resources
variable "location" {
  type    = string
  default = "westeurope"
}

# New Relic OTLP endpoint
variable "newrelic_otlp_endpoint" {
  type    = string
  default = "https://otlp.nr-data.net:4317"
}

# New Relic license key
variable "newrelic_license_key" {
  type    = string
}