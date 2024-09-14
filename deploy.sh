#!/bin/bash
# This script just for deploying the latest build
# to the living-evidence folder
# Before running this script,
# make sure you have activated the correct conda environment
#
# conda activate node18
#

# build the latest
cd web
npx vite build
cd ..

# remove the old one
echo "* Removing existing files ..."
rm -v -rf ../living-evidence/coe/*

# copy the new one
echo "* Copying newly built files ..."
cp -v -r ./web/dist/* ../living-evidence/coe/