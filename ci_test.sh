#!/usr/bin/env bash

set -e
NODE_PRE=pxc-node
GALERA_TAG=${GALERA_TAG:-galera}

function get_node_ip() {
  node=$1
  docker inspect ${node} | jq -r ".[].NetworkSettings.IPAddress"
}

function start_node() {

  nodeid=$1
  debug=$2

  case ${nodeid} in
  1)
    node=${NODE_PRE}1
    extra_opts=" --name ${node} "
    ;;
  2)
    node=${NODE_PRE}2
    extra_opts=" --name ${node} -e USE_IP=true "
    ip1=$(get_node_ip ${NODE_PRE}1)
    extra_opts="${extra_opts} -e PXC_NODE1_SERVICE_HOST=${ip1} --link ${NODE_PRE}1:${NODE_PRE}1"
    ;;
  3)
    node=${NODE_PRE}3
    extra_opts=" --name ${node} -e USE_IP=true "
    ip1=$(get_node_ip ${NODE_PRE}1)
    ip2=$(get_node_ip ${NODE_PRE}2)
    extra_opts="${extra_opts} -e PXC_NODE1_SERVICE_HOST=${ip1} --link ${NODE_PRE}1:${NODE_PRE}1"
    extra_opts="${extra_opts} -e PXC_NODE2_SERVICE_HOST=${ip2} --link ${NODE_PRE}2:${NODE_PRE}2"
    ;;
  esac

  docker stop ${node} 2>/dev/null|| true
  docker rm ${node} 2>/dev/null|| true

  docker run -it \
    ${extra_opts} \
    -d \
    -e DETECT_MASTER_IF_DOWN="true" \
    -e WSREP_SST_PASSWORD="NDNBMTcwMjctR" \
    -e MYSQL_PASSWORD="1NzMtN0Mz" \
    -e MYSQL_ROOT_PASSWORD="fdsgfdh43827" \
    -e GALERA_CLUSTER=true \
    -v ${PWD}/docker-entrypoint.sh:/entrypoint.sh \
    -v ${PWD}/recover_service:/opt/recover_service \
    -e WSREP_CLUSTER_ADDRESS=gcomm:// \
    ${GALERA_TAG} ${debug}
}

docker build -t ${GALERA_TAG} .

start_node $@
