username='priya_parthasarathy_sky_uk'
hostname='10.53.88.219'
PPK_FILE="C:\Users\pps08\.gcp_putty_ssh\id_rsa.ppk" 
SSH_FILE="C:\Users\pps08\.gcp_putty_ssh\ssh.txt" 
#puttygen_path="C:\Program Files\PuTTY\puttygen.exe"
#"$puttygen_path" "$ppk_file" -O private-openssh -o "$SSH_FILE"
#puttygen $PPK_FILE -O private-openssh -o $SSH_KEY_FILE
command="/apps/release_manager/batch_application/scripts/scr/build_application.sh -rep dta-customer-tf -cfg BBR-398_tf-202303_01.json -replace -branch BBR-398"
#putty.exe -ssh $username@$hostname -i $PPK_FILE "ls -la
#ssh -i $PPK_FILE $username@$hostname " rm -r /home/$username/archive/releases/* ;/apps/release_manager/batch_application/scripts/scr/build_application.sh -rep dta-customer-tf -cfg BBR-399_tf-202303_01.json -replace -branch BBR-399"
#ssh -i $PPK_FILE $username@$hostname "pwd"
ssh -i $SSH_FILE $username@$hostname "
if [ -d ""/home/$username/archive/releases/*"" ]
then
	rm -r /home/$username/archive/releases/* ;$command
else
	$command
fi"