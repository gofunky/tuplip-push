export TAGS=""
export PUSH_TO=""
export REPOSITORY=""
export BUILD_PUSH="push"
export EXCLUDE_MAJOR=""
export EXCLUDE_MINOR=""
export EXCLUDE_BASE=""
export ADD_LATEST=""
export EXCLUSIVE_LATEST=""
export STRAIGHT=""
export ROOT_VERSION_FLAG=""
export ROOT_VERSION=""
export FILTER_FLAG=""
export FILTER=""

if [ -n "$INPUT_EXCLUDEMAJOR" ]; then
  EXCLUDE_MAJOR="--exclude-major"
fi

if [ -n "$INPUT_EXCLUDEMINOR" ]; then
  EXCLUDE_MINOR="--exclude-minor"
fi

if [ -n "$INPUT_EXCLUDEBASE" ]; then
  EXCLUDE_BASE="--exclude-base"
fi

if [ -n "$INPUT_ADDLATEST" ]; then
  ADD_LATEST="--add-latest"
fi

if [ -n "$INPUT_EXCLUSIVELATEST" ]; then
  EXCLUSIVE_LATEST="--exclusive-latest"
fi

if [ -n "$INPUT_ROOTVERSION" ]; then
  ROOT_VERSION_FLAG="--root-version"
  ROOT_VERSION="$INPUT_ROOTVERSION"
fi

if [ -n "$INPUT_FILTER" ]; then
  FILTER_FLAG="--filter"
  FILTER="$INPUT_FILTER"
fi

if [ -n "$INPUT_BUILDONLY" ]; then
  BUILD_PUSH="build"
else

  if ! grep -q "ARG REPOSITORY=" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
    PUSH_TO="to"
    REPOSITORY="$INPUT_REPOSITORY"
  fi

  if [ -n "$INPUT_USERNAME" ]; then
    if [ -z "$INPUT_PASSWORD" ]; then
      echo "ERROR: Input 'password' is not set even though 'username' is!"
      exit 127
    fi
    docker login -u "$INPUT_USERNAME" -p "$INPUT_PASSWORD"
  fi

  if [ -n "$INPUT_STRAIGHT" ]; then
    STRAIGHT="--straight"
  fi

fi

TAGS=$(
  /usr/local/bin/tuplip $BUILD_PUSH $PUSH_TO "$REPOSITORY" from file "$INPUT_PATH/$INPUT_DOCKERFILE" \
  --verbose $EXCLUDE_MAJOR $EXCLUDE_MINOR $EXCLUDE_BASE $ADD_LATEST $EXCLUSIVE_LATEST $STRAIGHT \
  $ROOT_VERSION_FLAG "$ROOT_VERSION" $FILTER_FLAG "$FILTER"
)

echo "::set-output tags:: $TAGS"
