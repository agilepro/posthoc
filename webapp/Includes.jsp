  <link rel="stylesheet" type="text/css" href="fw/bootstrap.css">
  <link rel="stylesheet" type="text/css" href="fw/bootstrap-combined.css">
  <link rel="stylesheet" type="text/css" href="fw/font-awesome/css/font-awesome.min.css">	
  <link rel="stylesheet" type="text/css" href="fw/textAngular.css">
  <link href="posthoc.css" rel="styleSheet" type="text/css"/>
  <script type="text/javascript" src="fw/jquery.js"></script>
  <script type="text/javascript" src="fw/bootstrap.js"></script>
  <script type="text/javascript" src="fw/angular.min.js"></script>
  <script type="text/javascript" src="fw/textAngular-rangy.min.js"></script>
  <script type="text/javascript" src="fw/textAngular-sanitize.min.js"></script>
  <script type="text/javascript" src="fw/textAngular.min.js"></script>    
  <title>Post Hoc</title>
  
  <script>
    //this is completely ridiculous, but there are so many layers
    //of encoding, and it seems impossible to get things to just 
    //work right without interleaving two layers of encoding in 
    //the wrong order.  The documentation does not explain how
    //to disable this, particularly when multipart MIME is involved
    //and there are no controls to control it.
    //
    //This avoide the problem by encoding every as hex digits so that 
    //none of the encoding is encountered
    function thoroughlyEncode(input) {
        var hexDigit = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P'];
        var result = "";
        var lineCount = 0;
        for (var i=0; i<input.length; i++) {
            var ch = input.codePointAt(i);
            var a = ch % 16;
            ch = Math.floor(ch / 16);
            var b = ch % 16;
            ch = Math.floor(ch / 16);
            var c = ch % 16;
            ch = Math.floor(ch / 16);
            var d = ch % 16;
            result = result + hexDigit[d] + hexDigit[c] + hexDigit[b] + hexDigit[a];
            if (++lineCount > 16) {
                result = result + "\n";
                lineCount = 0;
            }
        }
        return result;
    }
  </script>
