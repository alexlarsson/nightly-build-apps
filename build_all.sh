#!/bin/bash

for i in *.json; do
    ./build.sh $i
done

xdg-app build-update-repo  ${EXPORT_ARGS-} repo
