#! /bin/sh

set -e

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
define_variables
printf "%sGenerando script sql:%s\n" "${GREEN}" "${NORMAL}"
cat > empty-dbchangelog.xml << EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                                        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-latest.xsd">
    <changeSet author="DevOps" id="tagDatabase-v1.0.0">
        <tagDatabase tag="v1.0.0" />
    </changeSet>
</databaseChangeLog>
EOF
liquibase update --changelog-file=empty-dbchangelog.xml
liquibase update-sql --output-file=../changelog.sql
