# This file is created by ../write-subdomains.sh, don't change manually

resource "digitalocean_record" "ipfs-website-txt" {
	domain = "${digitalocean_domain.default.name}"
	type = "TXT"
	name = "ipfs-website"
	value = "dnslink=/ipfs/QmPCawMTd7csXKf7QVr2B1QRDZxdPeWxtE4EpkDRYtJWty"
}
resource "digitalocean_record" "ipfs-website-a" {
	domain = "${digitalocean_domain.default.name}"
	type = "A"
	name = "ipfs-website"
	value = "${digitalocean_droplet.front.0.ipv4_address}"
}
