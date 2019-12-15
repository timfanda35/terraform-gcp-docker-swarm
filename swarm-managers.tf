resource "google_compute_instance" "managers" {
  count        = 1
  name         = "manager"
  machine_type = "${var.swarm_managers_instance_type}"
  zone         = "${var.zone}"
  tags         = ["swarm", "manager"]
  depends_on   = ["google_compute_subnetwork.swarm_managers", "google_compute_firewall.swarm_internal_management"]

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
    network       = "${google_compute_network.swarm.self_link}"
    subnetwork    = "${google_compute_subnetwork.swarm_managers.self_link}"
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
  program = ["${path.module}/scripts/fetch-tokens.sh"]

  query = {
    host = "${google_compute_instance.managers.0.network_interface.0.access_config.0.nat_ip}"
    user = "${var.ssh_user}"
    key  = "${var.ssh_key_file}"
  }

  depends_on = ["google_compute_instance.managers"]
}

# Manager Followers

resource "google_compute_instance" "manager-followers" {
  count        = "${var.swarm_managers - 1}"
  name         = "manager-${count.index + 1}"
  machine_type = "${var.swarm_managers_instance_type}"
  zone         = "${var.zone}"
  tags         = ["swarm", "manager"]

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
    subnetwork    = "${google_compute_subnetwork.swarm_managers.self_link}"
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
      "sudo docker swarm join --token ${data.external.swarm_tokens.result.manager} ${google_compute_instance.managers.0.name}:2377",
    ]
  }

  # leave swarm on destroy
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "sudo docker swarm leave --force",
    ]

    on_failure = "continue"
  }
}