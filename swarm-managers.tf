resource "google_compute_instance" "managers" {
  count        = "${var.swarm_managers}"
  name         = "manager"
  machine_type = "${var.swarm_managers_instance_type}"
  zone         = "${var.zone}"
  tags         = ["swarm", "manager"]
  depends_on   = ["google_compute_firewall.swarm-internet", "google_compute_firewall.swarm-internal"]

  boot_disk {
    initialize_params {
      image = "${var.image_name}"
      size  = 100
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }

  network_interface {
    network       = "${google_compute_network.swarm.name}"
    access_config {}
  }

  connection {
    type = "ssh"
    host = "${self.network_interface.0.access_config.0.nat_ip}"
    user = "${var.ssh_user}"
    private_key = "${file("${var.ssh_key_file}")}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl stop packagekit && sudo systemctl stop packagekit",
      "curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh | sudo sh",
      "curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh | sudo sh",
      "curl -fsSL 'https://get.docker.com/' | sudo sh",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo docker swarm init --advertise-addr ${self.network_interface.0.network_ip}",
    ]
  }
}

data "external" "swarm_tokens" {
  program = ["${path.module}/fetch-tokens.sh"]

  query = {
    host = "${google_compute_instance.managers.0.network_interface.0.access_config.0.nat_ip}"
    user = "${var.ssh_user}"
    key  = "${var.ssh_key_file}"
  }

  depends_on = ["google_compute_instance.managers"]
}