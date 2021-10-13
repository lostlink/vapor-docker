#!/bin/bash

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

prepare_dockerfile () {
  # Dockerfile Header
  DOCKERFILE_CONTENT=$(printf "# syntax = edrevo/dockerfile-plus\nFROM php:%s-fpm-alpine" "${PHP_VERSION}")
  if [ "$OS" == "debian" ]
  then
    DOCKERFILE_CONTENT=$(printf "# syntax = edrevo/dockerfile-plus\nFROM php:%s-fpm" "${PHP_VERSION}")
  fi

  # Dockerfile - Include Base Vapor PHP Setup
  DOCKERFILE_PHP_VERSION=$(echo "php${PHP_VERSION}" | sed 's/\.//g' | awk '{print tolower($0)}')
  DOCKERFILE_CONTENT=$(printf "%s\nINCLUDE+ ${DOCKERFILE_PHP_VERSION}/docker/${OS}/base.Dockerfile" "${DOCKERFILE_CONTENT}")

  # Dockerfile - Include Selected Systems
  for SYSTEM in $(echo "$SYSTEMS" | tr "," "\n" | sort)
  do
      DOCKERFILE_CONTENT=$(printf "%s\nINCLUDE+ ${DOCKERFILE_PHP_VERSION}/docker/${OS}/${SYSTEM}.Dockerfile"  "${DOCKERFILE_CONTENT}")
  done

  # Create Dockerfile Version
  DOCKERFILE_VERSION="${DOCKERFILE_PHP_VERSION}-${OS}"
  for SYSTEM in $(echo "$SYSTEMS" | tr "," "\n" | sort)
  do
      DOCKERFILE_VERSION=$(echo "${DOCKERFILE_VERSION}-${SYSTEM}")
  done
  DOCKERFILE_VERSION="${DOCKERFILE_VERSION}"

  DOCKERFILE_PATH="./${DOCKERFILE_VERSION}"

  echo "${DOCKERFILE_CONTENT}" > "${DOCKERFILE_PATH}"
}

build_image () {
  BUILD_DOCKERFILE=$1
  BUILD_VERSION=$2
  BUILD_PUBLISH=$3

  docker build -f "${BUILD_DOCKERFILE}" -t vapor-"${BUILD_VERSION}":latest .

  docker tag vapor-"${BUILD_VERSION}":latest "${VENDOR}"/"${REPO}":"${BUILD_VERSION}"

  if [ -n "$BUILD_PUBLISH" ]; then
    docker push "${VENDOR}"/"${REPO}":"${BUILD_VERSION}"
  fi
}

validate_input() {
  # Make sure input is lowercase and remove base from Systems
  OS=$(echo "${INPUT_OS}" | awk '{print tolower($0)}')
  SYSTEMS=$(echo "${INPUT_SYSTEMS}" | awk '{print tolower($0)}' | sed 's/base//g' | sed 's/^,//' | sed 's/,$//')
  VENDOR=$(echo "${INPUT_VENDOR}" | awk '{print tolower($0)}')
  REPO=$(echo "${INPUT_REPO}" | awk '{print tolower($0)}')
  PHP_VERSION="${INPUT_PHP}"

  # Version should be in the format 8.0
  if [ ${#INPUT_PHP} -ne 3 ];
  then
    echo "PHP error" ; exit
  fi

  # OS should be alpine or debian only
  if [[ ${OS} != "debian" && ${OS} != "alpine" ]];
  then
    echo "OS error" ; exit
  fi
}

default_input() {
  INPUT_OS="${INPUT_OS:-debian}"
  INPUT_PHP="${INPUT_PHP:-8.0}"
  INPUT_SYSTEMS="${INPUT_SYSTEMS:-base}"
  INPUT_VENDOR="${INPUT_VENDOR:-lostlink}"
  INPUT_REPO="${INPUT_REPO:-vapor}"
}

help () {
cat << EOD
  To build an image:
    ./build.sh -s octane,puppeteer -p 8.0 -o debian

  To build and publish an image:
    ./build.sh -s octane,puppeteer -p 8.0 -o debian --publish
EOD
}

main() {
  while [[ "$#" -gt 0 ]]
  do
    case $1 in
      -p|--php)
        local INPUT_PHP="$2"
        ;;
      -o|--os)
        local INPUT_OS="$2"
        ;;
      -s|--systems)
        local INPUT_SYSTEMS="$2"
        ;;
      --vendor)
        local INPUT_VENDOR="$2"
        ;;
      --repo)
        local INPUT_REPO="$2"
        ;;
      --publish)
        local PUBLISH=1
        ;;
    esac
    shift
  done

  default_input

  validate_input

  prepare_dockerfile

  build_image "${DOCKERFILE_PATH}" "${DOCKERFILE_VERSION}" "${PUBLISH}";

  rm -fr "${DOCKERFILE_PATH}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -eq 0 ]; then
      help
      exit 1
  fi

    main "$@"
fi