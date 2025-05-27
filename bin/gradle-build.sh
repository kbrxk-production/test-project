#! /bin/bash

set -e

printf "%s# Executing gradle%s\n" "${GREEN}" "${NORMAL}"

gradle --version

cp "/usr/local/bin/init.gradle" init.gradle
[ "${LOG_LEVEL}" = "DEBUG" ] &&
  printf "%sinit.gradle:%s\n" "${BLUE}" "${NORMAL}" &&
  cat init.gradle

# [[ "${DEPLOYABLE}" == "true" ]] &&
#   printf "${GREEN}Publicando artefactos${NORMAL}\n" &&
#   PUBLISH_OPTS="publish"

command="gradle --init-script init.gradle --build-cache build -x test --warning-mode all ${GRADLE_EXTRAS}"
printf "%s# %s%s\n" "${GREEN}" "${command}" "${NORMAL}"
${command}

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${FINAL_NAME}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
fi
