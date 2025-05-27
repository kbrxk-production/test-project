#! /bin/bash

set -e

SSL_OPTIONS="-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -oPasswordAuthentication=no"

printf "${BLUE}BUSINESS_SERVICE_NAME=${NORMAL}$BUSINESS_SERVICE_NAME\n"
printf "${BLUE}FINAL_NAME=${NORMAL}$FINAL_NAME\n"
printf "${BLUE}WORK_DIR=${NORMAL}$WORK_DIR\n"
printf "${BLUE}OUTPUT_DIR=${NORMAL}$OUTPUT_DIR\n"
printf "${BLUE}SSL_OPTIONS=${NORMAL}${SSL_OPTIONS}\n"
[ "${BUSINESS_SERVICE_NAME}" = "" ] &&
    printf "${RED}ERROR: BUSINESS_SERVICE_NAME no esta definida${NORMAL}\n" &&
    ERROR=1
[ "${WORK_DIR}" = "" ] &&
    printf "${RED}ERROR: WORK_DIR no esta definida${NORMAL}\n" &&
    ERROR=1
[ "${OUTPUT_DIR}" = "" ] &&
    printf "${RED}ERROR: OUTPUT_DIR no esta definida${NORMAL}\n" &&
    ERROR=1
[ "${OUTPUT_DIR:0:1}" = "/" ] &&
    printf "${RED}ERROR: OUTPUT_DIR debe ser una ruta relativa${NORMAL}\n" &&
    ERROR=1

[ "${ERROR}" != "" ] &&
    exit 1

if grep -rlUP '\r$' * | xargs grep -I ^ > /dev/null; then
  printf "${RED}Se encontraron archivo con fines de linea CRLF${NORMAL}\n"
  exit 1
fi

# local public key (id_rsa.pub):
mkdir ~/.ssh
cat ${ID_RSA_FILE} > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
printf "${BLUE}~/.ssh/id_rsa.pub:${NORMAL}\n"
ssh-keygen -y -f ~/.ssh/id_rsa | tee ~/.ssh/id_rsa.pub

# Agregando host public key a known_hosts
SSH_HOST_IP=$(echo ${SSH_CONNECTION_STRING} |awk -F '@' '{print $NF}')
printf "${BLUE}Server public key:${NORMAL}\n"
ssh-keygen -R ${SSH_HOST_IP} | tee -a ~/.ssh/known_hosts
ssh-keyscan -t rsa ${SSH_HOST_IP} | tee -a ~/.ssh/known_hosts

printf "${GREEN}$ ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  \"mkdir -p $WORK_DIR\"\n"
ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  "mkdir -p $WORK_DIR"

# TODO: Eliminar binarios
chmod +x rutinas/gsoap/bin/*

# TODO: Normalizar estructura
printf "${GREEN}$ scp ${SSL_OPTIONS} -pr * $SSH_CONNECTION_STRING:$WORK_DIR${NORMAL}\n"
scp ${SSL_OPTIONS} -pr * $SSH_CONNECTION_STRING:$WORK_DIR

printf "${GREEN}$ scp ${SSL_OPTIONS} -pr /usr/local/bin/proc-aix-profile $SSH_CONNECTION_STRING:$WORK_DIR/.profile${NORMAL}\n"
scp ${SSL_OPTIONS} -pr /usr/local/bin/proc-aix-profile $SSH_CONNECTION_STRING:$WORK_DIR/.profile

printf "${GREEN}$ ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  \"bash -s \" < /usr/local/bin/proc-aix-build-mono-remote.sh $BUSINESS_SERVICE_NAME $WORK_DIR $OUTPUT_DIR${NORMAL}\n"
ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  "bash -s " < /usr/local/bin/proc-aix-build-mono-remote.sh "$BUSINESS_SERVICE_NAME" "$WORK_DIR" "$OUTPUT_DIR"

mkdir "${ARTIFACT_PATH}"
echo scp -pr ${SSH_CONNECTION_STRING}:/tmp/$BUSINESS_SERVICE_NAME.tar.gz "${FINAL_NAME}"
scp ${SSL_OPTIONS} -pr ${SSH_CONNECTION_STRING}:/tmp/$BUSINESS_SERVICE_NAME.tar.gz "${FINAL_NAME}"

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${FINAL_NAME}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
fi
