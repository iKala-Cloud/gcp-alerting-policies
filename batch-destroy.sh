#!/bin/bash

set -e

cd terraform/deploy-2
terraform destroy

cd -

cd terraform/deploy-1
terraform destroy
