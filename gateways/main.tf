variable "do_token" {}
variable "domain" {}
variable "ipfs_nodes_count" {
  default = 1
}
variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}

resource "digitalocean_ssh_key" "default" {
  name       = "IPFS Terraform Key"
  public_key = "${file("${var.ssh_public_key_path}")}"
}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_domain" "default" {
  name       = "${var.domain}"
  ip_address = "${digitalocean_droplet.front.0.ipv4_address}"
}

resource "digitalocean_record" "default" {
  domain = "${digitalocean_domain.default.name}"
  name   = "@"
  type   = "A"
  value  = "${digitalocean_droplet.front.0.ipv4_address}"
}

resource "digitalocean_record" "gateway" {
  domain = "${digitalocean_domain.default.name}"
  name   = "gateway"
  type   = "A"
  value  = "${digitalocean_droplet.front.0.ipv4_address}"
}

data "template_file" "caddyfile" {
  template = "${file("${path.module}/Caddyfile.tpl")}"

  vars {
    upstreams = "${join(" ", formatlist("%s:8080", digitalocean_droplet.ipfs.*.ipv4_address_private))}"
  }
}

resource "digitalocean_droplet" "front" {
  image  = "ubuntu-16-04-x64"
  name   = "front-${count.index}"
  region = "fra1"
  size   = "512mb"
  count  = "${var.ipfs_nodes_count}"

  ssh_keys           = ["${digitalocean_ssh_key.default.fingerprint}"]
  private_networking = true

  provisioner "file" {
    content     = "${data.template_file.caddyfile.rendered}"
    destination = "/root/Caddyfile"
  }

  provisioner "file" {
    source      = "caddy.service"
    destination = "/etc/systemd/system/caddy.service"
  }

  provisioner "remote-exec" {
    inline = [
      "curl https://getcaddy.com | bash",
      "systemctl start caddy",
    ]
  }
}

resource "digitalocean_droplet" "ipfs" {
  image              = "ubuntu-16-04-x64"
  name               = "ipfs-${count.index}"
  region             = "fra1"
  size               = "2gb"
  ssh_keys           = ["${digitalocean_ssh_key.default.fingerprint}"]
  private_networking = true
  count              = 1

  provisioner "file" {
    source      = "ipfs.service"
    destination = "/etc/systemd/system/ipfs.service"
  }

  provisioner "remote-exec" {
    inline = [
      "fallocate -l 1G /swapfile",
      "chmod 600 /swapfile",
      "mkswap /swapfile",
      "swapon /swapfile",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "wget https://dist.ipfs.io/go-ipfs/v0.4.10/go-ipfs_v0.4.10_linux-amd64.tar.gz",
      "tar xfv go-ipfs_v0.4.10_linux-amd64.tar.gz",
      "cd go-ipfs/ && ./install.sh",
      "ipfs init",
      "ipfs config Addresses.Gateway /ip4/${self.ipv4_address_private}/tcp/8080",
      "systemctl start ipfs",
    ]
  }
}

output "ipfs nodes" {
  value = "${digitalocean_droplet.ipfs.*.ipv4_address}"
}

output "front nodes" {
  value = "${digitalocean_droplet.front.*.ipv4_address}"
}
