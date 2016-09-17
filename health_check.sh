#!/bin/bash

. env.sh

ISSUE=false
FIXED=false

if [ -z "$(docker ps -aq --filter name=www-apmelton-com)" ]; then
    ISSUE=true
    . deploy.sh
fi

if [ -z "$(docker ps -q --filter name=www-apmelton-com)" ]; then
    ISSUE=true
    docker start www-apmelton-com
    . nginx_head.sh
fi

if [ -z "$(docker ps -q --filter name=www-apmelton-com)" ]; then
    FIXED=true
fi

if [ "${ISSUE}" = 'true' ] && [ "${FIXED}" = 'true' ]; then
    exit 2
elif [ "${ISSUE}" = 'true' ] && [ "${FIXED}" = 'false' ]; then
    exit 1
else
    exit 0
fi
