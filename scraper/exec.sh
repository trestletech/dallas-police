
PATH=$PATH:/usr/local/bin/

# Clean up last run
killall phantomjs
rm out.txt
rm out-*.csv

phantomjs scraper.js
Rscript geocode.R out.txt

aws s3 cp cache.Rds s3://dallas-police/server-cache.Rds

DATEDIR=`date +%Y/%m-%d`

# Make sure all the files are copied up
for i in out-*.csv; do
    aws s3 cp $i s3://dallas-police/$DATEDIR/
done

# Keep a pointer to the latest one both here and in S3.
cp out-*.csv current.csv
aws s3 cp current.csv s3://dallas-police/ --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers

