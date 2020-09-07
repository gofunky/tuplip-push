#!/bin/sh

export TAGS=""
export REPOSITORY="$INPUT_REPOSITORY"
export BUILD_PUSH="push"
export STRAIGHT=""
export VERSION=""
export SOURCE="$GITHUB_JOB"
export ARGS=""
export FILTER=""

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse inputs
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -n "$INPUT_STRAIGHT" ]; then
  IFS="
  "
  for arg in $INPUT_STRAIGHT; do
    if [ -n "$STRAIGHT" ]; then
      STRAIGHT="$STRAIGHT,$arg"
    else
      STRAIGHT="$arg"
    fi
  done
  unset IFS
fi

if [ -n "$INPUT_FILTER" ]; then
  IFS="
  "
  for arg in $INPUT_FILTER; do
    if [ -n "$FILTER" ]; then
      FILTER="$FILTER,$arg"
    else
      FILTER="$arg"
    fi
  done
  unset IFS
fi

if [ -n "$INPUT_ROOTVERSION" ]; then
  VERSION="$INPUT_ROOTVERSION"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Verify Dockerfile
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# If any repository is given, and if the Dockerfile has a default repository defined, then ensure they are equal.
if [ -n "$REPOSITORY" ]; then
  if grep -q "ARG REPOSITORY=" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
    if ! grep -q "ARG REPOSITORY=$REPOSITORY" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
      if ! grep -q "ARG REPOSITORY='$REPOSITORY'" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
        if ! grep -q "ARG REPOSITORY="'"'"$REPOSITORY"'"' "$INPUT_PATH/$INPUT_DOCKERFILE"; then
          echo "::error:: the Dockerfile '$INPUT_PATH/$INPUT_DOCKERFILE' contains a different ARG REPOSITORY
          than given in the action config"
          exit 6
        fi
      fi
    fi
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Prepare Dockerfile
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if ! grep -q "ARG REPOSITORY" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
  echo "ARG REPOSITORY='$REPOSITORY'" >> "$INPUT_PATH/$INPUT_DOCKERFILE"
fi

if ! grep -q "ARG VERSION" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
  echo "ARG VERSION='$VERSION'" >> "$INPUT_PATH/$INPUT_DOCKERFILE"
fi

if ! grep -q "LABEL fun.gofunky.tuplip.repository" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
  # use Dockerfile-internal $REPOSITORY
  # shellcheck disable=SC2016
  echo 'LABEL fun.gofunky.tuplip.repository="$REPOSITORY"' >> "$INPUT_PATH/$INPUT_DOCKERFILE"
fi

if ! grep -q "LABEL fun.gofunky.tuplip.version" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
  # use Dockerfile-internal $VERSION
  # shellcheck disable=SC2016
  echo 'LABEL fun.gofunky.tuplip.version="$VERSION"' >> "$INPUT_PATH/$INPUT_DOCKERFILE"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Login to Docker repository if necessary
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -n "$INPUT_BUILDONLY" ]; then
  BUILD_PUSH="tag"
else
  echo "Logging into Docker registry..."
  if [ -n "$INPUT_USERNAME" ]; then
    if [ -z "$INPUT_PASSWORD" ]; then
      echo "::error:: input 'password' is not set even though 'username' is"
      exit 22
    fi
    echo "$INPUT_PASSWORD" | docker login -u "$INPUT_USERNAME" --password-stdin
  else
    # Relogin will succeed if the user authenticated before this action
    if ! docker login | grep -iq 'succeeded';
    then
      echo "::error:: docker was not logged in and no credentials were provided"
      exit 13
    fi
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Build docker image
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -n "$INPUT_BUILDSCRIPT" ]; then
  if [ -z "$INPUT_SOURCETAG" ]; then
    echo "::error:: input 'sourceTag' is not set even though 'buildScript' is"
    exit 22
  fi

  echo "Executing given build script..."
  sh "$INPUT_BUILDSCRIPT"
fi

if [ -n "$INPUT_SOURCETAG" ]; then
  SOURCE="$INPUT_SOURCETAG"
  if [ -z "$INPUT_BUILDSCRIPT" ]; then
    echo "Skipping docker build..."
  fi
else
  if [ -n "$INPUT_BUILDARGS" ]; then
    IFS="
    "
    for arg in $INPUT_BUILDARGS; do
      ARGS="$ARGS --build-arg $arg"
    done
    unset IFS
  fi

  echo "Executing docker build..."
  docker build -t "$SOURCE" -f "$INPUT_PATH/$INPUT_DOCKERFILE" ${VERSION:+--build-arg VERSION} \
  ${REPOSITORY:+--build-arg REPOSITORY} $ARGS "$INPUT_PATH"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Inspect docker image
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -z "$REPOSITORY" ]; then
  if ! REPOSITORY=$(docker inspect --format '{{ index .Config.Labels "fun.gofunky.tuplip.repository" }}' "$SOURCE");
  then
    echo "::error:: target repository was neither given nor detected in the docker image"
    exit 61
  fi
fi

if [ -z "$VERSION" ]; then
  if ! VERSION=$(docker inspect --format '{{ index .Config.Labels "fun.gofunky.tuplip.version" }}' "$SOURCE");
  then
    echo "::error:: root version was neither given nor detected in the docker image"
    exit 61
  fi
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Executing tuplip
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo "Executing tuplip $BUILD_PUSH..."

if [ -n "$STRAIGHT" ]; then
  TAGS=$( \
    echo "$STRAIGHT" | tuplip $BUILD_PUSH "$SOURCE" ${REPOSITORY:+to "$REPOSITORY"} from stdin \
    --verbose --straight --separator="," ${INPUT_CHECKSEMVER:+--check-semver} \
    ${INPUT_ADDLATEST:+--add-latest} ${INPUT_EXCLUSIVELATEST:+--exclusive-latest} \
  )
else
  TAGS=$( \
    tuplip $BUILD_PUSH "$SOURCE" ${REPOSITORY:+to "$REPOSITORY"} from file "$INPUT_PATH/$INPUT_DOCKERFILE" \
    --verbose ${INPUT_EXCLUDEMAJOR:+--exclude-major} ${INPUT_EXCLUDEMINOR:+--exclude-minor} \
    ${INPUT_EXCLUDEBASE:+--exclude-base} ${INPUT_ADDLATEST:+--add-latest} ${INPUT_EXCLUSIVELATEST:+--exclusive-latest} \
    ${INPUT_CHECKSEMVER:+--check-semver} ${VERSION:+--root-version "$VERSION"} ${FILTER:+--filter "$FILTER"} \
  )
fi

STATUS="$?"

# Workaround until actions/toolkit#403 is resolved
# shellcheck disable=SC2039
TAGS="${TAGS//'%'/'%25'}"
# shellcheck disable=SC2039
TAGS="${TAGS//$'\n'/'%0A'}"
# shellcheck disable=SC2039
TAGS="${TAGS//$'\r'/'%0D'}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logout of Docker repository
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# This is supposed to prevent accidental caching of a Docker image with a valid login
echo "Logging out of Docker registry..."
docker logout

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check status and store outputs
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ "$STATUS" -eq 0 ]; then
  echo "::set-output name=tags::$TAGS"
else
  echo "::error:: tuplip command did not succeed"
  exit 1
fi
