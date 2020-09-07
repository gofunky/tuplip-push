export NAME="Build Test"
docker build -t "testTag" -f "./WithoutRepository.Dockerfile" ${VERSION:+--build-arg VERSION} \
${REPOSITORY:+--build-arg REPOSITORY} --build-arg NAME .
