#!/bin/bash

for i in *.def; do
    ./build.sh $i
done

ostree summary -u --repo=repo
