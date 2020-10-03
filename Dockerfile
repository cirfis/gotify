FROM golang:buster as build-env
## Download and Extract
ADD https://github.com/gotify/server/archive/v2.0.19.tar.gz ./
RUN tar -xzavf v2.0.19.tar.gz

RUN cd server-2.0.19 && go build -a -o ../gotify-app .

FROM ubuntu

WORKDIR /app/

COPY --from=build-env /go/gotify-app ./
ENV GOTIFY_SERVER_PORT="8600"
EXPOSE 8600
ENTRYPOINT ["./gotify-app"]
