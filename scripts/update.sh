#!/bin/bash

git config --global --add safe.directory /local/etcd/ETCD
git config --global --add safe.directory /local/etcd/PineappleGo
git config --global --add safe.directory /local/etcd/RabiaGo
git config --global --add safe.directory /local/etcd/RS-Paxos
git config --global --add safe.directory /local/etcd/Raft

cd ETCD
cd ../RS-Paxos || exit
git stash && git stash clear && git pull
cd ../Raft || exit
git stash && git stash clear && git pull
cd ../RabiaGo || exit
git stash && git stash clear && git pull
cd ../PineappleGo || exit
git stash && git stash clear && git pull
cd ../ETCD || exit
git stash && git stash clear && git pull

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <nodes> [raft|rs-rabia|rs-paxos|pineapple [memory]]"
  exit 1
fi

nodes=$1

HOST=$(hostname | awk -F "." '{print $1}')
echo "Hostname: $HOST"
for ((i = 1; i <= nodes; i++)); do
  if [ "$HOST" = "node-$i" ]; then
    IP="10.10.1.$i"
    break
  fi
done

echo "Local IP: $IP"


export RS_RABIA="false"
export RS_PAXOS="false"
export PINEAPPLE="false"
export PINEAPPLE_MEMORY="false"
export PARITY = 0
export SEGMENTS = 0

if [ "$2" = "rs-rabia" ]; then
  export RS_RABIA="true"
    if [ "$#" -ge 4 ]; then
      PARITY=$3
      SEGMENTS=$4
    else
      echo "Please provide PARITY and SEGMENTS arguments for 'rs-rabia'."
      exit 1
    fi
elif [ "$2" = "rs-paxos" ]; then
  export RS_PAXOS="true"
    if [ "$#" -ge 4 ]; then
      PARITY=$3
      SEGMENTS=$4
    else
      echo "Please provide PARITY and SEGMENTS arguments for 'rs-paxos'."
      exit 1
    fi
elif [ "$2" = "raft" ]; then
  export SETUP="--initial-cluster "
    for ((i = 1; i <= nodes; i++)); do
      export SETUP+="node-$i=http://10.10.1.$i:12380"
      if [ "$i" -lt "$nodes" ]; then
        export SETUP+=","
      fi
    done
    echo "SETUP: $SETUP"
else
  if [ "$2" = "pineapple" ]; then
    if [ "$3" = "memory" ]; then
      export PINEAPPLE="true"
      export PINEAPPLE_MEMORY="true"
    export PINEAPPLE="true"
    fi
  else
    echo "Invalid argument. Please use 'rs-rabia', 'rs-paxos', 'pineapple', or 'pineapple memory'."
    exit 1
  fi
fi

sudo rm -rf "$HOST.etcd"
make build
sudo ./bin/etcd --log-level panic \
--name "$HOST" \
--initial-cluster-token etcd-cluster-1 \
--listen-client-urls http://"$IP":2379,http://127.0.0.1:2379 \
--advertise-client-urls http://"$IP":2379 \
--initial-advertise-peer-urls http://"$IP":12380 \
--listen-peer-urls http://"$IP":12380 \
--quota-backend-bytes 10000000000 \
--snapshot-count 0 \
--max-request-bytes 104857600 \
$SETUP \
--initial-cluster-state new



