#!/usr/bin/env bash

export BRANCH="$1"

docker build -t kontalk/xmppserver --build-arg BRANCH=${BRANCH} $(dirname $0)/.
