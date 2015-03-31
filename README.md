dallas-police
=============

A real-time application to monitor the public activity of the Dallas Police. This project consists of two parts: a scraper for collecting the data from [this page](http://www.dallaspolice.net/MediaAccess/Default.aspx) and a [Shiny](http://rstudio.com/shiny/) app for visualizing the data in Leaflet.

## Scraper

Unfortunately, the Dallas Police provide their real-time "Media Access" [page](http://www.dallaspolice.net/MediaAccess/Default.aspx) in a really quirky format that depends on a lot of encrypted state and AJAX calls to update the data in some obscure ASPX system for no real reason </rant>. So to collect the data, you actually need to run a Javascript-enabled browser such as PhantomJS. The scraper consists of a Phantom application and a shell script wrapper which will visit that web site, aggregate the data from all available pages, then return the results as a CSV file.

Once the data has been collected, I upload it to Amazon S3 for easy retrieval by other application.

## Shiny App

Because I store the real-time data in a public S3 location, anyone can download and view it. This Shiny application will download that file from S3 periodically and visualize the results contained therein in a Shiny application backed by Leaflet. The app is hosted online at [https://trestletech.shinyapps.io/dpd-active/](https://trestletech.shinyapps.io/dpd-active/).

## Config

To run this, you'll need to configure your S3 credentials so that the `aws` CLI can work with your S3 bucket. (You'll also need the `aws` tool installed). Also, on OSX I once had a problem not having the region specified. If you run into an error like 

```
HTTPSConnectionPool(host='s3-us-east-1a.amazonaws.com', port=443): Max retries exceeded with url: /my.bucket?delimiter=/&prefix= (Caused by <class 'socket.gaierror'>: [Errno 8] nodename nor servname provided, or not known)
```

then run `aws configure` and specify the region as `us-east-1`.
