resource "digitalocean_tag" "cluster" {
  name = var.name
}

resource "digitalocean_ssh_key" "cluster" {
  name       = var.name
  public_key = file(var.ssh_key)
}

resource "null_resource" "generate_testdata" {
  provisioner "local-exec" {
    command = "cluster/testfiles.sh ./testfiles ${var.num_leaves} ${var.rounds}"
  }
}

resource "null_resource" "prep_local_outdir" {
  provisioner "local-exec" {
    command = "mkdir -p ${var.local_outdir}"
  }
}

# provision proposer first:
resource "digitalocean_droplet" "proposer" {
  name  = "${var.name}-proposer"
  image = "ubuntu-20-10-x64"
  size  = var.instance_size
  ssh_keys = [
  digitalocean_ssh_key.cluster.id]
  region = element(var.regions, 0)
  # proposer always picks the first region

  # this could also be made configurable but we currently just use one proposer node
  # the other nodes can also be made proposer afterwards by loading the leafs into their DAG
  count = 1

  tags = [
  digitalocean_tag.cluster.id]
  # Generate testdata once:
  depends_on = [
  null_resource.generate_testdata]

  provisioner "file" {
    source      = "ipfs"
    destination = "/tmp"
  }

  provisioner "file" {
    source      = "testfiles"
    destination = "/var/local/"
  }

  provisioner "remote-exec" {
    inline = [
      # https://github.com/hashicorp/terraform/issues/18517#issuecomment-415023605
      "echo 'ClientAliveInterval 120' >> /etc/ssh/sshd_config",
      "echo 'ClientAliveCountMax 720' >> /etc/ssh/sshd_config",
      "chmod +x /tmp/ipfs/bootstrap.sh",
      "/tmp/ipfs/bootstrap.sh",
      "/tmp/ipfs/dag-puts.sh ${var.rounds}",
      # add dags locally
    ]
  }

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "10m"
  }
}

# provisions all other
resource "digitalocean_droplet" "clients-cluster" {
  # TODO it's probably better to split out provisioning the proposer separately
  # and then spin up the clients afterwards.
  # The distinction between client nodes and proposer in scripts
  # is currently achieved via the hostname:
  name   = "${var.name}-node-${count.index}"
  image  = "ubuntu-20-10-x64"
  size   = var.instance_size
  region = element(var.regions, count.index)
  ssh_keys = [
  digitalocean_ssh_key.cluster.id]
  count = var.nodes

  tags = [
  digitalocean_tag.cluster.id]
  depends_on = [
  digitalocean_droplet.proposer]

  provisioner "file" {
    source      = "ipfs"
    destination = "/tmp"
  }

  provisioner "file" {
    source      = "testfiles"
    destination = "/var/local/"
  }

  provisioner "remote-exec" {
    inline = [
      # https://github.com/hashicorp/terraform/issues/18517#issuecomment-415023605
      "echo 'ClientAliveInterval 120' >> /etc/ssh/sshd_config",
      "echo 'ClientAliveCountMax 720' >> /etc/ssh/sshd_config",
      "chmod +x /tmp/ipfs/bootstrap.sh",
      "mkdir -p ${var.remote_outdir}",
      "/tmp/ipfs/bootstrap.sh",
    ]
  }

  connection {
    host        = self.ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "10m"
  }
}

locals {
  names = digitalocean_droplet.clients-cluster.*.name
  ips   = digitalocean_droplet.clients-cluster.*.ipv4_address
}

resource "null_resource" "run-clients-measurements" {
  count = var.nodes

  connection {
    host        = local.ips[count.index]
    user        = "root"
    type        = "ssh"
    private_key = file(var.pvt_key)
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = [
      "/tmp/ipfs/measure-dag-get-latencies.sh ${var.rounds} ${var.num_leaves} ${var.remote_outdir}",
    ]
  }

  # scp result data from each node:
  provisioner "local-exec" {
    command = "scp -rp -B -o 'StrictHostKeyChecking no' -i ${var.pvt_key} root@${local.ips[count.index]}:${var.remote_outdir} ${var.local_outdir}/${local.names[count.index]}"
  }
  depends_on = [
  digitalocean_droplet.clients-cluster]
}

# provisions a fresh node and run second experiment: measure time to sync 'blocks' from the network (above cluster)
//resource "digitalocean_droplet" "sync-experiment" {
//  name = "sync-node"
//  image = "ubuntu-20-10-x64"
//  size = var.instance_size
//  region = element(var.regions, 0) # always pick the first region
//  ssh_keys = [
//    digitalocean_ssh_key.cluster.id]
//  tags = [
//    digitalocean_tag.cluster.id]
//  count = var.sync_nodes
//
//  depends_on = [digitalocean_droplet.cluster]
//
//  provisioner "file" {
//    source = "ipfs"
//    destination = "/tmp"
//  }
//
//  provisioner "remote-exec" {
//    inline = [
//      "chmod +x /tmp/ipfs/bootstrap.sh",
//      "/tmp/ipfs/bootstrap.sh",
//    ]
//  }
//
//  connection {
//    host = self.ipv4_address
//    user = "root"
//    type = "ssh"
//    private_key = file(var.pvt_key)
//    timeout = "2m"
//  }
//}

//locals {
//  ips = {
//    for node in digitalocean_droplet.cluster :
//    node.id => node.ipv4_address
//    if node.name != "${var.name}-proposer"
//  }
//
//  depends_on = [
//    digitalocean_droplet.cluster,
//  ]
//}

//resource "null_resource" "collect_data" {
//  for_each = local.ips
//
//  provisioner "local-exec" {
//    # scp data from each node
//    command = "scp -rp -B -o 'StrictHostKeyChecking no' -i ${var.pvt_key} root@${each.value}:${var.remote_outdir} ${var.local_outdir}/${each.value}"
//  }
//  depends_on = [
//    digitalocean_droplet.cluster,
//    # TODO: uncomment to run sync-experiment:
//    // digitalocean_droplet.sync-experiment,
//  ]
//}

