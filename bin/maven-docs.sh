#! /bin/sh

set -e

printf "${GREEN}# Configuacion maven:${NORMAL}\n"

# Configuacion maven:
mkdir -p ${MAVEN_CONFIG} || true
cp "/usr/local/bin/settings.xml" "${MAVEN_CONFIG}/settings.xml"
[ "${LOG_LEVEL}" = "DEBUG" ] &&
  ls -l ${REPOSITORY_PATH} &&
  printf "settings.xml:\n" &&
  cat ${MAVEN_CONFIG}/settings.xml
printf "${BLUE}MAVEN_CLI_OPTS=${NORMAL}\"${MAVEN_CLI_OPTS}\"\n"
printf "${BLUE}MAVEN_USER_OPTS=${NORMAL}\"${MAVEN_USER_OPTS}\"\n"
printf "${GREEN}# mvn ${MAVEN_CLI_OPTS} ${MAVEN_USER_OPTS} org.apache.maven.plugins:maven-javadoc-plugin:3.5.0:aggregate${NORMAL}\n"
mvn ${MAVEN_CLI_OPTS} ${MAVEN_USER_OPTS} org.apache.maven.plugins:maven-javadoc-plugin:3.5.0:aggregate
mv target/site/apidocs public
