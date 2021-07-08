#!/bin/bash
set -e

# Run terratest
echo "Running Terratest"
go get "github.com/gruntwork-io/terratest/modules/terraform" \
   "github.com/stretchr/testify/assert" \
   "strings" \
   "testing" \
   "fmt" \
   "github.com/gruntwork-io/terratest/modules/random" \
   "github.com/gruntwork-io/terratest/modules/aws"

mkdir ${BASE_PATH}/hello_world/test/reports
go test ${BASE_PATH}/hello_world/test/terraform_hello_world_example_test.go -timeout 10m -v | tee ${BASE_PATH}/hello_world/test/reports/test_output.log
retcode=${PIPESTATUS[0]}

echo "Creating Logs"
terratest_log_parser -testlog ${BASE_PATH}/hello_world/test/reports/test_output.log -outputdir ${BASE_PATH}/hello_world/test/reports

exit ${retcode}