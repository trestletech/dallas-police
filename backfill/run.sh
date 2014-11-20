#!/bin/bash

if [ $# -eq 0 ]; then
  echo "You must pass in the number of API calls you want to use."
  exit 1
fi

# Update data
echo "Synchronizing downloads to make sure we have the latest..."
(cd ../download && ./download.sh)

Rscript backfill.R ../download/2014/ pointer.txt $@

# backup cache
aws s3 cp ../scraper/cache.Rds s3://dallas-police/home-cache.Rds

aws s3 sync ../download/2014/ s3://dallas-police/2014
