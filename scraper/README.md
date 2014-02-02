# Dallas Police Web Scraper

A PhantomJS script which goes out to the Dallas Police media page. It downloads each page separately and merges them all into a tab-delimited output.

## Execution

The parent script is `exec.sh`. You can just run that (or schedule it to be run in a cron job). Note that in order to do geolocation, you have to add a MapQuest API key (see [here](http://developer.mapquest.com/web/info/account/app-keys)). You can explicitly provide that in the `exec.sh` script. Otherwise, it will try to read it in from a file named `.mq_key` in this directory.

### Execution of PhantomJS

Run the following command in this directory to generate an `out.txt` file with the scraped data. Note that it will take at least 5 seconds per page of data to load. 

```
phantomjs scraper.js
```

Tested on version 1.9.1 of PhantomJS.

