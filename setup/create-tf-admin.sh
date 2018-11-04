#!/usr/bin/env bash
# shellcheck disable=SC2154
# -----------------------------------------------------------------------------
# PURPOSE:  1-time setup (per-project) for the terraform admin-credentials
#           account type: individual
#           Some controls are necessary at the Organization and project level.
# -----------------------------------------------------------------------------
#    EXEC:  setup/create-tf-admin.sh
# -----------------------------------------------------------------------------
set -x

###----------------------------------------------------------------------------
### VARIABLES
###----------------------------------------------------------------------------
declare -r svcAcctName='terraform'
serviceEmail="${svcAcctName}@${TF_VAR_currentProject}.iam.gserviceaccount.com"
# TARGET FORMAT:   terraform@projectName.iam.gserviceaccount.com
serviceAccount="serviceAccount:${serviceEmail}"
declare -a envVARs=('TF_VAR_currentProject' 'TF_VAR_projectCreds'
    'TF_VAR_billing_account')
declare -a gcpRoles=('viewer' 'storage.admin' 'compute.instanceAdmin.v1'
    'iam.serviceAccountKeyAdmin')
declare -a projAPIs=('cloudresourcemanager' 'cloudbilling' 'iam' 'compute')
#declare -a orgPerms=('resourcemanager.projectCreator' 'billing.user')


###----------------------------------------------------------------------------
### FUNCTIONS
###----------------------------------------------------------------------------
function pMsg() {
    theMessage="$1"
    printf '%s\n' "$theMessage"
}

###----------------------------------------------------------------------------
### MAIN
###----------------------------------------------------------------------------
### Check some basic assumptions
###---
printf '\n\n%s\n' "Verifying all ENV variables are available..."
for reqdVar in "${envVARs[@]}"; do
    if [[ -z "${!reqdVar}" ]]; then
        pMsg "$reqdVar is not set; exiting."
        exit 1
    else
        pMsg "  * $reqdVar = ${!reqdVar}"
    fi
done

# Success
pMsg "All required variables check-out; advancing to the next step."


###---
### Link billing and set project as default
###---
### Link the Admin project space to the billing account
gcloud beta billing projects link "$TF_VAR_currentProject" \
    --billing-account "$TF_VAR_billing_account"

### set project as default for now
gcloud config set project "$TF_VAR_currentProject"


###---
### Create the Terraform service account in the project and
### download the JSON credentials
###---
pMsg "Creating 'terraform' service-account..."
gcloud iam service-accounts create "$svcAcctName" \
    --display-name "Terraform admin account for $USER"

pMsg "Creating keys for 'terraform' service-account..."
gcloud iam service-accounts keys create "$TF_VAR_projectCreds" \
    --iam-account "$serviceEmail"


###---
### Grant the service account permission to:
###   * view the Admin Project, and
###   * manage Cloud Storage
###---
printf '\n\n%s\n' "Granting roles to $serviceEmail..."
for adminRole in "${gcpRoles[@]}"; do
    gcloud projects add-iam-policy-binding "$TF_VAR_currentProject" \
        --member "$serviceAccount" \
        --role   "roles/${adminRole}"
    pMsg "  * $adminRole"
done


###---
### Enable the APIs
### Any action taken by Terraform (under the TF_VAR_currentProject with serviceAccount)
### requires requisite APIs are enabled.
###---
printf '\n\n%s\n' "Enabling required APIs for $TF_VAR_currentProject..."
for adminAPI in "${projAPIs[@]}"; do
    gcloud services enable "${adminAPI}.googleapis.com"
    pMsg "  * $adminAPI"
done


###---
### Add organization/folder-level permissions FIX?
### Grant the serviceAccount permission to:
###   * create projects, and
###   * assign billing accounts
###---
#printf '\n\n%s\n' "Adding organization/folder-level permissions for $TF_ADMIN..."
#for adminPerms in "${orgPerms[@]}"; do
#    gcloud organizations add-iam-policy-binding \
#        --member "$serviceAccount" \
#        --role "roles/${adminPerms}"
#    pMsg "  * $adminPerms"
#done


###---
### Setup Terraform state storage
###---
printf '\n\n%s\n' "Creating a bucket for remote terraform state..."
gsutil mb -p "$TF_VAR_currentProject" "gs://${TF_VAR_currentProject}"

cat > backend.tf <<EOF
/*
  -----------------------------------------------------------------------------
                           CENTRALIZED HOME FOR STATE
                           inerpolations NOT allowed
  -----------------------------------------------------------------------------
*/
terraform {
  backend "gcs" {
    bucket  = "$TF_VAR_currentProject"
    project = "$TF_VAR_currentProject"
    prefix  = "terraform/state"
  }
}
EOF


###---
### Enable storage versioning
###---
gsutil versioning set on "gs://${TF_VAR_currentProject}"
gsutil iam ch "${serviceAccount}:objectCreator" "gs://${TF_VAR_currentProject}"


###---
### Export the goodies
###---
export GOOGLE_APPLICATION_CREDENTIALS="$TF_VAR_projectCreds"
export GOOGLE_PROJECT="$TF_VAR_currentProject"
export TF_VAR_project_name="$TF_VAR_currentProject"


###---
### fin~
###---
exit 0

