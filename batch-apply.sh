#!/bin/bash

set -e

cd terraform/deploy-1
terraform init
terraform apply

cd -

cd terraform/deploy-2
terraform init
terraform apply
