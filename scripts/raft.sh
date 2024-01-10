#!/bin/bash

cd /local/rs-paxos
cd .. & git clone https://github.com/Bompedy/RS-Paxos.git

git config --global --add safe.directory /local/rs-paxos/ETCD
git config --global --add safe.directory /local/rs-paxos/PineappleGo
git config --global --add safe.directory /local/rs-paxos/RabiaGo
git config --global --add safe.directory /local/rs-paxos/RS-Paxos.git

cd RS-Paxos
git stash && git stash clear && git pull
cd ../ETCD
git stash && git stash clear && git pull

HOST=$(hostname | awk -F "." '{print $1}')
echo "Hostname: $HOST"


if [ $HOST = "node-1" ]; then
    IP="10.10.1.1"
elif [ $HOST = "node-2" ]; then
    IP="10.10.1.2"
elif [ $HOST = "node-3" ]; then
    IP="10.10.1.3"
elif [ $HOST = "node-4" ]; then
    IP="10.10.1.4"
elif [ $HOST = "node-5" ]; then
    IP="10.10.1.5"
fi
echo "Local IP: $IP"

#if [ "$1" = "raft" ]; then
export PINEAPPLE="false"
export RS_PAXOS="false"
export SETUP="--initial-cluster node-1=http://10.10.1.1:12380,node-2=http://10.10.1.2:12380,node-3=http://10.10.1.3:12380,node-4=http://10.10.1.4:12380,node-5=http://10.10.1.5:12380"
#elif [ "$1" = "paxos" ]; then
#  export RS_PAXOS="true"
#else
#  export PINEAPPLE="true"
#fi

#process_info=$(ps aux | grep "$script_name" | grep -v grep)
#if [ -n "$process_info" ]; then
#  echo "Process is running: $process_info"
#else
#  echo "Process is not running."
#fi

sudo rm -rf "$HOST.etcd"
make build
pwd
sudo ./bin/etcd --log-level panic \
--name "$HOST" \
--initial-cluster-token etcd-cluster-1 \
--listen-client-urls http://"$IP":2379,http://127.0.0.1:2379 \
--advertise-client-urls http://"$IP":2379 \
--initial-advertise-peer-urls http://"$IP":12380 \
--listen-peer-urls http://"$IP":12380 \
--quota-backend-bytes 20000000000 \
--snapshot-count 0 \
--max-request-bytes 104857600 \
$SETUP \
--initial-cluster-state new
