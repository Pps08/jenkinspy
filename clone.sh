#!/bin/bash
MY_PATH=${WORKSPACE}
cd "${WORKSPACE}"
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
git clone ssh://git@ssh.github.com:443/Pps08/jenkinspy.git
cd "${WORKSPACE}/dta-customer-tf"
