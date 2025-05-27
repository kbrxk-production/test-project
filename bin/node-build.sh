#! /bin/bash

set -e

echo -e "${BLUE}FINAL_NAME=${NORMAL}${FINAL_NAME}"
echo -e "${BLUE}ARTIFACT_NAME=${NORMAL}${ARTIFACT_NAME}"
echo -e "${BLUE}PACKAGING=${NORMAL}${PACKAGING}"
echo -e "${BLUE}OUTPUT_DIR=${NORMAL}${OUTPUT_DIR}"

node -v
rm -rf node_modules

cat > .npmrc << EOF
registry=https://${NODE_REPOSITORY_HOST}
//${NODE_REPOSITORY_HOST}/:_authToken="${NODE_REPOSITORY_TOKEN}"
EOF

npm config set cache .npm

[ "${LOG_LEVEL}" = "DEBUG" ] && VERBOSE="-verbose"
printf "%snpm ci --omit=dev %s%s\n" "${GREEN}" "${VERBOSE}" "${NORMAL}"
npm ci --omit=dev ${VERBOSE} || ERROR=1

if [ "${BUILD_TOOL}" = "nest" ]; then
    npx -y -p @nestjs/cli@$(node -pe "require('./package.json').devDependencies['@nestjs/cli']") \
        nest build
fi

ls -l

mkdir -p "${ARTIFACT_PATH}"
printf "%s$ tar -zcf ${FINAL_NAME} node_modules package.json package-lock.json ${OUTPUT_DIR}%s\n" "${GREEN}" "${NORMAL}"
tar -zcf ${FINAL_NAME} node_modules package.json package-lock.json ${OUTPUT_DIR}

# if [[ "${DEPLOYABLE}" == "true" ]]; then
#   echo -e "${GREEN}Publicando artefactos${NORMAL}"
#   npm config set registry "${NEXUS_URL}/repository/${SNAPSHOT_REPOSITORY}"
#   # Hint para generar token: npm login --registry ${NEXUS_URL}/repository/${SNAPSHOT_REPOSITORY} --cafile=/tmp/nexus.pem
#   echo "${NEXUS_URL}/repository/:_authToken=${NEXUS_NPM_TOKEN}" | sed -e "s|http[s]*:||g" | tee -a ~/.npmrc
#   npm publish
# fi
