#!/bin/bash

# Get commandline arguments
while (( "$#" )); do
  case "$1" in
    --project)
      project="${2}"
      shift
      ;;
    --instance)
      instance="${2}"
      shift
      ;;
    --location)
      location="${2}"
      shift
      ;;
    --destroy)
      flagDestroy="true"
      shift
      ;;
    --dry-run)
      flagDryRun="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

### Check input

# Project
if [[ $project == "" ]]; then
  echo -e "Project [--project] is not provided!\n"
  exit 1
fi

# Instance
if [[ $instance == "" ]]; then
  echo -e "Instance [--instance] is not provided!\n"
  exit 1
fi

# Location
if [[ $location == "" ]]; then
  location="westeurope"
  echo -e "Location [--location] is not provided. Using default location ${location}.\n"
fi

if [[ $flagDestroy != "true" ]]; then

  # Initialize Terraform
  terraform -chdir=../terraform init -upgrade

  # Plan Terraform
  terraform -chdir=../terraform plan \
    -var project=$project \
    -var instance=$instance \
    -var location=$location \
    -var newrelic_otlp_endpoint="https://otlp.eu01.nr-data.net:4317" \
    -var newrelic_license_key=$NEWRELIC_LICENSE_KEY \
    -out "./tfplan"

    if [[ $flagDryRun != "true" ]]; then
    
      # Apply Terraform
      terraform -chdir=../terraform apply tfplan
    fi
else

  # Destroy resources
  terraform -chdir=../terraform destroy \
    -var project=$project \
    -var instance=$instance \
    -var location=$location \
    -var newrelic_otlp_endpoint="https://otlp.eu01.nr-data.net:4317" \
    -var newrelic_license_key=$NEWRELIC_LICENSE_KEY
fi
