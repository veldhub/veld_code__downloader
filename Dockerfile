FROM alpine:latest
RUN apk update
RUN apk add curl
RUN apk add dtrx
RUN apk add file

