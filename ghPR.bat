"${WORKSPACE}"/gh auth login -h github.com --with-token < GH_token.txt
"${WORKSPACE}"/gh pr create --head "$MY_BRANCH" --title "$PRtitle" --body "$PRbody" --draft
