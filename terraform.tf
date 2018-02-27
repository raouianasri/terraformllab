resource "google_compute_instance_template" "instance-template-apache" {
  name         = "instance-template-apache" # Nom
  machine_type = "n1-standard-1"            # Taille de la machine
  region       = "northamerica-northeast1"  # Zone

  disk {
    source_image = "debian-cloud/debian-8" # Disque
    boot         = true
    auto_delete  = true
  }

  metadata_startup_script = "sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y install apache2 && sudo systemctl start apache2"

  network_interface {
    subnetwork    = "${google_compute_subnetwork.cr460-subnet1.self_link}" # Interface Reseau
    access_config = {}
  }

  tags = ["web", "patate", "cr460", "linux"]
}

resource "google_compute_instance_group_manager" "instance_group" {
  name = "instance-group"

  base_instance_name = "instance"
  instance_template  = "${google_compute_instance_template.instance-template-apache.self_link}"
  update_strategy    = "NONE"
  zone               = "northamerica-northeast1-a"

  target_size = 3
}

resource "google_compute_autoscaler" "autoscaler" {
  name   = "scaler"
  zone   = "northamerica-northeast1-a"
  target = "${google_compute_instance_group_manager.instance_group.self_link}"

  autoscaling_policy = {
    max_replicas    = 10
    min_replicas    = 1
    cooldown_period = 15

    cpu_utilization {
      target = 0.2
    }
  }
}

#Definition du sous-reseau
resource "google_compute_subnetwork" "cr460-subnet1" {
  name          = "cr460-subnet1"                             # Nom
  ip_cidr_range = "10.0.0.0/24"                               # Adresse IP
  network       = "${google_compute_network.cr460.self_link}" # Liens vers le reseau
  region        = "northamerica-northeast1"                   # Region
}

# Definition du VPC
resource "google_compute_network" "cr460" {
  name                    = "cr460" # Nom du reseau
  auto_create_subnetworks = "false"
}

resource "google_compute_firewall" "http" {
  name    = "http"
  network = "${google_compute_network.cr460.name}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags = ["web"]
}

resource "google_compute_firewall" "ssh" {
  name    = "ssh"
  network = "${google_compute_network.cr460.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["linux"]
}

# Definir le fournisseur nuagique
provider "google" {
  credentials = "${file("account.json")}"
  project     = "cr460-cours6"
  region      = "northamerica-northeast1"
}
