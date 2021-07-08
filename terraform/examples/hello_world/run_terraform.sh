#/bin/bash

ACTION=${1} # destroy / plan / apply


if ( [[ -z ${AWS_ACCESS_KEY_ID} ]] || [[ -z ${AWS_SECRET_ACCESS_KEY} ]] ) && [[ -z ${AWS_PROFILE} ]]; then
    echo "[ERROR] Missing AWS credentials variables"
    exit 1
fi

TFVARS_FILE="inventories/variables.tfvars"
# To use the env var AWS_PROFILE
export AWS_SDK_LOAD_CONFIG="true"

terraform init -input=false
terraform validate
retcode=$?
if [[  $retcode != 0 ]]; then 
    exit $retcode
fi

if [[ -z ${ACTION} ]]; then
    continue 
elif [[ ${ACTION} == "destroy" ]]; then
    terraform output | grep -i S3_bucket
    read -p "Confirm that you have empty the S3 bucket"
    echo "[INFO] destroy all"
    terraform destroy
    exit 0
elif [[ ${ACTION} == "plan" ]]; then
    echo "terraform plan -out plan.out"
    terraform plan -out plan.out
    retcode=$?
    if [[  $retcode != 0 ]]; then 
        exit $retcode
    fi
elif [[ ${ACTION} == "apply" ]]; then
    terraform apply plan.out
    if [[  $retcode != 0 ]]; then 
        exit $retcode
    fi
else 
    echo "[ERROR] Value not recognised"
    echo "[ERROR] ./run_terraform.sh [destroy, plan, apply]"
    exit 1
fi




