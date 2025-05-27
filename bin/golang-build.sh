#!/bin/bash

set -e

OUTPUT_DIR=bin
printf "${BLUE}OUTPUT_DIR=${NORMAL}$OUTPUT_DIR\n"

rm -rf vendor
printf "${GREEN}$ make all${NORMAL}\n"
make all
printf "${GREEN}$ go list ./...${NORMAL}\n"
go list ./...

# Preparando empaquetado
ls -la *
find vendor -type f -not -name '*.go' -delete
printf "${GREEN}tar -zcf ${FINAL_NAME} -C ${OUTPUT_DIR} ${ARTIFACT_NAME}-${ARTIFACT_VERSION}${NORMAL}\n"
tar -zcf ${FINAL_NAME} -C ${OUTPUT_DIR} ${ARTIFACT_NAME}-${ARTIFACT_VERSION}

#   if [[ "${DEPLOYABLE}" == "true" ]]; then
#     echo -e "${GREEN}Publicando artefactos${NORMAL}"
#     curl -k -s -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} --upload-file ${FINAL_NAME} \
#     ${NEXUS_URL}/repository/${SNAPSHOT_REPOSITORY}/${GROUP_NAME}/${ARTIFACT_NAME}/${PUBLISH_VERSION}/$(basename ${FINAL_NAME})
#   fi
