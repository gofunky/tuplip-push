#!/bin/sh

export TAGS=""
export REPOSITORY=""
export BUILD_PUSH="push"
export STRAIGHT=""
export VERSION=""
export SOURCE="$GITHUB_WORKFLOW"
export ARGS=""
export FILTER=""

if [ -n "$INPUT_FILTER" ]; then
  IFS="
  "
  for arg in $INPUT_FILTER; do
    if [ -n "$FILTER" ]; then
      FILTER="$FILTER,$arg"
    else
      FILTER="$FILTER"
    fi
  done
  unset IFS
fi

if [ -n "$INPUT_ROOTVERSION" ]; then
  VERSION="$INPUT_ROOTVERSION"
fi

if [ -n "$INPUT_BUILDONLY" ]; then
  BUILD_PUSH="build"
  SOURCE=""
else

  if ! grep -q "ARG REPOSITORY=" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
    REPOSITORY="$INPUT_REPOSITORY"
  else
    if ! grep -q "ARG REPOSITORY=$INPUT_REPOSITORY" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
      if ! grep -q "ARG REPOSITORY='$INPUT_REPOSITORY'" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
        if ! grep -q "ARG REPOSITORY="'"'"$INPUT_REPOSITORY"'"' "$INPUT_PATH/$INPUT_DOCKERFILE"; then
          echo "::error The Dockerfile '$INPUT_PATH/$INPUT_DOCKERFILE' contains a different ARG REPOSITORY
          than given in the action config!"
          exit 6
        fi
      fi
    fi
  fi

  if [ -n "$INPUT_USERNAME" ]; then
    if [ -z "$INPUT_PASSWORD" ]; then
      echo "::error Input 'password' is not set even though 'username' is!"
      exit 22
    fi

    echo "Logging into Docker registry..."
    echo "$INPUT_PASSWORD" | docker login -u "$INPUT_USERNAME" --password-stdin
  fi

  if [ -n "$INPUT_STRAIGHT" ]; then
    STRAIGHT="--straight"
  fi
fi

if [ -n "$INPUT_SOURCETAG" ]; then
  SOURCE="$INPUT_SOURCETAG"
  echo "Skipping docker build..."
else
  if [ -n "$INPUT_BUILDARGS" ]; then
    IFS="
    "
    for arg in $INPUT_BUILDARGS; do
      ARGS="$ARGS --build-arg $arg "
    done
    unset IFS
  fi

  echo "Executing docker build..."
  docker build -t "$SOURCE" -f "$INPUT_PATH/$INPUT_DOCKERFILE" ${VERSION:+--build-arg VERSION} \
  ${REPOSITORY:+--build-arg "$REPOSITORY"} $ARGS "$INPUT_PATH"
fi

echo "Executing tuplip $BUILD_PUSH..."

TAGS=$(tuplip $BUILD_PUSH ${REPOSITORY:+to "$REPOSITORY"} from file "$INPUT_PATH/$INPUT_DOCKERFILE" \
--verbose ${INPUT_EXCLUDEMAJOR:+--exclude-major} ${INPUT_EXCLUDEMINOR:+--exclude-minor} \
${INPUT_EXCLUDEBASE:+--exclude-base} ${INPUT_ADDLATEST:+--add-latest} ${INPUT_EXCLUSIVELATEST:+--exclusive-latest} \
$STRAIGHT ${VERSION:+--root-version "$VERSION"} ${FILTER:+--filter "$FILTER"})

STATUS="$?"

# This is supposed to prevent accidental caching of a Docker image with a valid login
echo "Logging out of Docker registry..."
docker logout

if [ "$STATUS" -eq 0 ]; then
  echo "::set-output name=tags::$TAGS"
else
  echo "::error tuplip command did not succeed!"
  exit 1
fi
