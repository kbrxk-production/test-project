#! /bin/bash

set -e

curl -s -o /usr/local/bin/functions \
    ${CI_SERVER_PROTOCOL}://gitlab-ci-token:${CI_JOB_TOKEN}@${CI_SERVER_HOST}/devops/ci-cd/build-pipeline/-/raw/main/bin/functions
. /usr/local/bin/functions

# Rescata informacion del proyecto
# Evaluating Variables:
printf "%sDEPLOYABLE=%s%s\n" "${BLUE}" "${NORMAL}" "${DEPLOYABLE}"
printf "%sOUTPUT_DIR=%s%s\n" "${BLUE}" "${NORMAL}" "${OUTPUT_DIR}"
printf "%sTESTS_PATH_REGEX=%s%s\n" "${BLUE}" "${NORMAL}" "${TESTS_PATH_REGEX}"
printf "%sARTIFACT_PATH=%s%s\n" "${BLUE}" "${NORMAL}" "${ARTIFACT_PATH}"
printf "%sFULL_PIPELINE=%s%s\n" "${BLUE}" "${NORMAL}" "${FULL_PIPELINE}"
printf "%sSKIP_CHECKS=%s%s\n" "${BLUE}" "${NORMAL}" "${SKIP_CHECKS}"
printf "%sSKIP_BUILD=%s%s\n" "${BLUE}" "${NORMAL}" "${SKIP_BUILD}"
[ -f Dockerfile ] &&
    SKIP_IMAGE=false
export SKIP_IMAGE
printf "%sSKIP_IMAGE=%s%s\n" "${BLUE}" "${NORMAL}" "${SKIP_IMAGE}"

[ -z "${REPOSITORY_LANGUAGE}" ] && [ "${SKIP_BUILD}" = "true" ] && [ "${SKIP_IMAGE}" != "true" ] &&
    REPOSITORY_LANGUAGE=docker
export REPOSITORY_LANGUAGE
printf "%sREPOSITORY_LANGUAGE=%s%s\n" "${BLUE}" "${NORMAL}" "${REPOSITORY_LANGUAGE}"

if [ "${SKIP_BUILD}" = "false" ]; then
    printf "%sBUILD_TOOL=%s%s\n" "${BLUE}" "${NORMAL}" "${BUILD_TOOL}"
    printf "%sPACKAGING=%s%s\n" "${BLUE}" "${NORMAL}" "${PACKAGING}"
    printf "%sREPOSITORY_PATH=%s%s\n" "${BLUE}" "${NORMAL}" "${REPOSITORY_PATH}"
fi

##### GROUP_NAME #####
if [ "${SKIP_BUILD}" = "false" ]; then
    [ "${LOG_LEVEL}" = "DEBUG" ] &&
        echo "${GREEN}$ ${get_group_name}${NORMAL}" &&
        eval ${get_group_name} &&
        echo
    GROUP_NAME="$(eval ${get_group_name})"
    if [ -z "${GROUP_NAME}" ]; then
        printf "%sNo se pudo obtener el nombre del grupo%s\n" "${RED}" "${NORMAL}"
        [ "${SKIP_CHECKS}" = "true" ] && exit 127 || exit 1
    fi
    if [ "${PACKAGE_NAME_VALIDATION}" = "true" ]; then
        if [ "${REPOSITORY_LANGUAGE}" = "java" ]; then
        echo "${GROUP_NAME}" | grep -Pq "^${JAVA_PACKAGE_NAME_REGEX}$" ||
            ERROR="${ERROR}\nERROR: El nombre del grupo (package) debe tener el formato ${JAVA_PACKAGE_NAME_REGEX}"
        elif [ "${REPOSITORY_LANGUAGE}" = "golang" ]; then
        echo "${GROUP_NAME}" | grep -Pq "^${GO_PACKAGE_NAME_REGEX}$" ||
            ERROR="${ERROR}\nERROR: El nombre del grupo (package) debe tener el formato ${GO_PACKAGE_NAME_REGEX}"
        elif echo "${REPOSITORY_LANGUAGE}" | grep -Pq '^typescript$'; then
        echo "${GROUP_NAME}" | grep -Pq "^${NODE_PACKAGE_NAME_REGEX}$" ||
            ERROR="${ERROR}\nERROR: El nombre del grupo (package) debe tener el formato ${NODE_PACKAGE_NAME_REGEX}"
        fi
    fi
    export GROUP_NAME
    printf "%sGROUP_NAME=%s%s\n" "${BLUE}" "${NORMAL}" "${GROUP_NAME}"
