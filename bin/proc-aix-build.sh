#! /bin/bash

set -e

SSL_OPTIONS="-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa -oPasswordAuthentication=no"

printf "${BLUE}BUSINESS_SERVICE_NAME=${NORMAL}$BUSINESS_SERVICE_NAME\n"
printf "${BLUE}SERVICE_NAME=${NORMAL}$SERVICE_NAME\n"
printf "${BLUE}FINAL_NAME=${NORMAL}$FINAL_NAME\n"
printf "${BLUE}WORK_DIR=${NORMAL}$WORK_DIR\n"
printf "${BLUE}OUTPUT_DIR=${NORMAL}$OUTPUT_DIR\n"
printf "${BLUE}SSL_OPTIONS=${NORMAL}${SSL_OPTIONS}\n"
[ "${BUSINESS_SERVICE_NAME}" = "" ] &&
    printf "${RED}ERROR: BUSINESS_SERVICE_NAME no esta definida${NORMAL}\n" &&
    ERROR=1
[ "${SERVICE_NAME}" = "" ] &&
    printf "${RED}ERROR: SERVICE_NAME no esta definida${NORMAL}\n" &&
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
[ ! -f Makefile ] &&
    printf "${RED}NO se encuentra archivo Makefile${NORMAL}\n" &&
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

if [ -f dependencies.ini ]; then
  dependencies_path=dependencies
  mkdir $dependencies_path
  while IFS= read -r line; do
    if [[ ! $line =~ ^#|^( )*$ ]]; then
      repository="$(echo $line | cut -d' ' -f1)"
      location="$(echo $line | cut -d' ' -f2)"
      [ "$location" = "$repository" ] &&
        location=$(basename $line)
      git clone -b master --single-branch \
        ${CI_SERVER_PROTOCOL}://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/$repository.git \
        $dependencies_path/$location
      rm -rf $dependencies_path/$location/.git
    fi
  done < dependencies.ini
fi

# Agregando host public key a known_hosts
SSH_HOST_IP=$(echo ${SSH_CONNECTION_STRING} |awk -F '@' '{print $NF}')
printf "${BLUE}Server public key:${NORMAL}\n"
ssh-keygen -R ${SSH_HOST_IP} | tee -a ~/.ssh/known_hosts
ssh-keyscan -t rsa ${SSH_HOST_IP} | tee -a ~/.ssh/known_hosts
# printf "${GREEN}$ ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
#   \"rm -rf $WORK_DIR/fuentes $WORK_DIR/lib $WORK_DIR/tests $WORK_DIR/include && mkdir -p $WORK_DIR\"\n"
# ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
#   "rm -rf $WORK_DIR/fuentes $WORK_DIR/lib $WORK_DIR/tests $WORK_DIR/include && mkdir -p $WORK_DIR"
printf "${GREEN}$ ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  \"mkdir -p $WORK_DIR\"\n"
ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  "mkdir -p $WORK_DIR"

# TODO: Normalizar estructura
# printf "${GREEN}$ scp ${SSL_OPTIONS} -pr Makefile src include $dependencies_path $SSH_CONNECTION_STRING:$WORK_DIR${NORMAL}\n"
# scp ${SSL_OPTIONS} -pr Makefile src include $dependencies_path $SSH_CONNECTION_STRING:$WORK_DIR
if [ -d servidores ]; then
  printf "${GREEN}$ scp ${SSL_OPTIONS} -pr servidores Makefile VERSION $SSH_CONNECTION_STRING:$WORK_DIR/$SERVICE_NAME/${NORMAL}\n"
  scp ${SSL_OPTIONS} -pr servidores Makefile VERSION $SSH_CONNECTION_STRING:$WORK_DIR/$SERVICE_NAME/
fi
if [ -d batch ]; then
  ls -l batch/fuentes
  printf "${GREEN}$ scp ${SSL_OPTIONS} -pr batch Makefile VERSION $SSH_CONNECTION_STRING:$WORK_DIR/$SERVICE_NAME/${NORMAL}\n"
  scp ${SSL_OPTIONS} -pr batch Makefile VERSION $SSH_CONNECTION_STRING:$WORK_DIR/$SERVICE_NAME/
fi
if [ -f dependencies.ini ]; then
  printf "${GREEN}$ scp ${SSL_OPTIONS} -pr $dependencies_path/* $SSH_CONNECTION_STRING:$WORK_DIR/${NORMAL}\n"
  scp ${SSL_OPTIONS} -pr $dependencies_path/* $SSH_CONNECTION_STRING:$WORK_DIR/
fi
printf "${GREEN}$ scp ${SSL_OPTIONS} -pr /usr/local/bin/proc-aix-profile $SSH_CONNECTION_STRING:$WORK_DIR/.profile${NORMAL}\n"
scp ${SSL_OPTIONS} -pr /usr/local/bin/proc-aix-profile $SSH_CONNECTION_STRING:$WORK_DIR/.profile

printf "${GREEN}$ ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  \"bash -s \" < /usr/local/bin/proc-aix-build-remote.sh $SERVICE_NAME $WORK_DIR $OUTPUT_DIR${NORMAL}\n"
ssh ${SSL_OPTIONS} ${SSH_CONNECTION_STRING} \
  "bash -s " < /usr/local/bin/proc-aix-build-remote.sh "$SERVICE_NAME" "$WORK_DIR" "$OUTPUT_DIR"

mkdir "${ARTIFACT_PATH}"
echo scp -pr ${SSH_CONNECTION_STRING}:/tmp/$SERVICE_NAME.tar.gz "${FINAL_NAME}"
scp ${SSL_OPTIONS} -pr ${SSH_CONNECTION_STRING}:/tmp/$SERVICE_NAME.tar.gz "${FINAL_NAME}"

if  [ -n "${PACKAGE_LOCATION}" ]; then
  curl -s --request PUT \
       --upload-file "${FINAL_NAME}" \
       --header "Job-Token: ${CI_JOB_TOKEN}" \
       "${PACKAGE_LOCATION}" || :
fi
