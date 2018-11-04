/*
  -----------------------------------------------------------------------------
                             Initialize/Declare Variables
  -----------------------------------------------------------------------------
*/
variable "region" {
  description = "Deployment Region; from ENV; E.G.: us-west2"
  type        = "string"
}

variable "zone" {
  description = "Deployment Zone(s); from ENV; E.G.: us-west2-a"
  type        = "string"
}

variable "currentProject" {
  description = "Currently configured project ID; from ENV; E.G.: My First Project"
  type        = "string"
}

variable "projectCreds" {
  description = "Path to credentials file; from ENV; E.G.: ~/.config/gcloud/terraform.json"
  type        = "string"
}
