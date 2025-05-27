#! /bin/bash

set -e

apt -qq update > /tmp/apt.log 2>&1 || cat /tmp/apt.log
apt -qq install -y \
    libgconf-2-4 libatk1.0-0 \
    libatk-bridge2.0-0 libgdk-pixbuf2.0-0 \
    libgtk-3-0 libgbm-dev libnss3-dev \
    libxss-dev libasound2 > /tmp/apt.log 2>&1 || cat /tmp/apt.log

printf "${GREEN}npm install -G puppeteer ngx-spinner${NORMAL}\n"
npm install -g puppeteer ngx-spinner --verbose
CHROME_BIN="$(find / -name chrome -type f)"
export CHROME_BIN
printf "${BLUE}CHROME_BIN=${NORMAL}${CHROME_BIN}\n"
[ "${CHROME_BIN}" = "" ] && exit 1

PUPPETEER_SKIP_DOWNLOAD=true
export PUPPETEER_SKIP_DOWNLOAD

npm ci

ls -l ${CI_PROJECT_DIR}.tmp
npx -p @angular/cli@$(node -pe "require('./package.json').devDependencies['@angular/cli']") \
  ng test --watch=false --browsers="ChromeHeadless" --code-coverage=true
