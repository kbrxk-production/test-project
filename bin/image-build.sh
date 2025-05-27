#! /bin/sh

set -e

apk add jq

[ "${ARTIFACT_NAME}" = "standalone-pom" ] && exit 0

echo -e "${BLUE}FINAL_NAME=${NORMAL}${FINAL_NAME}"
echo -e "${BLUE}ARTIFACT_NAME=${NORMAL}${ARTIFACT_NAME}"
echo -e "${BLUE}PACKAGING=${NORMAL}${PACKAGING}"

# Descargando archivo necesarios
[ "${REPOSITORY_LANGUAGE}" = "java" ] &&
    wget -q -O dd-java-agent.jar https://dtdg.co/latest-java-tracer
[ "${REPOSITORY_LANGUAGE}" = "python" ] && [ "${ORACLE}" = "true" ] &&
    wget -q -O instantclient.zip ${INSTANTCLIENT_URL}
[ "${LOG_LEVEL}" = "DEBUG" ] &&
    ls -l

ls -l
# Renombrar artefactos
if [ "${ARTIFACT_PATH}" != "." ]; then
    [ -n ${PACKAGING} ] &&
        mv ${FINAL_NAME} ${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${PACKAGING} ||
        mv ${FINAL_NAME} ${ARTIFACT_NAME}-${ARTIFACT_VERSION}
fi

# - >
#   curl -k -s -L -u ${NEXUS_REPO_USER}:${NEXUS_REPO_PASS} -X
#   GET "${NEXUS_URL}/service/rest/v1/search/assets/download?sort=version&repository=${SNAPSHOT_REPOSITORY}&maven.groupId=${GROUP_NAME}&maven.artifactId=${ARTIFACT_NAME}&maven.baseVersion=${PUBLISH_VERSION}&maven.extension=${PACKAGING}"
#   -H "accept: application/json" -o ${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${PACKAGING} || :

echo ${GCR_SERVICE_ACCOUNT} | base64 -d |
    docker login -u _json_key --password-stdin https://gcr.io

docker buildx create \
  --name container \
  --driver=docker-container
echo docker buildx build \
        --push --builder=container \
        --cache-from type=registry,ref=${REGISTRY}/${IMAGE_NAME}:cache \
        --cache-to   type=registry,ref=${REGISTRY}/${IMAGE_NAME}:cache,mode=max,image-manifest=true,oci-mediatypes=true \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${ARTIFACT_VERSION} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:cache \
        --build-arg  ARTIFACT_NAME=${ARTIFACT_NAME} \
        --build-arg  ARTIFACT_VERSION=${ARTIFACT_VERSION} \
        --build-arg  GIT_COMMIT=${CI_COMMIT_SHORT_SHA} \
        ${IMAGE_BUILD_ARGS} \
        $PWD

docker buildx build \
        --push \
        --cache-from type=registry,ref=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
        --cache-to   type=inline \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${ARTIFACT_VERSION} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
        --tag        ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} \
        --build-arg  ARTIFACT_NAME=${ARTIFACT_NAME} \
        --build-arg  ARTIFACT_VERSION=${ARTIFACT_VERSION} \
        --build-arg  GIT_COMMIT=${CI_COMMIT_SHORT_SHA} \
        ${IMAGE_BUILD_ARGS} \
        $PWD

docker inspect ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} | jq -C
