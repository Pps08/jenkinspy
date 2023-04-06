#!/bin/bash

# Enter your GitHub repository URL
REPO_URL="https://github.com/Pps08/jenkinspy.git"

# Enter the path to your PPK file
PPK_FILE="C:\Users\pps08\.gcp_putty_ssh\id_rsa.ppk" 

# Enter the username and IP address of the remote server
USERNAME="priya_parthasarathy_sky_uk"
IP_ADDRESS="customer-tf-compute-dev"

# Enter the path where you want to clone your repository on the remote server
REMOTE_PATH="/home/priya_parthasarathy_sky_uk"

# Clone the repository from GitHub
git clone $REPO_URL

# Copy the repository to the remote server using the PPK file for authentication
pscp -i $PPK_FILE -r yourrepository $USERNAME@$IP_ADDRESS:$REMOTE_PATH
