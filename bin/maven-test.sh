#! /bin/bash

set -e

maven-build.sh || ERROR $?

if [[ "$(find ${TESTS_PATH_REGEX} -type f -printf '.' | wc -c)" = "0" ]]; then
  printf "\n${RED}No se encontraron tests${NORMAL}\n"
  exit 127
fi

exit $ERROR
