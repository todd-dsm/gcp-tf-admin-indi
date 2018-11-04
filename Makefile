#!/usr/bin/env make
# vim: tabstop=8 noexpandtab

# Grab some ENV stuff
newClusterName	?= $(shell $(newClusterName))
planFile	?= $(shell $(planFile))

# Start Terraforming
tf-init:
	terraform init -get=true

plan: tf-init
	terraform plan -no-color \
		-out=$(planFile) 2>&1 | tee /tmp/tf-$(newClusterName)-plan.out

apply: 
	terraform apply --auto-approve -no-color \
		-input=false "$(planFile)" 2>&1 | tee /tmp/tf-$(newClusterName)-apply.out

clean: ## Destroy existing resources, current build, and all generated files
	terraform destroy --force -auto-approve -no-color 2>&1 | \
		tee /tmp/tf-$(newClusterName)-destroy.out
	rm -f "$(planFile)"
	rm -rf .terraform
	gcloud compute config-ssh --remove

