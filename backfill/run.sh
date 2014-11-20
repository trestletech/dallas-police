#!/bin/bash

# Update data
#(cd ../download && ./download.sh)

if [ $# -eq 0 ]; then
  echo "You must pass in the number of API calls you want to use."
  exit 1
fi

Rscript backfill.R ../download/2014/ pointer.txt $@