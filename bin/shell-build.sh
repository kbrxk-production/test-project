#! /bin/bash

set -e

apt update
apt install -y curl

printf "${BLUE}LATEST_RELEASE=${NORMAL}$LATEST_RELEASE\n"

mkdir ${ARTIFACT_PATH}
if [ -n "${LATEST_RELEASE}" ] &&
   [ "${LATEST_RELEASE}" != "null" ]; then
  diffs=$(git diff --name-only v${LATEST_RELEASE}.. | xargs echo -n)

  [ "$diffs" = "" ] &&
    echo -e "${RED}No hay cambios respecto al ultimo release${NORMAL}" &&
    exit 127

  printf "${GREEN}$ Generando archivo con cambios incrementales${NORMAL}\n"
  tar --exclude=.gitlab-ci.yml \
      -zvcf ${ARTIFACT_PATH}/${CI_PROJECT_NAME}-diffs-${BUILD_NUMBER}.${PACKAGING} $diffs
fi

tar --exclude=${ARTIFACT_PATH} \
    -zcf ${ARTIFACT_PATH}/${CI_PROJECT_NAME}-full-${BUILD_NUMBER}.${PACKAGING} *

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${ARTIFACT_PATH}/${CI_PROJECT_NAME}-diffs-${BUILD_NUMBER}.${PACKAGING}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
fi
