
# Clean up last run
killall phantomjs
rm out.txt
rm out.csv

if [ -f .mq_key ]
then
  MAPQUEST_KEY=`cat .mq_key`
fi

phantomjs scraper.js
Rscript geolocate.R out.txt $MAPQUEST_KEY

