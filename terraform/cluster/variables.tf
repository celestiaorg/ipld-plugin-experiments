variable "name" {
  description = "The cluster name, e.g cdn"
}

variable "regions" {
  description = "Regions to launch in"
  type = list
  default = ["AMS3", "FRA1", "LON1", "NYC3", "SFO2", "SGP1", "TOR1", "AMS3", "FRA1", "LON1", "NYC3", "SFO2", "SGP1", "TOR1", "AMS3", "FRA1", "LON1", "NYC3", "SFO2", "SGP1", "TOR1"]
}

variable "ssh_key" {
  description = "SSH key filename to copy to the nodes"
  type = "string"
}

variable "pvt_key" {
  description = "SSH private key for terraform to use to login into the nodes"
}

variable "instance_size" {
  description = "The instance size to use"
  default = "1gb"
}

variable "servers" {
  description = "Desired instance count"
  default     = 4
}

