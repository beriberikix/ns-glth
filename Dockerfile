FROM ghcr.io/embeddedcontainers/zephyr:posix-0.16.8SDK AS build
WORKDIR /golioth/

COPY . ./app

# Setup Zephyr workspace & dependencies
RUN \
  west init -l app \
  && west update --narrow -o=--depth=1 \
  && west zephyr-export \
  && pip install -r deps/zephyr/scripts/requirements-base.txt

# Build for Native Sim
RUN \
  west build -b native_sim app/