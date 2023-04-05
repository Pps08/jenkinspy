#!/bin/ksh
export DATE=`date +'%d %b %Y, %H:%M:%S'`

Release_Label=$(echo $Release_Label | sed 's/,/<br>/g;s/,\n/<br>/g')

if [ "x${Release_Label}" == "x" ]; then
  echo Release Label not provided. Exiting.
  exit 1
elif [[ "x${Tester}" == "x" || "${Tester}" == "N/A" || "${Tester}" == "n/a" ]]; then
  echo Tester must be valid. Exiting.
  exit 1
elif [[ "x${Project}" == "x" || "${Project}" == "N/A" || "${Project}" == "n/a" ]]; then
  echo Project name must be valid. Exiting.
  exit 1
elif [[ "x${Dependencies}" == "x" ]]; then
  echo Dependencies must not be null. Exiting.
  exit 1
elif [[ "$Dev_Signoff" == "--------" || "$Test_Signoff" == "--------" ]]; then
  echo Dev/Test Signoff not completed. Will not submit form. Exiting.
  exit 1
fi

##Cleaning Release Label of nonprintable characters
Release_Label=$(echo $Release_Label | tr -dc '\11\12\15\40-\176' | sed 's/<br>/\n/g')

ORIG_PROJECT=$(echo $Project | sed 's/(Test Branch)//')

