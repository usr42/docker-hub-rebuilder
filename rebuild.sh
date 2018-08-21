#!/bin/bash

usage() {
    echo usage: $0 IMAGE_NAME
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

IMAGE=$(echo $1 | cut -d':' -f 1)
TAG=$(echo $1 | cut -d':' -f 2)
if [ "$TAG" == "$IMAGE" ]; then
    TAG="latest"
fi
TMPDIR=$(mktemp -d)
JSON_FILE=$TMPDIR/autobuild.json

curl -s -o $JSON_FILE https://hub.docker.com/v2/repositories/$IMAGE/autobuild/

GIT_URL=$(jq -r .source_url $JSON_FILE)
DOCKERFILE_PATH=$(jq -r ".build_tags[] | select(.name==\"$TAG\") | .dockerfile_location" $JSON_FILE)
if [ -z "$DOCKERFILE_PATH" ]; then
    echo Tag \"$TAG\" is not existing for $IMAGE
    rm -rf $TMPDIR
    exit 1
fi
CHECKOUT_TARGET=$(jq -r ".build_tags[] | select(.name==\"$TAG\") | .source_name" $JSON_FILE)

cd $TMPDIR
mkdir git
git clone $GIT_URL git
cd git${DOCKERFILE_PATH}
git checkout $CHECKOUT_TARGET
docker build --pull -t ${IMAGE}:${TAG}_rebuild .
rm -rf $TMPDIR
