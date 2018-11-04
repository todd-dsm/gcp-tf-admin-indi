# gcp-tf-admin-indi

 This is based on a great piece, [Managing GCP Projects with Terraform], by the community. Unfortunately it's:
* matured and not all the steps work as expected.
* definitely made for Business accounts.

As a result, had a weird time auth'ing Terraform to build stuff; thought I would save others the first few steps.


## Before you begin
There are 2 types of accounts in the GCP world:
* Individual
* Business (organizational hierarchy)

This walk-through assumes you already have a GCP account for an _Individual_ with billing already setup. 
* If not, [sign up] now.
* If you have a Business account, use the [gcp-tf-admin-setup] instead.

This walk-through assumes a POSIX-like workstation; either macOS or Linux.

It assumes the first (admin) user is configured, authenticated and authorized to perform the first few steps.

_You_ can assume that I'm just starting out and, therefore, this is a very narrow view of the world and, in all likelihood, there is a better way to solve.


# Leftovers
When this is over you should have a few things, a:
* quick test for Terraform credentials and access
* build pattern which, I'm not proud of but, illustrates a flow.
* templated setup for quick building


## Pregame
* You _**must**_ have a GCP account
* You _**must**_ have a payment type input (debit/credit card)
* That project must be configured in the shell with `gcloud`
* You _**must**_ be authenticated with `gcloud`

_**NOTE:**_ think about the names you assign to projects; they shouldn't be too revealing.

# Installs
To get going, we need a few things:

[Homebrew] after all, we're not savages.

`brew cask install --force google-cloud-sdk`

`brew install terraform`

[gsutil] for managing Google Storage from the CLI

The configurations are coming soon to the wiki; not there yet.


## Do the Work

_**NOTES:**_ 
* this should be done in 1 shell._ `;-)`
* if you see anything weird, check the issues in this repo, even the closed ones.
 
`git clone git@github.com:todd-dsm/gcp-tf-admin-indi.git && cd gcp-tf-admin-indi/`

**Source-in your env vars by passing an argument to the script. The argument is your deployment environment; E.G.: stag, prod, etc** 

`source setup/env-vars.sh stage`

This file will discover your Project ID, Billing ID and other relevant details. Check the output. If the Project is not configured in the terminal and Billing is not setup in the WebUI do that now and re-run the step above or subsequent steps _will_ exit.


**Run the script**

`setup/create-tf-admin.sh 2>&1 | tee /tmp/create-tf-admin.out`

`set -x` is turned on; you'll be able to see all the gory details on-screen and in the log.

Now your admin user `user@domain.tld` account is associated with a service account and you can run Terraform with it.

`cat ~/.config/gcloud/tf-{TF_VAR_currentProject}.json` to see the service account details.

There seems to be a bug in `gcloud` and it will not recognize the `GOOGLE_APPLICATION_CREDENTIALS` value from the export at the end of the script. Just drop it in your `~/.bashrc` file:  (example)

```
grep GOOGLE ~/.bashrc
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/tf-myProjectID.json"
```

and source it in: `source ~/.bashrc`. for some reason that's the only way it will work.


## Terraform

For reasons you'll come to find on your own, the Terraform bits have been abstracted away to a `Makefile`. To run it:

**Initialize**

```
$ make tf-init 
terraform init -get=true

Initializing the backend...

Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "google" (1.19.1)...
- Downloading plugin for provider "random" (2.0.0)...
...
* provider.google: version = "~> 1.19"
* provider.random: version = "~> 2.0"
...
Terraform has been successfully initialized!
```

**Plan**

```
$ make plan
...
terraform plan -no-color \
	-out=/tmp/kubes-stage-la.plan 2>&1 | tee /tmp/tf-stage-la-plan.out
Acquiring state lock. This may take a few moments...
Refreshing Terraform state in-memory prior to plan...
...
------------------------------------------------------------------------

This plan was saved to: /tmp/kubes-stage-la.plan

To perform exactly these actions, run the following command to apply:
    terraform apply "/tmp/kubes-stage-la.plan"
```

**Apply**

```
$ make apply
...
terraform apply --auto-approve -no-color \                                 
    -input=false /tmp/kubes-stage-la.plan 2>&1 | tee /tmp/tf-stage-la-plan.out
```

This will apply the plan, create a log of the proceedings and store state in the bucket; it takes about 20 seconds. To see the backup:

```
$ gsutil ls -r gs://tester-01-yo
gs://tester-01-yo/terraform/:

gs://tester-01-yo/terraform/state/:
gs://tester-01-yo/terraform/state/default.tfstate  <-- your state!
```

**Destroy** the Terraformed configuration

This will destroy remote resources from GCP, sync the state again and remove local stuff; it takes about 15 seconds.

``` 
terraform destroy --force -auto-approve 2>&1 | \
	tee /tmp/tf-stage-la-destroy.out

Destroy complete!
rm -f "/tmp/kubes-stage-la.plan"
rm -rf .terraform
```

## Afterwards

You're left with a _project-specific_ Terraform service account that you can use to build stuff. That service account is empowered to do most everything it needs to. If not, it's generally a matter of enabling more APIs.

Effectively, you're ready to start terraforming.


[gsutil]:https://cloud.google.com/storage/docs/gsutil_install
[Homebrew]:https://brew.sh/
[Managing GCP Projects with Terraform]: https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
[sign up]: https://cloud.google.com/free/
[gcp-tf-admin-setup]: https://github.com/todd-dsm/gcp-tf-admin-setup