for BUILD in ${Release_Label}
do

  ##Replacing line breaks with HTML tags for formatting
  export New_Description=$(echo "${Description}"                   | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_POST_DEPLOY=$(echo "${POST_DEPLOY}"                   | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Supp_Logging=$(echo "${Supp_Logging}"                 | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Job_Files=$(echo "${Job_Files}"                       | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Pop_Controls=$(echo "${Pop_Controls}"                 | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Initial_Load=$(echo "${Initial_Load}"                 | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Dependencies=$(echo "${Dependencies}"                 | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export New_Special_Instructions=$(echo "${Special_Instructions}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' )
  export Jira_Issue_Number BUILD GCP_json_File Developer Tester Project  
  
  echo Checking build name is valid...
  build_check=$(echo $BUILD | egrep "^[[:alpha:]]{4,}-[[:digit:]]{6}_[[:digit:]]{2}_[[:digit:]]{2}$"\|"^[[:alpha:]].*[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]].*[[:digit:]]$"\|"^[[:alpha:]].*[-|_][[:digit:]]{1}[_|.][[:digit:]]{1,2}[_|.][[:digit:]]{3}$"\|"^AB_"\|"^MOB2-"\|"^QA_CMD.*[[:digit:]]{2}[-|_][[:digit:]]{2}[-|_][[:digit:]]{3}$")
  if [ "x${build_check}" != "x" ]; then
    echo Build $BUILD is good - will add to DEPLOYMENTTRACKER DB
    echo
    echo Checking DeploymentTracker for ${BUILD}..
    print "select BUILDNO from DEPLOYMENTTRACKER where BUILDNO = '${BUILD}';" > sqlfile_$$.sql
    print "exit;" >> sqlfile_$$.sql

    sqlplus -s dw_tester/dw_tester@DWH011T @sqlfile_$$.sql > build_provision.$$
 
    grep ${BUILD} build_provision.$$ > /dev/null
    if [ $? -ne 0 ]; then
      echo updating DeploymentTracker for ${BUILD}
      print "SET DEFINE OFF" > sqlfile_$$.sql
      print "insert into DEPLOYMENTTRACKER (" >> sqlfile_$$.sql
      print "ID, BUILDNO_JIRA, BUILDNO, GCP_JSON, QUARANTINE, BUILDNOTES, ADDJOBTOBATCH," >> sqlfile_$$.sql
      print "SUPPLOGGING, POPCONTROLS, DEVELOPER, TESTER, PROJECT, INITIALLOAD, DEPENDENCIES" >> sqlfile_$$.sql
      print ")" >> sqlfile_$$.sql
      print "values (" >> sqlfile_$$.sql
      print "deploymenttracker_id.nextval, '${Jira_Issue_Number}', '${BUILD}', '${GCP_json_File}', 'N'," >> sqlfile_$$.sql
      print "q'[${New_Description}]', 'N', q'[${New_Supp_Logging}]', q'[${New_Pop_Controls}]', '${Developer}'," >> sqlfile_$$.sql
      print "'${Tester}', q'[${Project}]', q'[${New_Initial_Load}]', q'[${New_Dependencies}]');" >> sqlfile_$$.sql
    else
      echo "${BUILD} has already been added to the DEPLOYMENTTRACKER Table. Updating record."
      print "SET DEFINE OFF" > sqlfile_$$.sql
      print "update DEPLOYMENTTRACKER" >> sqlfile_$$.sql
      print "set BUILDNO_JIRA = '${Jira_Issue_Number}', GCP_JSON = '${GCP_json_File}', QUARANTINE = 'N'," >> sqlfile_$$.sql
      print "BUILDNOTES = q'[${New_Description}]', ADDJOBTOBATCH = 'N', SUPPLOGGING = q'[${New_Supp_Logging}]'," >> sqlfile_$$.sql
      print "POPCONTROLS = q'[${New_Pop_Controls}]', DEVELOPER = '${Developer}', TESTER = '${Tester}'," >> sqlfile_$$.sql
      print "PROJECT = q'[${Project}]', INITIALLOAD = q'[${New_Initial_Load}]', DEPENDENCIES = q'[${New_Dependencies}]'" >> sqlfile_$$.sql
      print "where BUILDNO = '${BUILD}';" >> sqlfile_$$.sql
    fi
    if [ "x$(echo $JOB_NAME | grep DEV)" == "x" ]; then
      print "commit;" >> sqlfile_$$.sql
    else
      print "rollback;" >> sqlfile_$$.sql
    fi
    print "exit;" >> sqlfile_$$.sql

    sqlplus -s dw_tester/dw_tester@DWH011T @sqlfile_$$.sql > tracker.$$
    egrep 'ORA-|SP2-' tracker.$$ > /dev/null
    if [ $? -eq 0 ]; then
  	  echo Error adding record. Please review output below:
      cat tracker.$$ build_provision.$$;rm tracker.$$ sqlfile_$$.sql build_provision.$$ 2>/dev/null
      RET=1
      exit $RET
    else
      rm tracker.$$ sqlfile_$$.sql build_provision.$$ 2>/dev/null
    fi
    rm build_provision.* 2>/dev/null
  else
    echo Build $BUILD is non-standard, so will just release Dev Email comms.
    Project="${ORIG_PROJECT} (Test Branch)"
  fi
done 


##Let's sort out test/dev signoff
MailTo_Email=$(egrep '^MailTo' ${WORKSPACE}/Email_D2T.list | cut -d: -f2),${BUILD_USER_EMAIL}
Dev_Email=$(grep "$Dev_Signoff" ${WORKSPACE}/Email_D2T.list | cut -d, -f2)
Test_Email=$(grep "$Test_Signoff" ${WORKSPACE}/Email_D2T.list | cut -d, -f2)

###
# Email build based on information provided
###
# Let's capture the given information into a readable format
QG_DATA=${WORKSPACE}/QG_form_data.txt

echo "Clarity Code:${Clarity_Code}" > ${QG_DATA}
echo "JIRA Issue Number:${Jira_Issue_Number}" >> ${QG_DATA}
echo "Build Number(s):${Release_Label}" | sed -rz 's/^(.*)\n/\1<BR>/; s/[\n| ]/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "GCP .json file(s):${GCP_json_File}" | sed -e 's/ //3g' | sed 's/,/<br>/g' >> ${QG_DATA}
echo "Build Repository:${REPO_PATH}" >> ${QG_DATA}
echo "Unit Test SharePoint Location:${Unit_Test_SharePoint_Location}" >> ${QG_DATA}
echo "Confluence Analysis doc location:${Confluence_Location}" >> ${QG_DATA}
echo "Description:${Description}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Supplemental Logging Details:${Supp_Logging}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo ".scr/.sql files:${Job_Files}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA} 
echo "Pop control files:${Pop_Controls}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Deploy command/job:${DEPLOY_COMMAND}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Post-deploy commands:${New_POST_DEPLOY}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Developer:${Developer}" >> ${QG_DATA}
echo "Tester assigned:${Tester}" >> ${QG_DATA}
echo "Project:${Project}" >> ${QG_DATA}
echo "Initial load details:${Initial_Load}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Dependencies:${Dependencies}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Special Instructions:${Special_Instructions}" | sed -rz 's/^(.*)\n/\1<BR>/; s/\n/<br>/g' | sed -z 's/<BR>/\n/' >> ${QG_DATA}
echo "Developer Signoff:${Dev_Signoff}" >> ${QG_DATA}
echo "Dev Walkthrough Date:${Walkthrough_Date}" >> ${QG_DATA}
echo "Tester Signoff:${Test_Signoff}" >> ${QG_DATA}

#escaping backslashes
sed -i 's/\\/\\\\/g' $QG_DATA
#removing erroneously formatted hypens
sed -i 's/â€“/-/g' $QG_DATA
#escaping angled brackets, coz HTML
sed -i 's#<br>#||||||||#g' $QG_DATA
sed -i 's#<#\\<#g' $QG_DATA
sed -i 's#>#\\>#g' $QG_DATA
sed -i 's#||||||||#<br>#g' $QG_DATA
 
QG_DATA_FINAL=${WORKSPACE}/QG_form_formatted.txt
if [ -f $QG_DATA_FINAL ]
then
  rm $QG_DATA_FINAL
fi
while read line
do
  email_title=$(echo $line | cut -d':' -f1)
  email_detail=$(echo "$line" | cut -d':' -f2-)
  echo "<tr>" >> $QG_DATA_FINAL
  echo "<td style=\"border: 1px solid black; width: 15%;\" align=\"center\"><strong>$email_title</strong></td>" >> $QG_DATA_FINAL
  echo "<td style=\"border: 1px solid black;\" align=\"left\">$email_detail</td>" >> $QG_DATA_FINAL
  echo "</tr>" >> $QG_DATA_FINAL
done < ${QG_DATA}

## Let's build a content file for emailing...
QG_EMAIL=${WORKSPACE}QG_Email.txt
echo "<tr style=\"color: black; background-color: yellow; font-size: small; margin: 0; padding: 0.25em; text-align: center;\">" > ${QG_EMAIL}
echo "  <td style=\"border: 1px solid black;\" colspan=2>" >> ${QG_EMAIL}
echo "    <p>Dev to Test QG form - ${BUILD_USER_FIRST_NAME} ${BUILD_USER_LAST_NAME}: ${Project}</p>" >> ${QG_EMAIL}
echo "  </td>" >> ${QG_EMAIL}
echo "</tr>" >> ${QG_EMAIL}
 
cat ${QG_DATA_FINAL} >> ${QG_EMAIL}
echo "" >> ${QG_EMAIL}
echo "</td>" >> ${QG_EMAIL}
echo "</tr>" >> ${QG_EMAIL}

## trying to combat the 990 char limit with SMTP
sed -i 's/<br>/<br>\n/g' $QG_EMAIL



exit $?
