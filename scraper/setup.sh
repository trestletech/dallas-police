yum install R-core R-core-devel libcurl-devel git gcc -y
wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
tar -jxvf phantomjs-1.9.7-linux-x86_64.tar.bz2

# Interactive
git clone https://github.com/trestletech/dallas-police.git

sudo su - \
  -c "R -e \"install.packages(c('httr', 'RJSONIO', 'rjson'), repos='http://cran.rstudio.com/')\""

# Add the following to the crontab
( cd /home/ec2-user/dallas-police/scraper/ && ./exec.sh )

