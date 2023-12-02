FROM golang:alpine

LABEL maintainer="me+proxyserver@devsolux.com"

WORKDIR /etc/proxyserver

COPY . /etc/proxyserver
RUN ./build.sh linux server

EXPOSE 9159/tcp

# this should be a standard user with the users group on alpine
USER 1000:100

CMD ["sh", "-c", "/etc/proxyserver/out/linux-server/proxyserver-server-* --host 0.0.0.0:9159"]
