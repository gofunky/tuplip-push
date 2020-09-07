FROM alpine/semver:5.5.0 as i__me
FROM scratch as mytag
FROM gofunky/git:2.18.4
ARG VERSION=latest
ARG NAME
ARG TEST_ARG

RUN [ -n "$TEST_ARG" ] || { echo "TEST_ARG has to be given!"; exit 1 }

LABEL org.label-schema.name=$NAME
LABEL org.label-schema.version=$VERSION
LABEL org.label-schema.schema-version="1.0"
