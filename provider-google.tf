provider "google" {
  credentials = "${file("${var.projectCreds}")}"
  region      = "${var.region}"
  zone        = "${var.zone}"
  project     = "${var.currentProject}"
}
