#!/usr/bin/env bash

set -e

# Credits for initial version: https://github.com/robertpeteuil/build-lambda-layer-python

# AWS Lambda Layer Zip Builder for Python Libraries
#   requires: docker, _make.zip.sh, build_layer.sh (this script)
#     Launches docker container from lambci/lambda:build-pythonX.X image
#         where X.X is the python version (2.7, 3.6, 3.7) - defaults to 3.7
#     Executes build script "_make.zip.sh" within container to create zip
#         with libs specified in package.json
#     Zip filename includes python version used in its creation

scriptname=$(basename "$0")
scriptbuildnum="1.0.0"
scriptbuilddate="2020-04-05"

# Used to set destination of zip
SUBDIR_MODE=""

# Display version
displayVer() {
  echo -e "${scriptname} v${scriptbuildnum} (${scriptbuilddate})"
}

# Display usage
usage() {
  echo -e "AWS Lambda Layer Builder for Node libraries\n"
  echo -e "Usage: ${scriptname} [-l NODEJS_RUNTIME_VERSION] [-n NAME] [-r] [-h] [-v]"
  echo -e "  -l NODEJS_RUNTIME_VERSION\t: Node runtime version to use: 8.10, 10.x, 12.x (default 10.x)"
  echo -e "  -n NAME\t\t\t: Name of the layer"
  echo -e "  -r\t\t\t\t: Raw mode, don't zip layer contents"
  echo -e "  -h\t\t\t\t: Help"
  echo -e "  -v\t\t\t\t: Display ${scriptname} version"
}

# Handle configuration
while getopts ":l:n:rhv" arg; do
  case "${arg}" in
    l)  NODEJS_RUNTIME_VERSION=${OPTARG};;
    n)  NAME=${OPTARG};;
    r)  RAW_MODE=true;;
    h)  usage; exit;;
    v)  displayVer; exit;;
    \?) echo -e "Error - Invalid option: $OPTARG"; usage; exit;;
    :)  echo "Error - $OPTARG requires an argument"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))

# Default Python to 3.7 if not set by CLI params
NODEJS_RUNTIME_VERSION="${NODEJS_RUNTIME_VERSION:-10.x}"
NAME="${NAME:-base}"
CURRENT_DIR=$(reldir=$(dirname -- "$0"; echo x); reldir=${reldir%?x}; cd -- "$reldir" && pwd && echo x); CURRENT_DIR=${CURRENT_DIR%?x}
BASE_DIR=$(basename $CURRENT_DIR)
PARENT_DIR=${CURRENT_DIR%"${BASE_DIR}"}
RAW_MODE="${RAW_MODE:-false}"

# Find location of package.json
if [[ -f "${CURRENT_DIR}/package.json" ]]; then
  REQ_PATH="${CURRENT_DIR}/package.json"
  echo "Using package.json from script dir"
elif [[ -f "${PARENT_DIR}/package.json" ]]; then
  REQ_PATH="${PARENT_DIR}/package.json"
  SUBDIR_MODE="True"
  echo "Using package.json from ../"
elif [[ -f "${PARENT_DIR}/function/package.json" ]]; then
  REQ_PATH="${PARENT_DIR}/function/package.json"
  SUBDIR_MODE="True"
  echo "Using package.json from ../function"
else
  echo "Unable to find package.json"
  exit 1
fi

# Find location of _clean.sh
if [[ -f "${CURRENT_DIR}/_clean.sh" ]]; then
  CLEAN_PATH="${CURRENT_DIR}/_clean.sh"
  echo "Using clean.sh from script dir"
elif [[ -f "${PARENT_DIR}/_clean.sh" ]]; then
  CLEAN_PATH="${PARENT_DIR}/_clean.sh"
  echo "Using clean.sh from ../"
elif [[ -f "${CURRENT_DIR}/$(dirname "${BASH_SOURCE[0]}")/_clean.sh" ]]; then
  CLEAN_PATH="${PARENT_DIR}/$(dirname "${BASH_SOURCE[0]}")/_clean.sh"
  echo "Using clean.sh from ../$(dirname "${BASH_SOURCE[0]}")"
else
  echo "Using default cleaning step"
fi

if [[ "$RAW_MODE" = true ]]; then
  echo "Using RAW mode"
else 
  echo "Using ZIP mode"
fi

# Run build
docker run --rm -e NODEJS_RUNTIME_VERSION="$NODEJS_RUNTIME_VERSION" -e NAME="$NAME" -e RAW_MODE="$RAW_MODE" -e PARENT_DIR="${PARENT_DIR}" -e SUBDIR_MODE="$SUBDIR_MODE" -v "$CURRENT_DIR":/var/task -v "$REQ_PATH":/temp/build/package.json -v "$CLEAN_PATH":/temp/build/_clean.sh "lambci/lambda:build-nodejs${NODEJS_RUNTIME_VERSION}" bash /var/task/_make.sh

# Move ZIP to parent dir if SUBDIR_MODE set
if [[ "$SUBDIR_MODE" ]]; then
  ZIP_FILE="${NAME}_node${NODEJS_RUNTIME_VERSION}.zip"
  # Make backup of zip if exists in parent dir
  if [[ -f "${PARENT_DIR}/${ZIP_FILE}" ]]; then
    mv "${PARENT_DIR}/${ZIP_FILE}" "${PARENT_DIR}/${ZIP_FILE}.bak"
  fi
  if [[ "$RAW_MODE" != true ]]; then
    mv "${CURRENT_DIR}/${ZIP_FILE}" "${PARENT_DIR}"
  fi
fi