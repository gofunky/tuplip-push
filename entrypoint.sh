export TAGS=""
export REPOSITORY=""
export BUILD_PUSH="push"
export STRAIGHT=""
export VERSION=""
export SOURCE="$GITHUB_WORKFLOW"

# TODO Caching (attach entrypoint internal to worker external cache somehow)

if [ -n "$INPUT_ROOTVERSION" ]; then
  VERSION="$INPUT_ROOTVERSION"
fi

if [ -n "$INPUT_SOURCETAG" ]; then
  SOURCE="$INPUT_SOURCETAG"
  echo "Skipping docker build..."
else
  echo "Executing docker build..."
  docker build -t "$SOURCE" -f "$INPUT_DOCKERFILE" ${VERSION:+--build-arg VERSION} "$INPUT_PATH"
  # TODO More build args
fi

if [ -n "$INPUT_BUILDONLY" ]; then
  BUILD_PUSH="build"
  SOURCE=""
  echo "Executing tuplip build..."
else

  if ! grep -q "ARG REPOSITORY=" "$INPUT_PATH/$INPUT_DOCKERFILE"; then
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

  echo "Executing tuplip push..."
fi

TAGS=$(
  /usr/local/bin/tuplip $BUILD_PUSH ${REPOSITORY:+to "$REPOSITORY"} from file "$INPUT_PATH/$INPUT_DOCKERFILE" \
  --verbose ${INPUT_EXCLUDEMAJOR:+--exclude-major} ${INPUT_EXCLUDEMINOR:+--exclude-minor} \
  ${INPUT_EXCLUDEBASE:+--exclude-base} ${INPUT_ADDLATEST:+--add-latest} ${INPUT_EXCLUSIVELATEST:+--exclusive-latest} \
  $STRAIGHT ${VERSION:+--root-version "$VERSION"} ${INPUT_FILTER:+--filter "$INPUT_FILTER"}
)

echo "::set-output tags:: $TAGS"
