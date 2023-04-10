#!/bin/bash
#"Cloning the repo locally"
cd "${WORKSPACE}"
#git clone https://02b772a70f3c23e41d2231adec6778ac392cebd4@github.com/Pps08/jenkinspy.git
git clone https://github.com/Pps08/jenkinspy.git
git_token='02b772a70f3c23e41d2231adec6778ac392cebd4'
cd "${WORKSPACE}/jenkinspy"
#"Create a temp branch from dev branch and add code to it"
echo "Enter temp branch name to be created"
git checkout -b "$temp_branch" main
#git push -u origin "$temp_branch"
git checkout "$temp_branch"
mkdir "${WORKSPACE}/jenkinspy/temp2"
cd "${WORKSPACE}/jenkinspy/temp2"
touch test1.sql
echo "Adding first file" > test1.sql
touch test2.sql
echo "Adding second file" > test2.sql
#cd "${WORKSPACE}/jenkinspy/"
git add .
git commit -m "Adding new folder"
#git push origin "$temp_branch"
#"Create jira branch from latest dev  and add temp branch code into it"
echo "Enter jira branch name to be created"
git checkout -b "$MY_BRANCH" main
#git push -u origin "$MY_BRANCH"
git checkout "$MY_BRANCH"
echo "Enter absolute path of the script to be merged into jira branch"
git checkout "$temp_branch" "${WORKSPACE}/jenkinspy/$My_file"
#git checkout "$temp_branch" "${WORKSPACE}/jenkinspy/temp2/test1.sql"
echo "${WORKSPACE}\jenkinspy\$My_file"
#git checkout "$temp_branch" "${WORKSPACE}jenkinspy/$My_file"
git add .
git commit -m "Adding new file from temp branch"
#git push origin "$MY_BRANCH"
echo "Merging"
#Merge temp branch into jira branch
git checkout "$MY_BRANCH"
echo "merge started"
git merge "$temp_branch" -m "Merge branches"
echo "pushing to remote"
#git push origin "$temp_branch" 
#git push origin "$MY_BRANCH"
#Create Draft PR
git checkout "$MY_BRANCH"
echo "creating PR"
#echo "$(<"${WORKSPACE}\PRbody.txt")" 
PRbody=$(<"${WORKSPACE}\PRbody.txt")
#GIT_TOKEN=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
#GIT_API="https://api.github.com"
 #curl -s -L \
 # -H "Accept: application/vnd.github+json" \
 # -H "Authorization: Bearer $GIT_TOKEN"\
 # -H "X-GitHub-Api-Version: 2022-11-28" \
  #$GIT_API
#curl -u pps08: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 https://api.github.com/user
#echo $GH_TOKEN | GH_TOKEN= "${WORKSPACE}"/gh auth login --with-token
#GH_TOKEN='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'
#"${WORKSPACE}"/gh auth login
#"${WORKSPACE}"/gh auth login -h github.com --with-token < "${WORKSPACE}"/GH_Token.txt
#gh auth login -h github.com --with-token "
#ghpath= "C:\\Program Files\\GitHub CLI\\"
#cd "${WORKSPACE}"
#ls -lrt "${WORKSPACE}"
#sh "${WORKSPACE}"\\gh.exe --version
#"${WORKSPACE}"\\gh auth login --with-token < "${WORKSPACE}"\\mytoken.txt
#echo "creating Pull Request"
#"${WORKSPACE}"\\gh pr create --head "$MY_BRANCH" --title "$PRtitle" --body "$PRbody" --draft
set +u
echo "$GITHUB_TOKEN" > .githubtoken
unset GITHUB_TOKEN
#"${WORKSPACE}"\\gh auth login --with-token < .githubtoken
rm .githubtoken
