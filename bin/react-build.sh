#! /bin/bash

set -e

node -v

[ ! -f yarn.lock ] &&
  echo -e "${RED}No existe yarn.lock${NORMAL}" &&
  exit 1

printf "%snpm config set cache .npm%s\n" "${GREEN}" "${NORMAL}"
npm config set cache .npm
cat > .eslintrc << EOF
{
  "rules": {}
}
EOF

printf "%syarn%s\n" "${GREEN}" "${NORMAL}"
yarn

printf "%syarn build%s\n" "${GREEN}" "${NORMAL}"
yarn build

ls -la

tar -zcf ${FINAL_NAME} ${OUTPUT_DIR} yarn.lock package.json
