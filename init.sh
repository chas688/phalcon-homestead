#!/usr/bin/env bash

mkdir -p ~/.phalcon

homesteadRoot=~/.phalcon

cp -i src/Homestead.yaml $homesteadRoot/Homestead.yaml
cp -i src/after.sh $homesteadRoot/after.sh
cp -i src/aliases $homesteadRoot/aliases

echo "Homestead initialized!"
