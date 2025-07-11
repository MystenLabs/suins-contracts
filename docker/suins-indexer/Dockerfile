FROM rust:1.87.0 AS builder

ARG PROFILE=release
ARG GIT_REVISION
ENV GIT_REVISION=$GIT_REVISION

WORKDIR work

COPY Cargo.lock Cargo.toml ./
COPY indexer/ ./indexer/
COPY docker/suins-indexer/entry.sh ./

RUN apt-get update && apt-get install -y build-essential libssl-dev pkg-config curl cmake clang ca-certificates
ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo build --profile $PROFILE --bin suins-indexer --config net.git-fetch-with-cli=true

FROM debian:bookworm-slim AS runtime

RUN apt-get update
RUN apt-get -y --no-install-recommends install wget \
        iputils-ping procps bind9-host bind9-dnsutils \
        curl iproute2 git ca-certificates libpq-dev \
        postgresql

COPY --from=builder /work/target/release/suins-indexer /opt/mysten/bin/
COPY --from=builder /work/entry.sh .
RUN ["chmod", "+x", "/opt/mysten/bin/suins-indexer"]
RUN ["chmod", "+x", "entry.sh"]

ARG BUILD_DATE
ARG GIT_REVISION
LABEL build-date=$BUILD_DATE
LABEL git-revision=$GIT_REVISION

CMD ["./entry.sh"]
