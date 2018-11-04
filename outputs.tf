/*
  -----------------------------------------------------------------------------
                                     OUTPUTS
  -----------------------------------------------------------------------------
*/
output "build_info" {
  value = "successfully bootstrapped! ${data.google_compute_image.os_image.name}"
}

output "ssh_info " {
  value = "ssh ${google_compute_instance.default.name}.${var.zone}.${var.currentProject}"
}

output "private_address" {
  value = "${google_compute_instance.default.network_interface.0.network_ip}"
}

output "public_address" {
  value = "${google_compute_instance.default.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "further_configuration" {
  value = "READ: https://cloud.google.com/sdk/gcloud/reference/compute/config-ssh"
}
