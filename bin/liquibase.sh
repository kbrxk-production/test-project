#! /bin/bash

set -e

# Variables:
printf "${BLUE}DATABASE_NAME=${NORMAL}${DATABASE_NAME}\n"
printf "${BLUE}ARTIFACT_VERSION=${NORMAL}${ARTIFACT_VERSION}\n"
printf "${BLUE}LATEST_RELEASE=${NORMAL}${LATEST_RELEASE}\n"
printf "${BLUE}CI_COMMIT_BRANCH=${NORMAL}${CI_COMMIT_BRANCH}\n"

define_variables() {
    # Generación de archivo de configuración
    DATABASE_JDBC=$(echo ${DB_CONNECTION_STRING} | awk -F://  '{print $1}')
    DATABASE_HOST=$(echo ${DB_CONNECTION_STRING} | awk -F[/?] '{print $3}' | sed 's|.*@||g')
    DATABASE_AUTH=$(echo ${DB_CONNECTION_STRING} | awk -F[/?] '{print $3}' | grep @ | sed 's|@.*||g') || :
    DATABASE_USER=$(echo ${DATABASE_AUTH} | sed 's|:.*||g') || :
    DATABASE_PASS=$(echo ${DATABASE_AUTH} | sed 's|.*:||g') || :
    [ $(echo ${DB_CONNECTION_STRING} | grep '\?') ] &&
        DATABASE_OPTS=?$(echo ${DB_CONNECTION_STRING} | cut -d\? -f2-)

    cat > liquibase.properties << EOF
    changelogfile: dbchangelog.xml
    url: ${DATABASE_JDBC}://${DATABASE_HOST}/${DATABASE_NAME}${DATABASE_OPTS}
    username: ${DATABASE_USER}
    password: ${DATABASE_PASS}
    loglevel: ${LOG_LEVEL}
    showbanner: false
    contexts: ${ENVIRONMENT}
EOF
    if [ "${LOG_LEVEL}" = "DEBUG" ]; then
        cat liquibase.properties
    fi
}

cd src
if [ "${DATABASE_VENDOR}" = "mongodb" ]; then
    cp /liquibase/plugins/liquibase-mongodb-*.jar \
        /liquibase/plugins/mongo-java-driver-*.jar \
        /liquibase/plugins/jackson-*.jar /liquibase/lib
fi

define_variables

if [ "${DATABASE_VENDOR}" = "postgres" ]; then
    [ -f schemas/schemas.sql ] &&
        liquibase update --changelog-file=schemas/schemas.sql
elif [ "${DATABASE_VENDOR}" = "mongodb" ]; then
    cat > empty-dbchangelog.xml << EOF
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                        xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                                            http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd"/>
EOF
fi

if [ "${LATEST_RELEASE}" != "null" ] &&
   [ "${CI_COMMIT_REF_NAME}" != "${CI_DEFAULT_BRANCH}" ]; then
    printf "%sInstalación línea base productiva:%s\n" "${GREEN}" "${NORMAL}"
    git reset --hard origin/${CI_DEFAULT_BRANCH}
    liquibase update
fi

git reset --hard ${CI_COMMIT_SHORT_SHA}

printf "%sValidando changelog para:%s\n" "${GREEN}" "${NORMAL}"
liquibase validate

printf "%sProbando Instalación:%s\n" "${GREEN}" "${NORMAL}"
liquibase update --show-summary VERBOSE

printf "%sProbando Vuelta Atrás:%s\n" "${GREEN}" "${NORMAL}"
liquibase rollback v${ARTIFACT_VERSION}

printf "%sProbando Reinstalación:%s\n" "${GREEN}" "${NORMAL}"
liquibase update

if [ -n "${ERROR}" ]; then
    printf "%s%s%s\n" "${RED}" "${ERROR}" "${NORMAL}"
    exit 1
fi
