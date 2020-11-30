provider "digitalocean" {
  token = var.DO_API_TOKEN
}

module "cluster" {
  source = "./cluster"
  name = var.TESTNET_NAME
  ssh_key = var.SSH_KEY_FILE
  pvt_key = var.pvt_key
  nodes = var.NODES
  sync_nodes = var.SYNC_NODES
  rounds = var.ROUNDS
  num_leaves = var.NUM_LEAVES
}

output "public_ips" {
  value = module.cluster.public_ips
}

