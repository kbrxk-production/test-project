#! /bin/sh

set -e

if [ "${JDK_FRAMEWORK}" = "quarkus" ]; then
  CLASSIFIER="runner"
  GRADLE_EXTRAS="quarkusBuild"
fi
printf "%sJDK_FRAMEWORK=%s%s\n" "${BLUE}" "${NORMAL}" "${JDK_FRAMEWORK}"
printf "%sCLASSIFIER=%s%s\n" "${BLUE}" "${NORMAL}" "${CLASSIFIER}"
printf "%sGRADLE_EXTRAS=%s%s\n" "${BLUE}" "${NORMAL}" "${GRADLE_EXTRAS}"

printf "%s# Executing gradle%s\n" "${GREEN}" "${NORMAL}" &&

gradle --version

cp "/usr/local/bin/init.gradle" init.gradle
[ "${LOG_LEVEL}" = "DEBUG" ] &&
  printf "%sinit.gradle:%s\n" "${BLUE}" "${NORMAL}" &&
    cat init.gradle

command="gradle --init-script init.gradle --build-cache test --warning-mode all ${GRADLE_EXTRAS}"
printf "%s# %s%s\n" "${GREEN}" "${command}" "${NORMAL}"
${command}
