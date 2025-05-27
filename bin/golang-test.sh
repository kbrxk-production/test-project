#!/bin/bash

set -e

printf "${GREEN}# Starting Unit Tests:${NORMAL}\n"

if [ "$(find . -name '*_test.go' | wc -l)" = "0" ]; then
    exit 127
fi

mkdir .sonar
go mod vendor > /dev/null
go test -v -coverpkg=./... -coverprofile=.sonar/coverage.out ./...|
    sed ''/PASS/s//$(printf "${GREEN}PASS${NORMAL}")/'' |
    sed ''/FAIL/s//$(printf "${RED}FAIL${NORMAL}")/''
