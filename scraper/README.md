# Dallas Police Web Scraper

A PhantomJS script which goes out to the Dallas Police media page. It downloads each page separately and merges them all into a tab-delimited output.

## Execution

Run the following command in this directory to generate an `out.txt` file with the scraped data. Note that it will take at least 5 seconds per page of data to load. 

```
phantomjs scraper.js
```

Tested on version 1.9.1 of PhantomJS.