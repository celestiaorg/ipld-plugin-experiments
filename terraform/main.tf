variable "DO_API_TOKEN" {
  description = "DigitalOcean Access Token"
}

variable "TESTNET_NAME" {
  description = "Name of the testnet"
  default = "dag-experiments"
}

variable "SSH_KEY_FILE" {
  description = "SSH public key file to be used on the nodes"
  type = string
}

variable "pvt_key" {
  description = "SSH private key that terraform will use to install stuff on the nodes"
}

variable "SERVERS" {
  description = "Number of nodes"
  default = "4"

  validation {
    condition     = length(var.SERVERS) > 1
    error_message = "You must provision at least two nodes."
  }
}

variable "NUM_LEAVES" {
  description = "Number of leaves to be used in experiment."
  default = 32

  validation {
    condition = var.NUM_LEAVES == 32 || var.NUM_LEAVES == 64 || var.NUM_LEAVES == 128 || var.NUM_LEAVES == 256
    error_message = "valid values: 32, 64, 128, 256"
  }
}

variable "ROUNDS" {
  description = "Number of rounds to run in the experiment"
  default = 100
}

variable "NUM_SAMPLES" {
  description = "Number of sample requests per round"
  default = 15
}

variable "MAX_PARALLEL" {
  description = "Max. number of parallel requests per round. Should be <= NUM_SAMPLES."
  default = 15
}

variable "ROUND_TICKER" {
  description = "Time after which new round is started (default 2 mins)."
  default = "120s"
}

provider "digitalocean" {
  token = var.DO_API_TOKEN
}

module "cluster" {
  source           = "./cluster"
  name             = var.TESTNET_NAME
  ssh_key          = var.SSH_KEY_FILE
  pvt_key          = var.pvt_key
  servers          = var.SERVERS
}

output "public_ips" {
  value = module.cluster.public_ips
}

