#!/bin/bash

IMAGE=$(echo $1 | cut -d':' -f 1)
TAG=$(echo $1 | cut -d':' -f 2)
if [ "$TAG" == "$IMAGE" ]; then
    TAG="latest"
fi

docker pull $IMAGE:$TAG > /dev/null || exit 1
clair-container-scan.sh -p $IMAGE:$TAG > /dev/null
VULN=$?
if [ $VULN -eq 1 ]
then
    echo $IMAGE:$TAG has CVEs
    echo Trying to rebuild it
    ./rebuild.sh $IMAGE:$TAG
    clair-container-scan.sh ${IMAGE}:${TAG}_rebuild && echo Rebuilding fixed all CVEs
else
    echo $IMAGE:$TAG has no CVEs
fi
