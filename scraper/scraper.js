// This is a PhantomJS Script

var fs = require('fs');

var page = require('webpage').create();
page.open('http://www.dallaspolice.net/MediaAccess/Default.aspx');
page.onLoadFinished = function(status) {
  page.includeJs("http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js", function() {
    evalNext('', function(str){
      exit(str);
    }, true);
  });
};

var first = true;
var pageNum = 0;
var evalNext = function(str, callback, suppressNext){
  var hasNext = true;
  if (!suppressNext){
    hasNext = page.evaluate(nextPage);
  }
  
  if (hasNext){
    console.log("Got a new page. Waiting 3 sec.");
    // There is another page and it's loading.
    setTimeout(function(){
      pageNum++;
      page.render("page-" + pageNum + ".png");
      str += page.evaluate(getPage);
      evalNext(str, function(cbStr){
        callback(cbStr);
      });
    }, 3000);
  } else{
    console.log("No new page. Exiting");
    // return immediately.
    callback(str);
  }
}



var exit = function(str){
  console.log("Exiting");
  var file = fs.open("out.txt", "w");
  file.write(str);
  file.close();
  
  phantom.exit();    
}

var nextPage = function(){
  var btn = jQuery('tr.GridPager_Mac td a[title="Next Page"]');
  
  if (btn.length == 1){
    // Then we have a next page to go to
    eval(jQuery(btn[0]).attr("href").replace(/^javascript:/, ''));
    return true;
  }
  return false;
}

var getPage = function() {
  var str = '';
  jQuery('table#grdData_ctl01 tbody tr').each(function(ind, val){
    jQuery('td', val).each(function(tdInd, tdVal){
      str += jQuery(tdVal).text() + '\t';
    });
    str += '\n';
  });
  return str;
}