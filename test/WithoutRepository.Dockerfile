FROM bash:5.0.18 as bash
FROM alpine/semver:5.5.0 as i__me
FROM scratch as mytag
FROM gofunky/git:2.18.4-alpine3.8
ARG VERSION=latest
