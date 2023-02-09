#!/bin/bash
MY_PATH=${WORKSPACE}
cd ${WORKSPACE}
GIT_USER=SVC-DTO-GH-RO
GIT_TOKEN=02b772a70f3c23e41d2231adec6778ac392cebd4
GIT_API="https://$GIT_USER:$GIT_TOKEN@api.github.com"
git clone $GIT_API/orgs/Pps08/jenkinspy
