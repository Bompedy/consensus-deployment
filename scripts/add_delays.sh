#!/bin/bash
sudo tc qdisc add dev enp6s0f0 root netem delay 5ms

