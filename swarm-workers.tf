resource "google_compute_instance" "workers" {
  count        = "${var.swarm_workers}"
  name         = "worker${count.index + 1}"
  machine_type = "${var.swarm_workers_instance_type}"
  zone         = "${var.zone}"
  tags         = ["swarm", "worker"]
  depends_on   = ["google_compute_instance.managers"]

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
  
  # join the swarm
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm join --token ${data.external.swarm_tokens.result.worker} ${google_compute_instance.managers.0.name}:2377",
    ]
  }

  # leave swarm on destroy
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "sudo docker swarm leave",
    ]

    on_failure = "continue"
  }

  # remove node on destroy
  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "sudo docker node rm --force ${self.name}",
    ]

    on_failure = "continue"

    connection {
      type = "ssh"
      user = "${var.ssh_user}"
      private_key = "${file("${var.ssh_key_file}")}"
      host = "${google_compute_instance.managers.0.network_interface.0.access_config.0.nat_ip}"
    }
  }
}