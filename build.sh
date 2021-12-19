#!/bin/bash

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

prepare_dockerfile () {
  # PHP Version
  DOCKERFILE_PHP_VERSION=$(echo "php${PHP_VERSION}" | sed 's/\.//g' | awk '{print tolower($0)}')

  # Dockerfile Header
  DOCKERFILE_CONTENT="FROM php:${PHP_VERSION}-fpm-alpine"
  if [ "$OS" == "debian" ]
  then
    DOCKERFILE_CONTENT="FROM php:${PHP_VERSION}-fpm"
  fi

  # Dockerfile - Include Base PHP Setup
  while read -r line
  do
    if [[ $line == FROM* ]]
    then
        continue
    fi
    DOCKERFILE_CONTENT=$(printf "%s\n${line}" "${DOCKERFILE_CONTENT}")
  done < "${DOCKERFILE_PHP_VERSION}/${TARGET}/${OS}/base.Dockerfile"

  # Dockerfile - Include Selected Systems
  for SYSTEM in $(echo "$SYSTEMS" | tr "," "\n" | sort)
  do
    while read -r line
    do
      if [[ $line == FROM* ]]
      then
          continue
      fi
      DOCKERFILE_CONTENT=$(printf "%s\n${line}" "${DOCKERFILE_CONTENT}")
    done < "${DOCKERFILE_PHP_VERSION}/${TARGET}/${OS}/${SYSTEM}.Dockerfile"
  done

  # Create Dockerfile Version
  DOCKERFILE_VERSION="${DOCKERFILE_PHP_VERSION}-${OS}"
  for SYSTEM in $(echo "$SYSTEMS" | tr "," "\n" | sort)
  do
      DOCKERFILE_VERSION=$(echo "${DOCKERFILE_VERSION}-${SYSTEM}")
  done
  DOCKERFILE_VERSION="${DOCKERFILE_VERSION}"

  DOCKERFILE_PATH="./${DOCKERFILE_VERSION}.Dockerfile"

  echo "${DOCKERFILE_CONTENT}" > "${DOCKERFILE_PATH}"
}

build_image () {
  BUILD_DOCKERFILE=$1
  BUILD_VERSION=$2
  BUILD_PUBLISH=$3

  echo "${BUILD_DOCKERFILE}"

  docker buildx rm multibuild
  docker buildx create --use --name multibuild && \
  docker buildx build --platform linux/amd64,linux/arm64/v8,linux/arm/v7 -f "${BUILD_DOCKERFILE}" . -t "${VENDOR}"/"${TARGET}":"${BUILD_VERSION}"

  if [ "$PHP_VERSION" = "8.1" ]; then
    docker tag "${VENDOR}"/"${TARGET}":"${BUILD_VERSION}" "${TARGET}"-"${BUILD_VERSION}":latest
  fi

  if [ -n "$BUILD_PUBLISH" ]; then
    docker push "${VENDOR}"/"${TARGET}":"${BUILD_VERSION}"
  fi
}

validate_input() {
  # Make sure input is lowercase and remove base from Systems
  OS=$(echo "${INPUT_OS}" | awk '{print tolower($0)}')
  SYSTEMS=$(echo "${INPUT_SYSTEMS}" | awk '{print tolower($0)}' | sed 's/base//g' | sed 's/^,//' | sed 's/,$//')
  TARGET=$(echo "${INPUT_TARGET}" | awk '{print tolower($0)}')
  VENDOR=$(echo "${INPUT_VENDOR}" | awk '{print tolower($0)}')
  PHP_VERSION="${INPUT_PHP}"

  # Version should be in the format 8.0
  if [ ${#INPUT_PHP} -ne 3 ];
  then
    echo "PHP error" ; exit 1
  fi

  # OS should be alpine or debian only
  if [[ ${OS} != "debian" && ${OS} != "alpine" ]];
  then
    echo "OS error" ; exit 1
  fi

  # Target should be lambda or fargate only
  if [[ ${TARGET} != "lambda" && ${TARGET} != "fargate" ]];
  then
    echo "TARGET error" ; exit 1
  fi
}

default_input() {
  INPUT_OS="${INPUT_OS:-debian}"
  INPUT_PHP="${INPUT_PHP:-8.1}"
  INPUT_SYSTEMS="${INPUT_SYSTEMS:-base}"
  INPUT_TARGET="${INPUT_TARGET:-lambda}"
  INPUT_VENDOR="${INPUT_VENDOR:-lostlink}"
}

help () {
cat << EOD
  To build an image:
    ./build.sh -s octane,puppeteer -p 8.1 -o debian -t lambda

  To build and publish an image:
    ./build.sh -s octane,puppeteer -p 8.1 -o debian -t lambda --publish
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
      -t|--target)
        local INPUT_TARGET="$2"
        ;;
      --output-dockerfile-path)
        local DOCKERFILE_PATH_OUTPUT=1
        ;;
      --output-dockerfile-version)
        local DOCKERFILE_VERSION_OUTPUT=1
        ;;
      --dockerfile-keep)
        local DOCKERFILE_KEEP=1
        ;;
      --no-build)
        local NO_BUILD=1
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

  if [[ $DOCKERFILE_PATH_OUTPUT == 1 ]]
  then
    echo "${DOCKERFILE_PATH}"
  fi

  if [[ $DOCKERFILE_VERSION_OUTPUT == 1 ]]
  then
    echo "${DOCKERFILE_VERSION}"
  fi

  if [[ $NO_BUILD != 1 ]]
  then
    build_image "${DOCKERFILE_PATH}" "${DOCKERFILE_VERSION}" "${PUBLISH}";
  fi

  if [[ $DOCKERFILE_KEEP != 1 ]]
  then
    rm -fr "${DOCKERFILE_PATH}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -eq 0 ]; then
      help
      exit 1
  fi

    main "$@"
fi
