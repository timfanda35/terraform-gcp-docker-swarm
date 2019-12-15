resource "google_compute_network" "swarm" {
  name = "swarm-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "swarm_managers" {
  name          = "swarm-managers-subnetwork"
  ip_cidr_range = "${var.swarm_managers_subnetwork}"
  region        = "${var.region}"
  network       = "${google_compute_network.swarm.self_link}"
}

resource "google_compute_subnetwork" "swarm_workers" {
  name          = "swarm-workers-subnetwork"
  ip_cidr_range = "${var.swarm_workers_subnetwork}"
  region        = "${var.region}"
  network       = "${google_compute_network.swarm.self_link}"
}

resource "google_compute_firewall" "swarm_internal_management" {
  name    = "swarm-internal-management-firewall"
  network = "${google_compute_network.swarm.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["2377", "7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["4789", "7946"]
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["swarm"]
  target_tags = ["manager"]
}

resource "google_compute_firewall" "swarm_internal_wokers" {
  name    = "swarm-internal-workers-firewall"
  network = "${google_compute_network.swarm.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["7946"]
  }

  allow {
    protocol = "udp"
    ports    = ["4789", "7946"]
  }

  allow {
    protocol = "icmp"
  }

  source_tags = ["swarm"]
  target_tags = ["worker"]
}

resource "google_compute_firewall" "swarm_public" {
  name    = "swarm-public-firewall"
  network = "${google_compute_network.swarm.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080-8090"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["swarm"]
}

