#! /bin/bash

set -e

printf "${GREEN}# Configuacion maven:${NORMAL}\n"

if [ "${JDK_FRAMEWORK}" = "appengine" ]; then
    MAVEN_EXTRAS="appengine:stage"
    ARTIFACT_PATH="${OUTPUT_DIR}/appengine-staging"
elif [ "${JDK_FRAMEWORK}" = "micronaut" ]; then
    MAVEN_EXTRAS="assembly:single"
    CLASSIFIER="jar-with-dependencies"
elif [ "${JDK_FRAMEWORK}" = "quarkus" ]; then
    CLASSIFIER="runner"
    ARTIFACT_PATH="${OUTPUT_DIR}"
elif [ "${JDK_FRAMEWORK}" = "shade" ]; then
    MAVEN_EXTRAS="org.apache.maven.plugins:maven-shade-plugin:3.5.0:shade"
fi

[ "${PACKAGING}" = "pom" ] &&
    export FINAL_NAME="pom.xml"
echo -e "${BLUE}JDK_VERSION=${NORMAL}${JDK_VERSION}"
echo -e "${BLUE}FINAL_NAME=${NORMAL}${FINAL_NAME}"
echo -e "${BLUE}DATABASE_NAME=${NORMAL}${DATABASE_NAME}"
echo -e "${BLUE}MAVEN_MULTIMODULE=${NORMAL}${MAVEN_MULTIMODULE}"

mkdir -p "${MAVEN_CONFIG}" || true
cp "/usr/local/bin/settings.xml" "${MAVEN_CONFIG}/settings.xml"
[ "${LOG_LEVEL}" = "DEBUG" ] &&
  ls -l "${REPOSITORY_PATH}" &&
  printf "${BLUE}settings.xml:${NORMAL}\n" &&
  cat "${MAVEN_CONFIG}/settings.xml"
printf "${BLUE}MAVEN_CLI_OPTS=${NORMAL}\"${MAVEN_CLI_OPTS}\"\n"
printf "${BLUE}MAVEN_USER_OPTS=${NORMAL}\"${MAVEN_USER_OPTS}\"\n"
printf "${BLUE}MAVEN_EXTRAS=${NORMAL}\"${MAVEN_EXTRAS}\"\n"
printf "%sJDK_FRAMEWORK=%s%s\n" "${BLUE}" "${NORMAL}" "${JDK_FRAMEWORK}"
printf "%sCLASSIFIER=%s%s\n" "${BLUE}" "${NORMAL}" "${CLASSIFIER}"

# if [ "${DEPLOYABLE}" = "true" ] && [ "${SKIP_IMAGE}" == "true" ]; then
#   PUBLISH_OPTS="deploy:deploy-file \
#     -Dfile=${FINAL_NAME} \
#     -DgroupId=${GROUP_NAME} \
#     -DartifactId=${ARTIFACT_NAME} \
#     -Dversion=${PUBLISH_VERSION} \
#     -Dpackaging=${PACKAGING} \
#     -DgeneratePom=true \
#     -DrepositoryId=proget \
#     -Durl=${ARTIFACT_REPOSITORY_URL}/maven2/maven-snapshots/ \
#     -DaltDeploymentRepository=proget::default::${ARTIFACT_REPOSITORY_URL}/maven2/maven-snapshots/"
# fi

printf "${GREEN}# mvn ${MAVEN_CLI_OPTS} ${MAVEN_USER_OPTS} clean package ${MAVEN_EXTRAS}${NORMAL}\n"
mvn ${MAVEN_CLI_OPTS} ${MAVEN_USER_OPTS} clean package ${MAVEN_EXTRAS} ${PUBLISH_OPTS}

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${FINAL_NAME}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
fi
