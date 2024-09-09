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

FROM golang:latest as provision
WORKDIR /golioth/
COPY --from=build /golioth/build/zephyr/zephyr.exe zephyr.exe

# Install OpenSSL
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  openssl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Create and sign device certificates
RUN \
  --mount=type=secret,id=cert,target=/root/.golioth/golioth.cert.pem \
  --mount=type=secret,id=key,target=/root/.golioth/golioth.key.pem \
  PROJECT_SLUG='demos' \
  && CERTIFICATE_ID='docker1' \
  && SERVER_NAME='golioth' \
  && CLIENT_NAME="${PROJECT_SLUG}-${CERTIFICATE_ID}" \
  && openssl ecparam -name prime256v1 -genkey -noout -out "${CLIENT_NAME}.key.pem" \
  && openssl req -new \
  -key "${CLIENT_NAME}.key.pem" \
  -subj "/O=${PROJECT_SLUG}/CN=${CERTIFICATE_ID}" \
  -out "${CLIENT_NAME}.csr.pem" \
  && openssl x509 -req \
  -in "${CLIENT_NAME}.csr.pem" \
  -CA /root/.golioth/golioth.cert.pem \
  -CAkey /root/.golioth/golioth.key.pem \
  -CAcreateserial \
  -out "${CLIENT_NAME}.crt.pem" \
  -days 500 -sha256 \
  && openssl x509 -in ${CLIENT_NAME}.crt.pem -outform DER -out ${CLIENT_NAME}.crt.der \
  && openssl ec -in ${CLIENT_NAME}.key.pem -outform DER -out ${CLIENT_NAME}.key.der \
  && rm ${CLIENT_NAME}.crt.pem ${CLIENT_NAME}.key.pem ${CLIENT_NAME}.csr.pem

# Save credentials via mcumgr
RUN \
  go install github.com/apache/mynewt-mcumgr-cli/mcumgr@latest
# && mkfifo input.pipe \
# && ./zephyr.exe < input.pipe &
# && PID=$!
# && echo "fs mkdir /lfs1/credentials" > input.pipe
# && kill $PID
# && echo "log halt" > input.pipe \
# && mcumgr \
# --conntype serial \
# --connstring=dev=/dev/pts/1,baud=115200 \
# fs \
# upload \
# demos-docker1.crt.der \
# /lfs1/credentials/client_cert.der
# && mcumgr \
# --conntype serial \
# --connstring=dev=/dev/pts/0,baud=115200 \
# fs \
# upload \
# demos-docker1.key.der \
# /lfs1/credentials/private_key.der