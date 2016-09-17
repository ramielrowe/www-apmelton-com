#!/bin/bash

function get_container_host_port {
   echo "$(docker port ${1} 80)"
}

function get_container_variables {
    LABELS_TEMPLATE='{{range $key, $value := .Config.Labels}}{{ $key }} {{ $value }}{{ "\n" }}{{ end }}'
    ICC_HOST_TEMPLATE='{{ "com.apmelton.webhead.icc.host" }} {{.NetworkSettings.Networks.'"${OVERLAY_NETWORK}"'.IPAddress}}'
    echo "$(docker inspect -f "${LABELS_TEMPLATE}${ICC_HOST_TEMPLATE}" ${1})"
}

function get_container_variable {
    while read -r line; do
        label=$(cut -d " " -f 1 <<< ${line})
        value=$(cut -d " " -f 2 <<< ${line})
        if [ "$label" == "${1}" ]; then
            echo "${value}"
            break
        fi
    done <<< "${2}"
}

if [ -z "${NO_PULL}" ]; then
    docker pull ramielrowe/nginx_head
fi

if [ -z "$(docker ps -aq --filter name=nginx_head_volume)" ]; then
    docker create --name nginx_head_volume \
        --volume /etc/nginx \
        nginx
fi

PUBLISH_IDS=$(docker ps -q --filter label=com.apmelton.webhead.publish=true)
DOMAIN_MAPPINGS="--domain-mappings"
DEFAULT_DOMAIN=""

for ID in $PUBLISH_IDS; do
    CONTAINER_VARS="$(get_container_variables $ID)"
    CUR_DOMAIN=$(get_container_variable 'com.apmelton.webhead.domain' "${CONTAINER_VARS}")
    IS_DEFAULT=$(get_container_variable 'com.apmelton.webhead.default' "${CONTAINER_VARS}")
    IS_ICC=$(get_container_variable 'com.apmelton.webhead.icc' "${CONTAINER_VARS}")

    if [ "${IS_ICC}" == "true" ]; then
       ICC_HOST=$(get_container_variable 'com.apmelton.webhead.icc.host' "${CONTAINER_VARS}")
       ICC_PORT=$(get_container_variable 'com.apmelton.webhead.icc.port' "${CONTAINER_VARS}")
       if [ -z "${ICC_PORT}" ]; then
           ICC_PORT=80
       fi
       DOMAIN_MAPPINGS="${DOMAIN_MAPPINGS} ${CUR_DOMAIN}=${ICC_HOST}:${ICC_PORT}"
    else
       DOMAIN_MAPPINGS="${DOMAIN_MAPPINGS} ${CUR_DOMAIN}=$(get_container_host_port $ID)"
    fi

    if [ "${IS_DEFAULT}" = "true" ]; then
        DEFAULT_DOMAIN="--default ${CUR_DOMAIN}"
    fi
done

docker run --rm --volumes-from nginx_head_volume ramielrowe/nginx_head $DOMAIN_MAPPINGS $DEFAULT_DOMAIN $@

NETWORK=""
if [ -n "${OVERLAY_NETWORK}" ]; then
    NETWORK="--net ${OVERLAY_NETWORK}"
fi

if [ -z "$(docker ps -q --filter name=nginx_head)" ]; then
    docker run --name nginx_head \
        -d --restart=always \
        --volumes-from nginx_head_volume \
        ${NETWORK} \
        -p 80:80 \
        nginx
else
    docker kill -s HUP nginx_head
fi
