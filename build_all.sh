#!/bin/bash

for i in *.json; do
    ./build.sh $i
done

./build_update_repo.sh
