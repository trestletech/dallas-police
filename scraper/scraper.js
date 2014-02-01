// This is a PhantomJS Script

var fs = require('fs');

var page = require('webpage').create();
page.open('http://www.dallaspolice.net/MediaAccess/Default.aspx');
page.onLoadFinished = function(status) {
  page.includeJs("http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js", function() {
    var parStr = page.evaluate(function() {
      var str = '';
      jQuery('table#grdData_ctl01 tbody tr').each(function(ind, val){
        jQuery('td', val).each(function(tdInd, tdVal){
          str += jQuery(tdVal).text() + '\t';
        });
        str += '\n';
      });
      return str;
    });
    
    var file = fs.open("out", "w");
    file.write(parStr);
    file.close();
    phantom.exit();
  });
};
