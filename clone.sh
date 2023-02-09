#!/bin/bash
MY_PATH=${WORKSPACE}
cd ${WORKSPACE}
GIT_USER=PPS08
GIT_TOKEN=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
GIT_API="https://$GIT_USER:$GIT_TOKEN@api.github.com"
git clone $GIT_API/orgs/Pps08/jenkinspy
