#! /bin/sh

set -e

python -m venv build-env
source build-env/bin/activate
pip install --quiet --no-cache-dir --upgrade pip poetry pytest pytest-cov

[ "${LOG_LEVEL}" != "DEBUG" ] && QUIET=--quiet
poetry export --without-hashes --format=requirements.txt > requirements.txt
pip install ${QUIET} --no-cache-dir -r requirements.txt

if [ -n "${TEST_NAME}" ]; then
  echo pytest --cov --cov-report xml:.sonar/coverage-reports/coverage-${TEST_NAME}.xml ${TEST_PATH}/${TEST_NAME}.py
  pytest --cov --cov-report xml:.sonar/coverage-reports/coverage-${TEST_NAME}.xml ${TEST_PATH}/${TEST_NAME}.py
else
  pytest --cov --cov-report xml:.sonar/coverage-reports/coverage-tests.xml ${TEST_PATH}/*.py
fi
