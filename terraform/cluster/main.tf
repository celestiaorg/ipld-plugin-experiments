resource "digitalocean_tag" "cluster" {
  name = var.name
}

resource "digitalocean_ssh_key" "cluster" {
  name       = var.name
  public_key = file(var.ssh_key)
}


resource "digitalocean_droplet" "cluster" {
  name = "${var.name}-node${count.index}"
  image = "ubuntu-20-10-x64"
  size = var.instance_size
  region = element(var.regions, count.index)
  ssh_keys = [
    digitalocean_ssh_key.cluster.id]
  count = var.servers
  tags = [
    digitalocean_tag.cluster.id]

  provisioner "file" {
    source           = "ipfs"
    destination      = "/tmp"
  }
  provisioner "remote-exec" {
    inline           = [
      "chmod +x /tmp/ipfs/bootstrap.sh",
      "/tmp/ipfs/bootstrap.sh",
    ]
  }

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "5m"
  }
}

