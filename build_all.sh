#!/bin/bash

for i in *.json; do
    ./build.sh $i
done