fi

##### ARTIFACT_NAME #####
ARTIFACT_NAME="${CI_PROJECT_NAME}"
if [ "${SKIP_BUILD}" = "false" ]; then
    ARTIFACT_NAME="$(eval ${get_name} | head -1)" ||
        ERROR="${ERROR}\nERROR: No se pudo obtener el nombre del artefacto"
    if [ "${REPOSITORY_LANGUAGE}" = "java" ]; then
        echo "${ARTIFACT_NAME}" | grep -Pq "${JAVA_ARTIFACT_NAME_REGEX}" ||
        ERROR="${ERROR}\nERROR: El nombre del artefacto no cumple con la definicion (${JAVA_ARTIFACT_NAME_REGEX})"
    elif [ "${REPOSITORY_LANGUAGE}" = "golang" ]; then
        echo "${ARTIFACT_NAME}" | grep -Pq '^[a-z0-9-]+$' ||
        ERROR="${ERROR}\nERROR: El nombre del artefacto debe contener solo minúsculas y guión"
    elif [ "${REPOSITORY_LANGUAGE}" = "python" ]; then
        echo "${ARTIFACT_NAME}" | grep -Pq '^[a-z0-9-]+$' ||
        ERROR="${ERROR}\nERROR: El nombre del artefacto debe contener solo minúsculas y guión"
        ARTIFACT_NAME=$(printf "%s" "${ARTIFACT_NAME}" | tr '-' '_')
    fi
fi
export ARTIFACT_NAME
printf "%sARTIFACT_NAME=%s%s\n" "${BLUE}" "${NORMAL}" "${ARTIFACT_NAME}"

##### ARTIFACT_VERSION #####
if [ "${SKIP_BUILD}" = "true" ]; then
    ARTIFACT_VERSION="$(eval cat VERSION)" ||
    ERROR="${ERROR}\nERROR: No se pudo leer archivo VERSION"
else
    ARTIFACT_VERSION="$(eval ${get_version})" ||
    ERROR="${ERROR}\nERROR: No se pudo obtener VERSION"
fi
if [ -z "${ARTIFACT_VERSION}" ]; then
    printf "%sNo se pudo obtener la version del artefacto%s\n" "${RED}" "${NORMAL}"
    [ "${SKIP_CHECKS}" = "true" ] && exit 127 || exit 1
fi
echo "${ARTIFACT_VERSION}" | grep -Pq '^[1-9][0-9]*\.[0-9]+\.[0-9]+$' ||
ERROR="${ERROR}\nERROR: La version del artefacto debe tener el formato mayor.menor.parche"
export ARTIFACT_VERSION
printf "%sARTIFACT_VERSION=%s%s\n" "${BLUE}" "${NORMAL}" "${ARTIFACT_VERSION}"

