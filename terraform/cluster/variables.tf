variable "name" {
  description = "The cluster name, e.g cdn"
}

variable "regions" {
  description = "Regions to launch in"
  type = list
  default = [
    "AMS3",
    "FRA1",
    "LON1",
    "NYC3",
    "BLR1",
    "SFO1",
    "NYC2",
    "SFO2",
    "SGP1",
    "TOR1",
    "AMS3",
    "FRA1",
    "LON1",
    "NYC3",
    "SFO2",
    "SGP1",
    "TOR1",
    "AMS3",
    "FRA1",
    "LON1",
    "NYC3",
    "SFO2",
    "SGP1",
    "TOR1"]
}

variable "ssh_key" {
  description = "SSH public key filename to copy to the nodes"
  type = string
}

variable "pvt_key" {
  description = "SSH private key for terraform to use to login into the nodes"
  type = string
}

variable "instance_size" {
  description = "The instance size to use"
  default = "1gb"
}

variable "nodes" {
  description = "Desired instance count"
  default     = 4
}

variable "sync_nodes" {
  description = "Desired sync-nodes instance count for second experiment."
  default = 1
}

variable "rounds" {
  description = "Number of rounds to sample DA proofs (should "
  default = 100
}

variable "num_leaves" {
  default = 32
}

variable "remote_outdir" {
  description = "Absolute path to store measured data on the nodes."
  default = "/var/local/measurements"
}

variable "local_outdir" {
  description = "Path to store all measured data from the nodes locally."
  default = "ipfs-experiments-results/measurements"
}