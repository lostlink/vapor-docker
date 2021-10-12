#!/bin/bash

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

main () {
  VERSION=$1
  PUBLISH=$2

  if [ "$VERSION" == "all" ]; then
    ALL=$(find . -name "php*.Dockerfile" | sort -r)
    echo "${ALL}"
    for value in ${ALL}
    do
        length=$((${#value} - 13))
        VERSION=${value:2:$length}
        build "${VERSION}" "${PUBLISH}";
    done
  else
    build "${VERSION}" "${PUBLISH}";
  fi
}

build () {
  BUILD_VERSION=$1
  BUILD_PUBLISH=$2

  docker build -f "${PWD}"/"${BUILD_VERSION}".Dockerfile -t vapor-"${BUILD_VERSION}":latest .

  docker tag vapor-"${BUILD_VERSION}":latest lostlink/vapor:"${BUILD_VERSION}"

  if [ -n "$BUILD_PUBLISH" ]; then
    docker push lostlink/vapor:"${BUILD_VERSION}"
  fi
}

help ()
{
cat << EOD
To build an image:
  ./build.sh php80-debian-octane

To build and publish an image:
  ./build.sh php80-debian-octane -p

To build all images
  ./build.sh all

To build and publish all images
  ./build.sh all -p
EOD

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [ $# -eq 0 ]; then
      help
      exit 1
  fi

    main "$@"
fi