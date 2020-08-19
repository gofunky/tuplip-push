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

if [ -n "$INPUT_CACHEFILE" ]; then
  echo "Loading internal Docker layer cache..."
  if [ -f "$INPUT_CACHEFILE" ]; then
    docker load -i "$INPUT_CACHEFILE"
  else
    echo "::warning SKIP: The layer cache doesn't exist yet."
  fi
fi

if [ -n "$INPUT_SOURCETAG" ]; then
  SOURCE="$INPUT_SOURCETAG"
  echo "Skipping docker build..."
else
  echo "Executing docker build..."

  if [ -n "$INPUT_BUILDARGS" ]; then
    IFS="
    "
    for arg in $INPUT_BUILDARGS; do
      ARGS="$ARGS --build-arg $arg "
    done
    unset IFS
  fi

  docker build -t "$SOURCE" -f "$INPUT_DOCKERFILE" ${VERSION:+--build-arg VERSION} $ARGS "$INPUT_PATH"
fi

if [ -n "$INPUT_BUILDONLY" ]; then
  BUILD_PUSH="build"
  SOURCE=""
else

  if ! grep -q "ARG REPOSITORY=" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
    REPOSITORY="$INPUT_REPOSITORY"
  fi

  if [ -n "$INPUT_USERNAME" ]; then
    if [ -z "$INPUT_PASSWORD" ]; then
      echo "::error Input 'password' is not set even though 'username' is!"
      exit 127
    fi

    echo "Logging into Docker registry..."
    docker login -u "$INPUT_USERNAME" -p "$INPUT_PASSWORD"
  fi

  if [ -n "$INPUT_STRAIGHT" ]; then
    STRAIGHT="--straight"
  fi
fi

echo "Executing tuplip $BUILD_PUSH..."

TAGS=$(
  /usr/local/bin/tuplip $BUILD_PUSH ${REPOSITORY:+to "$REPOSITORY"} from file "$INPUT_PATH/$INPUT_DOCKERFILE" \
  --verbose ${INPUT_EXCLUDEMAJOR:+--exclude-major} ${INPUT_EXCLUDEMINOR:+--exclude-minor} \
  ${INPUT_EXCLUDEBASE:+--exclude-base} ${INPUT_ADDLATEST:+--add-latest} ${INPUT_EXCLUSIVELATEST:+--exclusive-latest} \
  $STRAIGHT ${VERSION:+--root-version "$VERSION"} ${FILTER:+--filter "$FILTER"}
)

echo "::set-output tags:: $TAGS"

if [ -n "$INPUT_CACHEFILE" ]; then
  echo "Storing internal Docker layer cache..."
  docker save -o "$INPUT_CACHEFILE"
fi
