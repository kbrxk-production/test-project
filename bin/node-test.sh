#! /bin/bash

set -e

if [ ! -d "${TESTS_PATH_REGEX}" ]; then
  printf "%sNo se encontraron tests unitarios%s" "${RED}" "${NORMAL}"
  exit 127
fi
