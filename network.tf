resource "google_compute_network" "swarm" {
  name = "swarm-network"
}

resource "google_compute_firewall" "swarm-internal" {
  name    = "swarm-internal-firewall"
  network = "${google_compute_network.swarm.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "2377", "7946", "8080"]
  }

  allow {
    protocol = "udp"
    ports    = ["7946", "4789"]
  }

  source_ranges = ["10.128.0.0/9"]
}

resource "google_compute_firewall" "swarm-internet" {
  name    = "swarm-internet-firewall"
  network = "${google_compute_network.swarm.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080-8090"]
  }

  source_ranges = ["0.0.0.0/0"]
}

