#!/bin/bash
#"Cloning the repo locally"
cd ${WORKSPACE}
git clone https://02b772a70f3c23e41d2231adec6778ac392cebd4@github.com/sky-uk/dta-customer-tf.git
cd "${WORKSPACE}/dta-customer-tf"
#"Create a temp branch from dev branch and add code to it"
echo "Enter temp branch name to be created"
git branch "$temp_branch" develop
git push -u origin "$temp_branch"
git switch "$temp_branch"
mkdir "${WORKSPACE}/dta-customer-tf/batch_application/scripts/sql/temp2"
cd "${WORKSPACE}/dta-customer-tf/batch_application/scripts/sql/temp2"
touch test1.sql
echo "Adding first file" > test1.sql
touch test2.sql
echo "Adding second file" > test2.sql
#cd "${WORKSPACE}/dta-customer-tf/batch_application/scripts/sql/"
git add .
git commit -m "Adding new folder"
git push origin "$temp_branch"
#"Create jira branch from latest dev  and add temp branch code into it"
echo "Enter jira branch name to be created"
git branch "$MY_BRANCH" develop
git push -u origin "$MY_BRANCH"
git switch "$MY_BRANCH"
echo "Enter absolute path of the script to be merged into jira branch"
git checkout "$temp_branch" "${WORKSPACE}/dta-customer-tf/$My_file"
#git checkout "$temp_branch" "${WORKSPACE}/dta-customer-tf/batch_application/scripts/sql/temp2/test1.sql"
echo "${WORKSPACE}/dta-customer-tf/$My_file"
#git checkout "$temp_branch" "${WORKSPACE}/$My_file"
git add .
git commit -m "Adding new file from temp branch"
git push origin "$MY_BRANCH"
#Merge temp branch into jira branch
git switch "$MY_BRANCH"
git merge "$temp_branch" -m "Merge branches"
git push origin "$MY_BRANCH" 