##### LATEST_RELEASE #####
if jq &> /dev/null ; then
    LATEST_RELEASE=$(curl -k -s --header  "Job-Token: ${CI_JOB_TOKEN}" -X GET \
        "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/releases" |
        jq -r '.[0].name' | sed 's|^v||g')
    export LATEST_RELEASE
    printf "%sLATEST_RELEASE=%s%s\n" "${BLUE}" "${NORMAL}" "${LATEST_RELEASE}"
    if ! echo "${LATEST_RELEASE}" | grep -Pq '^null$|^$'; then
        printf "%sCI_COMMIT_TAG=%s%s\n" "${BLUE}" "${NORMAL}" "${CI_COMMIT_TAG}"
        if ! echo "${CI_COMMIT_REF_NAME}" | grep -Pq '^master$|^main$|^renovate/|^test-|^test$|^pipeline$|^revert-|^temp$' &&
                [ -z "${CI_COMMIT_TAG}" ] &&
                [ "${FULL_PIPELINE}" = "true" ]; then
            [ "$LATEST_RELEASE" = "$(printf "%s\n%s" "${ARTIFACT_VERSION}" "${LATEST_RELEASE}" | sort -V | tail -1)" ] &&
            ERROR="${ERROR}\nERROR: La nueva version debe ser superior al último release"
        fi
    fi
fi

##### PUBLISH_VERSION #####
if [ "${SKIP_BUILD}" != "true" ]; then
    PUBLISH_TYPE="SNAPSHOT"
    export PUBLISH_TYPE
    printf "%sPUBLISH_TYPE=%s%s\n" "${BLUE}" "${NORMAL}" "${PUBLISH_TYPE}"
    PUBLISH_VERSION=${ARTIFACT_VERSION}
    [ "${PUBLISH_TYPE}" = "SNAPSHOT" ] &&
        PUBLISH_VERSION=${PUBLISH_VERSION}-${PUBLISH_TYPE}
    export PUBLISH_VERSION
    printf "%sPUBLISH_VERSION=%s%s\n" "${BLUE}" "${NORMAL}" "${PUBLISH_VERSION}"
fi

# TODO: Eliminar y dejar solo el de maven
if [ "${JDK_FRAMEWORK}" = "appengine" ]; then
    MAVEN_EXTRAS="appengine:stage"
    ARTIFACT_PATH="${OUTPUT_DIR}/appengine-staging"
elif [ "${JDK_FRAMEWORK}" = "micronaut" ]; then
    MAVEN_EXTRAS="assembly:single"
    CLASSIFIER="jar-with-dependencies"
elif [ "${JDK_FRAMEWORK}" = "quarkus" ]; then
    CLASSIFIER="runner"
    ARTIFACT_PATH="${OUTPUT_DIR}"
elif [ "${JDK_FRAMEWORK}" = "shade" ]; then
    MAVEN_EXTRAS="org.apache.maven.plugins:maven-shade-plugin:3.5.0:shade"
fi

##### FINAL_NAME #####
if [ "${SKIP_BUILD}" = "false" ]; then
    FINAL_NAME=${ARTIFACT_PATH}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}
    [ -n "${CLASSIFIER}" ] &&
        FINAL_NAME=${FINAL_NAME}-${CLASSIFIER}
    [ -n "${PACKAGING}" ] &&
        FINAL_NAME=${FINAL_NAME}.${PACKAGING}
    # [ "${MAVEN_MULTIMODULE}" = "true" ] &&
    #     [ "${BUILD_TOOL}" = "maven" ] &&
    #         FINAL_NAME=core/${FINAL_NAME}
    export FINAL_NAME
    printf "%sFINAL_NAME=%s%s\n" "${BLUE}" "${NORMAL}" "${FINAL_NAME}"
fi

##### BUILD_NUMBER #####
BUILD_NUMBER="v${ARTIFACT_VERSION}-${CI_COMMIT_SHORT_SHA}"
if [ "${SKIP_BUILD}" = "true" ]; then
    [ -n "${CLASSIFIER}" ] &&
        BUILD_NUMBER="${BUILD_NUMBER}-${CLASSIFIER}"
fi
export BUILD_NUMBER
printf "%sBUILD_NUMBER=%s%s\n" "${BLUE}" "${NORMAL}" "${BUILD_NUMBER}"

##### BUSINESS_SERVICE_NAME #####
echo "${BUSINESS_SERVICE_NAME}" | grep -Pq '^$|^none$' &&
    ERROR="${ERROR}\nERROR: Se debe definir variable BUSINESS_SERVICE_NAME"
