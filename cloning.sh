#!/bin/bash

pwd
echo "Enter path to clone the repo"
MY_PATH=${WORKSPACE}
cd "${WORKSPACE}"
ls
git clone https://github.com/sky-uk/dta-customer-tf
cd "${WORKSPACE}/dta-customer-tf"
echo "Enter jira branch name to be created"
read MY_BRANCH
git checkout -b "$MY_BRANCH"
git push -u origin "$MY_BRANCH"
git switch PPS_2912
echo "$MY_PATH/dta-customer-tf/batch_application/scripts/sql/temp2"
mkdir "$MY_PATH/dta-customer-tf/batch_application/scripts/sql/temp2"
cp /c/Users/pparth860/Documents/source/* "$MY_PATH/dta-customer-tf/batch_application/scripts/sql/temp2"
cd "$MY_PATH/dta-customer-tf/batch_application/scripts/sql/"
git switch PPS_2912
git add temp2
git commit -m "Adding new folder"
git push
git switch "$MY_BRANCH"
git checkout PPS_2912 "$MY_PATH/dta-customer-tf/batch_application/scripts/sql/temp2/copy.sql"
#git add customer_risk_td_risk.sql
#git show PPS_2912:dta-customer-tf/batch_application/scripts/sql/temp2/customer_risk_td_risk.sql > customer_risk_td_risk.sql
git add copy.sql
git commit -m "Adding new file from another branch"
git push
