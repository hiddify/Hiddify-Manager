% include('head')

    <div class="alert alert-{{data["out-type"]}}" role="alert" dir="ltr">
      {{!data["out-msg"]}}
    </div>

% if "log-path" in data:
  <div dir="ltr">
  <h1>Logs</h1>
    <a href="{{data['log-path']}}" target="_blank" >Click here to see the complete log</a><br>
    <iframe id='ilog' src="{{data['log-path']}}" style="width:100%;height:500px" onload="document.getElementById('ilog').contentWindow.scrollTo(0,999999)"></iframe>
  </div>
  <script>
  var x=document.getElementById("ilog");
  var orig_log_url=x.src
  function refresh(){
    x.location.replace(orig_log_url+"?random="+Math.random());
    //x.contentWindow.scrollTo( 0, 999999 );
  }
  setInterval(refresh,2000);

  </script>
% end
% include('tail')