printf "%sBUSINESS_SERVICE_NAME=%s%s\n" "${BLUE}" "${NORMAL}" "${BUSINESS_SERVICE_NAME}"

##### REGISTRY #####
if [ -f Dockerfile ]; then
    [ "${DEPLOYABLE}" != "true" ] &&
        export ENVIRONMENT=temp

    ##### REGISTRY #####
    REGISTRY=${GCR_HOST}/${GCR_PROJECT}/${ENVIRONMENT}/${BUSINESS_SERVICE_NAME}
    export REGISTRY
    printf "%sREGISTRY=%s%s\n" "${BLUE}" "${NORMAL}" "${REGISTRY}"
fi
##### IMAGE_NAME #####
IMAGE_NAME="${CI_PROJECT_NAME}"
export IMAGE_NAME
printf "%sIMAGE_NAME=%s%s\n" "${BLUE}" "${NORMAL}" "${IMAGE_NAME}"
printf "%sIMAGE_TAG=%s%s\n" "${BLUE}" "${NORMAL}" "${IMAGE_TAG}"

##### PACKAGE_LOCATION #####
# if  [ "${DEPLOYABLE}" = "true" ] && [ "${SKIP_IMAGE}" = "true" ]; then
  PACKAGE_LOCATION="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${PACKAGING}"
  export PACKAGE_LOCATION
  printf "%sPACKAGE_LOCATION=%s%s\n" "${BLUE}" "${NORMAL}" "${PACKAGE_LOCATION}"
# fi

[ "${REPOSITORY_LANGUAGE}" = "java" ] &&
    printf "%sJDK_VERSION=%s%s\n" "${BLUE}" "${NORMAL}" "${JDK_VERSION}"

# TODO: habilitar cuando haya una solucion para los hotfix
if ! echo "${CI_COMMIT_REF_NAME}" | grep -Pq '^temp$|^revert-$'
    git &> /dev/null &&
    [ -z "${CI_COMMIT_TAG}" ]; then
    printf "%s# git rev-list --left-only --count origin/${CI_DEFAULT_BRANCH}...@%s\n" "${GREEN}" "${NORMAL}"
    COMMITS_BEHIND=$(git rev-list --left-only --count origin/${CI_DEFAULT_BRANCH}...@)
    [ "${COMMITS_BEHIND}" != "0" ] &&
        ERROR="${ERROR}\nERROR: El commit actual está ${COMMITS_BEHIND} commits detrás de la rama principal"

    printf "%s# git rev-list --merges --count origin/${CI_DEFAULT_BRANCH}..@%s\n" "${GREEN}" "${NORMAL}"
    MERGES=$(git rev-list --merges --count origin/${CI_DEFAULT_BRANCH}..@)
    [ "${MERGES}" != "0" ] && [ "${LATEST_RELEASE}" != "null" ] &&
        ERROR="${ERROR}\nERROR: La rama contiene ${MERGES} merges fuera de la rama principal"
fi

env |
grep -Ew "^REPOSITORY_LANGUAGE|^GROUP_NAME|^ARTIFACT_NAME|^ARTIFACT_VERSION|\
^PUBLISH_VERSION|^FINAL_NAME|^DEPLOYABLE|^PUBLISH_TYPE|^PACKAGE_LOCATION|\
^REGISTRY|^BUSINESS_SERVICE_NAME|^IMAGE_TAG|^IMAGE_NAME|^BUILD_NUMBER|^BUILD_TOOL|\
^JDK_VERSION|^PACKAGING|^REPOSITORY_PATH|^SKIP_IMAGE|^LATEST_RELEASE" > build.env
if [ -n "${ERROR}" ]; then
    printf "${RED}${ERROR}${NORMAL}\n"
    [ "${SKIP_CHECKS}" = "true" ] && exit 127 || exit 1
fi

if grep "=$" build.env > /dev/null; then
    printf "%sValor no encontrado%s\n" "${RED}" "${NORMAL}"
    [ "${SKIP_CHECKS}" = "true" ] && exit 127 || exit 1
fi
