resource "digitalocean_tag" "cluster" {
  name = var.name
}

resource "digitalocean_ssh_key" "cluster" {
  name = var.name
  public_key = file(var.ssh_key)
}

# provisions all nodes and runs first experiment which measures latency to sample DA proofs
resource "digitalocean_droplet" "cluster" {
  name = count.index == 0 ? "${var.name}-proposer" : "${var.name}-node-${count.index}"
  image = "ubuntu-20-10-x64"
  size = var.instance_size
  region = element(var.regions, count.index)
  ssh_keys = [
    digitalocean_ssh_key.cluster.id]
  count = var.nodes
  tags = [
    digitalocean_tag.cluster.id]

  provisioner "file" {
    source = "ipfs"
    destination = "/tmp"
  }

  provisioner "local-exec" {
    command = "cluster/testfiles.sh"
  }

  provisioner "file" {
    source = "testfiles"
    destination = "/var/local/"
  }

  provisioner "remote-exec" {
    inline = [
      # https://github.com/hashicorp/terraform/issues/18517#issuecomment-415023605
      "echo 'ClientAliveInterval 120' >> /etc/ssh/sshd_config",
      "echo 'ClientAliveCountMax 720' >> /etc/ssh/sshd_config",
      "chmod +x /tmp/ipfs/bootstrap.sh",
      "/tmp/ipfs/bootstrap.sh ${var.name}-proposer",
    ]
  }

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
}

# provisions a fresh node and run second experiment: measure time to sync 'blocks' from the network (above cluster)
resource "digitalocean_droplet" "sync-experiment" {
  name = "sync-node"
  image = "ubuntu-20-10-x64"
  size = var.instance_size
  region = element(var.regions, 0) # always pick the first region
  ssh_keys = [
    digitalocean_ssh_key.cluster.id]
  tags = [
    digitalocean_tag.cluster.id]
  count = var.sync_nodes

  depends_on = [digitalocean_droplet.cluster]

  provisioner "file" {
    source = "ipfs"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/ipfs/bootstrap.sh",
      "/tmp/ipfs/bootstrap.sh",
    ]
  }

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }

}

resource "null_resource" "collect_data" {
  provisioner "local-exec" {
    # TODO scp plots/data from each node
    command = "echo 'Such data'"
  }
  depends_on = [
    digitalocean_droplet.cluster,
    digitalocean_droplet.sync-experiment,
  ]
}

