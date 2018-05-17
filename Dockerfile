# ==============================================================================
# First stage build (compile V8)
# ==============================================================================

FROM debian:stretch-slim as builder

ENV V8_VERSION="6.8.241"

RUN apt-get update && apt-get upgrade -yqq

RUN apt-get install bison \
                    cdbs \
                    curl \
                    flex \
                    g++ \
                    git \
                    python \
                    pkg-config \
                    rlwrap \
                    vim -yqq

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

ENV PATH="/depot_tools:${PATH}"

RUN fetch v8 && \
    cd /v8 && \
    git checkout ${V8_VERSION}
    ./tools/dev/v8gen.py x64.release && \
    ninja -C out.gn/x64.release

# ==============================================================================
# Second stage build
# ==============================================================================

FROM debian:stretch-slim

LABEL v8.version="6.8.241" \
      maintainer="andre.burgaud@gmail.com"

RUN apt-get update && apt-get upgrade -yqq && \
    apt-get install curl rlwrap vim -yqq && \
    apt-get clean

WORKDIR /v8

COPY --from=builder /v8/out.gn/x64.release/d8 \
                    /v8/out.gn/x64.release/natives_blob.bin \
                    /v8/out.gn/x64.release/snapshot_blob.bin ./

COPY entrypoint.sh ./

RUN chmod +x entrypoint.sh && \
    mkdir /examples

ENTRYPOINT ["/v8/entrypoint.sh"]