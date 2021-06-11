FROM golang:alpine as go-build-1

WORKDIR /opt/
ENV GO111MODULE=on
RUN apk add --no-cache bash git build-base && git clone https://github.com/gotify/server.git /opt/server && cd server && make download-tools && go get -d 

FROM node:alpine as node-build
COPY --from=go-build-1 /opt/ /opt
WORKDIR /opt/server/
RUN apk add --no-cache chromium-chromedriver && cd /opt/server/ui && yarn && yarn build

FROM golang:alpine as go-build-2
COPY --from=node-build /opt/server/. /opt/server/
WORKDIR /opt/server/
RUN apk add --no-cache bash build-base \
    && go run hack/packr/packr.go \
    && export LD_FLAGS="-w -s -X main.Version=$(git describe --tags | cut -c 2-) -X main.BuildDate=$(date "+%F-%T") -X main.Commit=$(git rev-parse --verify HEAD) -X main.Mode=prod" \
    && go build -ldflags="$LD_FLAGS" -o gotify-server


FROM alpine:3.13
RUN apk add --no-cache tzdata ca-certificates bash curl
WORKDIR /app/
COPY --from=go-build-2 /opt/server/gotify-server ./
ENV GOTIFY_SERVER_PORT="8600"
EXPOSE 8600
ENTRYPOINT ["./gotify-server"]
