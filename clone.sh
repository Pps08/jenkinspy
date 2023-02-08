#!/bin/bash
MY_PATH=${WORKSPACE}
cd "${WORKSPACE}"
ssh -T -p 443 git@ssh.github.com
git clone ssh://git@ssh.github.com:443/Pps08/jenkinspy.git
cd "${WORKSPACE}/dta-customer-tf"
