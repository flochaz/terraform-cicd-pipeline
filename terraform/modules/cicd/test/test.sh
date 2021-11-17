#!/bin/bash
set -e

# Run terratest
echo "installing deps"

for value in  "github.com/gruntwork-io/terratest/modules/terraform" \
   "github.com/stretchr/testify/assert" \
   "strings" \
   "testing" \
   "fmt" \
   "github.com/gruntwork-io/terratest/modules/random" \
   "github.com/gruntwork-io/terratest/modules/aws"
do
    echo "installing $value"
    go get $value
done

echo "Running Terratest"

mkdir ${BASE_PATH}/cicd/test/reports
go test ${BASE_PATH}/cicd/test/cicd_test.go -timeout 10m -v | tee ${BASE_PATH}/cicd/test/reports/test_output.log
retcode=${PIPESTATUS[0]}

echo "Creating Logs"
terratest_log_parser -testlog ${BASE_PATH}/cicd/test/reports/test_output.log -outputdir ${BASE_PATH}/cicd/test/reports

exit ${retcode}