# Golioth Native Sim (Zephyr)

Build container:
```
docker build --secret id=cert,src=$HOME/.golioth/golioth.cert.pem --secret id=key,src=$HOME/.golioth/golioth.key.pem -t golioth_nsim:latest .
```

Where `golioth.cert.pem` & `golioth.key.pem` are Root certificates uploaded to the console. See more [here](https://docs.golioth.io/firmware/golioth-firmware-sdk/authentication/certificate-auth).