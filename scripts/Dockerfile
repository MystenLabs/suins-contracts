FROM rust:latest

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends jq vim 

COPY functions.sh /
COPY entrypoint.sh /

RUN mkdir /sui_config
COPY client.yaml /sui_config/client.yaml

WORKDIR /

ENTRYPOINT [ "./entrypoint.sh" ]
