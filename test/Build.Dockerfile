FROM alpine/semver:5.5.0 as i__me
FROM scratch as mytag
FROM gofunky/git:2.18.4
ARG VERSION=latest
ARG NAME

LABEL org.label-schema.name="$NAME"
LABEL org.label-schema.version="$VERSION"
LABEL org.label-schema.schema-version="1.0"
