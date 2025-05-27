#! /bin/sh

set -e

export ANT_VERSION="1.10.14"
export IVY_VERSION="2.5.2"
printf "${BLUE}JAVA_HOME=${NORMAL}${JAVA_HOME}\n"
printf "${BLUE}ANT_VERSION=${NORMAL}${ANT_VERSION}\n"

if grep -rlUP '\r$' * | xargs grep -I ^ > /dev/null; then
  printf "${RED}Se encontraron archivo con fines de linea CRLF${NORMAL}\n"
  exit 1
fi

apt-get &> /dev/null && apt-get -qq update && apt-get -qq install -y wget curl
if wget &> /dev/null; then
  wget -q -O /tmp/apache-ant.tar.gz \
    https://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz
  tar -xf /tmp/apache-ant.tar.gz -C /usr/local/bin/
  wget -q -O /usr/local/bin/apache-ant-${ANT_VERSION}/lib/ivy-${IVY_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/ivy/ivy/${IVY_VERSION}/ivy-${IVY_VERSION}.jar
  export PATH="/usr/local/bin/apache-ant-${ANT_VERSION}/bin:$PATH"
fi

# cp /usr/local/bin/ivysettings.xml .
printf "${GREEN}$ ant clean build\n${NORMAL}"
ant clean build

ls -ltr dist/* ${OUTPUT_DIR} || :

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${FINAL_NAME}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
  if [ ! -f "${FINAL_NAME}" ]; then
    exit 1
  fi
fi
