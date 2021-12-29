AUTHTKN=${!AUTHTKNVAR}
BASEURL=${!BASEURLVAR}
APIOUTFN=$(mktemp)
STATUSOUTFN=$(mktemp)
if [[ "${AUTHTKN}x" == "x" ]] ; then
    echo "Rundeck authentication token not provided, and not present in environment."
    echo "To provide this value in the environment, set ${AUTHTKNVAR}"
    exit 1
fi
if [[ "${BASEURL}x" == "x" ]] ; then
    echo "Rundeck base URL not provided, and not present in environment."
    echo "To provide this value in the environment, set ${BASEURLVAR}"
    exit 1
fi

# Get options defined on the job.
curl -fLSsg -H 'Accept: application/yaml' -H "X-Rundeck-Auth-Token: ${AUTHTKN}" \
    "${BASEURL}/18/job/${JOBID}" | yq e '.[].options[].name' - > options

# Build a curl command using the rundeck job options.
echo -n "curl -LSsg -X POST -o ${APIOUTFN} -w '%{http_code}\n'" > command
echo -n " -H 'Accept: application/json'" >> command
echo -n " -H \"X-Rundeck-Auth-Token: ${AUTHTKN}\"" >> command
for O in `cat options` ; do case $O in
    cibranch)    echo -n " --data-urlencode \"option.$O=${CIRCLE_BRANCH}\"" ;;
    cibuildnum)  echo -n " --data-urlencode \"option.$O=${CIRCLE_BUILDNUM}\"" ;;
    cicommit)    echo -n " --data-urlencode \"option.$O=${CIRCLE_SHA1:0:8}\"" ;;
    cihash)      echo -n " --data-urlencode \"option.$O=${CIRCLE_SHA1}\"" ;;
    cireponame)  echo -n " --data-urlencode \"option.$O=${CIRCLE_PROJECT_REPONAME}\"" ;;
    cirepoowner) echo -n " --data-urlencode \"option.$O=${CIRCLE_PROJECT_USERNAME}\"" ;;
    cirepourl)   echo -n " --data-urlencode \"option.$O=${CIRCLE_REPOSITORY_URL}\"" ;;
    ciprurl)     echo -n " --data-urlencode \"option.$O=${CIRCLE_PULL_REQUEST}\"" ;;
    citag)       echo -n " --data-urlencode \"option.$O=${CIRCLE_TAG}\"" ;;
    ciuser)      echo -n " --data-urlencode \"option.$O=${CIRCLE_USERNAME}\"" ;;
esac ; done >> command
echo " ${BASEURL}/18/job/${JOBID}/run" >> command

# Start the job and check for failure.
sh command > ${STATUSOUTFN}
if (( $(cat ${STATUSOUTFN}) > 399 ))
then
    echo "Request failed with status $(cat ${STATUSOUTFN})"
    jq . ${APIOUTFN}
    exit 1
fi

# Output running job details if available.
PERMALINK="$(jq -r .permalink ${APIOUTFN})"
echo "Rundeck job is $(jq -r '.status // "unknown"' ${APIOUTFN})"
if [[ "${PERMALINK}x" == "x" ]]
then
    echo "No job link available"
else
    echo "View job: ${PERMALINK}"
fi
