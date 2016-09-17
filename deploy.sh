#!/bin/bash

. env.sh

docker stop -t 10 www-apmelton-com
docker rm -fv www-apmelton-com

docker run --name www-apmelton-com -d \
    --net ${OVERLAY_NETWORK} \
    --label com.apmelton.webhead.publish=true \
    --label com.apmelton.webhead.icc=true \
    --label 'com.apmelton.webhead.domain=~^(www\.)?apmelton.com' \
    --label com.apmelton.webhead.default=true \
    --restart always \
    ramielrowe/www-apmelton-com

. nginx_head.sh
