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

variable "NODES" {
  description = "Number of nodes"
  default = 4

  validation {
    condition = var.NODES > 1
    error_message = "You must provision at least two nodes."
  }
}

variable "SYNC_NODES" {
  description = "Number of nodes to run second experiment."
  default = 1
}

variable "NUM_LEAVES" {
  description = "Number of leaves to be used in experiment."
  default = 32

  validation {
    condition = var.NUM_LEAVES == 32 || var.NUM_LEAVES == 64 || var.NUM_LEAVES == 128 || var.NUM_LEAVES == 256
    error_message = "Valid values are: 32, 64, 128, 256."
  }
}

variable "ROUNDS" {
  description = "Number of rounds to run in the first experiment"
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

variable "REMOTE_OUTDIR" {
  description = "Absolute path to store measured data on the nodes."
  default = "/var/local/measurements"
}

variable "LOCAL_OUTDIR" {
  description = "Path to store all measured data from the nodes locally."
  default = "~/ipfs-experiments/measurements"
}