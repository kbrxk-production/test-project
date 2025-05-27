#!/bin/bash

set -e -o pipefail

ESC="\e"
RED="$ESC[91m"
GREEN="$ESC[92m"
YELLOW="$ESC[93m"
BLUE="$ESC[94m"
NORMAL="$ESC[0m"

export SERVICE_NAME=$1
export WORK_DIR=$2
export OUTPUT_DIR=$3
printf "${BLUE}SERVICE_NAME=${NORMAL}$SERVICE_NAME\n"
printf "${BLUE}HOME=${NORMAL}$HOME\n"
printf "${BLUE}WORK_DIR=${NORMAL}$WORK_DIR\n"
printf "${BLUE}OUTPUT_DIR=${NORMAL}$OUTPUT_DIR\n"
[ "${WORK_DIR}" = "" ] &&
    printf "${RED}ERROR: WORK_DIR no esta definida${NORMAL}\n" &&
    exit 1
[ "${OUTPUT_DIR}" = "" ] &&
    printf "${RED}ERROR: OUTPUT_DIR no esta definida${NORMAL}\n" &&
    exit 1
[ "${OUTPUT_DIR:0:1}" = "/" ] &&
    printf "${RED}ERROR: OUTPUT_DIR debe ser una ruta relativa${NORMAL}\n" &&
    exit 1
[ -z "$3" ] &&
    printf "${RED}ERROR: Parametros no encontrados${NORMAL}\n" &&
    exit 1

printf "${BLUE}Loading .profile:${NORMAL}\n"
printf "$(cat $WORK_DIR/.profile | sed "s,.*=,\\\\${BLUE}&\\\\${NORMAL},")\n"
. $WORK_DIR/.profile
(proc version=? || true) | head -3

rm -rf "$WORK_DIR/$OUTPUT_DIR"
mkdir -p "$WORK_DIR/lib"
mkdir -p "$WORK_DIR/$OUTPUT_DIR"
cd $WORK_DIR

printf "${GREEN}$ Iniciando compilación:${NORMAL}\n"
ls -l
[ ! -f "Makefile" ] &&
    printf "${RED}ERROR: No se encuentra archivo Makefile${NORMAL}\n" &&
    exit 1
printf "${GREEN}make clean all${NORMAL}\n"
make clean all
ERROR=$?
[ "$ERROR" != "0" ] && exit $ERROR

printf "${GREEN}$ Generando archivo $SERVICE_NAME.tar.gz${NORMAL}${NORMAL}\n"
printf "${BLUE}$WORK_DIR/$OUTPUT_DIR:${NORMAL}\n"
cd "$WORK_DIR/$OUTPUT_DIR"
# TODO: Empaquetar librerias
printf "${GREEN}$ tar cvf - * ../lib | gzip > /tmp/$SERVICE_NAME.tar.gz${NORMAL}\n"
tar cvf - * ../lib | gzip > /tmp/$SERVICE_NAME.tar.gz || true
