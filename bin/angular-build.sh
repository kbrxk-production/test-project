#! /bin/bash

set -e

echo -e "${BLUE}FINAL_NAME=${NORMAL}${FINAL_NAME}"
echo -e "${BLUE}ARTIFACT_NAME=${NORMAL}${ARTIFACT_NAME}"
echo -e "${BLUE}PACKAGING=${NORMAL}${PACKAGING}"
echo -e "${BLUE}OUTPUT_DIR=${NORMAL}${OUTPUT_DIR}"

node -v
npm config set cache .npm
# npm config set //${ARTIFACT_REPOSITORY_HOST}/npm/npm-proxy/:_auth=$(echo -n ${ARTIFACT_REPOSITORY_USER}:${ARTIFACT_REPOSITORY_PASS} | base64)
# npm config set registry=${ARTIFACT_REPOSITORY_URL}/npm/npm-proxy/
npm config ls
npm ci

npx -p @angular/cli@$(node -pe "require('./package.json').devDependencies['@angular/cli']") \
  ng build --configuration production --base-href . || exit 1

tar -zcf ${FINAL_NAME} ${OUTPUT_DIR} package-lock.json package.json

#   if [[ "${DEPLOYABLE}" == "true" ]]; then
#     echo -e "${GREEN}Publicando artefactos${NORMAL}"
#     echo curl -k -s -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} --upload-file ${FINAL_NAME} \
#     ${NEXUS_URL}/repository/${SNAPSHOT_REPOSITORY}/${GROUP_NAME}/${ARTIFACT_NAME}/${PUBLISH_VERSION}/$(basename ${FINAL_NAME})
#     curl -k -s -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} --upload-file ${FINAL_NAME} \
#     ${NEXUS_URL}/repository/${SNAPSHOT_REPOSITORY}/${GROUP_NAME}/${ARTIFACT_NAME}/${PUBLISH_VERSION}/$(basename ${FINAL_NAME})
#   fi
