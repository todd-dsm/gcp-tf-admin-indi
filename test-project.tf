/*
  -----------------------------------------------------------------------------
                              TERRAFORM SMOKE TEST
  -----------------------------------------------------------------------------
*/
resource "google_compute_instance" "default" {
  name         = "test"
  zone         = "${var.zone}"
  machine_type = "n1-standard-1"

  tags = ["region", "los-angeles"]

  boot_disk {
    initialize_params {
      image = "${data.google_compute_image.os_image.self_link}"
    }
  }

  // Local SSD disk
  scratch_disk {}

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  provisioner "local-exec" {
    command = "gcloud compute config-ssh"
  }
}

# Image lookup
data "google_compute_image" "os_image" {
  family  = "cos-stable"
  project = "cos-cloud"
}
