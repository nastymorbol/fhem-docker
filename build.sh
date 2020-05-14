#!/bin/bash

docker build -t nastymorbol/fhem:buster-slim .
docker run -it -p 8083:8083 --rm --volume "/Users/sschulze/github/fhem_dev/:/opt/fhem/" nastymorbol/fhem:buster-slim
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t nastymorbol/fhem:buster-slim --push .