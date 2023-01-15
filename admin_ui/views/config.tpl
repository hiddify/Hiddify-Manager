% include('head')


<form action='change' method='get' dir="ltr">
    <p>This page is only for configuration purpose.  </p>
    
    <div class="form-group">
    <p>Your IP is {{data["external_ip"]}} Please set this ip in your domain and enter your domain bellow.<br>   
    </p>
        <label>SubDomain <small> *Required</small></label>
        <input type='text'  value='{{data["MAIN_DOMAIN"]}}' class="form-control"  name='MAIN_DOMAIN' placeholder='plese enter your subdomain' /> 
        <small class="form-text text-muted">This field should be correct. Please visit <a href='https://github.com/hiddify/hiddify-config/blob/main/docs/create_domain.md'> Help</a> to learn how to create a subdomain.</small>
    </div>
       
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_TELEGRAM" {{"checked" if data["ENABLE_TELEGRAM"] != "false" else ""}}>
        <label class="form-check-label">Enable Telegram</label>
    </div>
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_VMESS" {{"checked" if data["ENABLE_VMESS"] != "false" else ""}}>
        <label class="form-check-label">Enable VMESS (not recommended)</label>
    </div>
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="BLOCK_IR_SITES" {{"checked" if data["BLOCK_IR_SITES"] != "false" else ""}}>
        <label class="form-check-label">Block Iranian sites to prevent detection by the govenment (recommended).</label>
    </div>
    <div class="form-group">
        <label>Fake site: simulate a site when someone visit your domain (وقتی کسی وارد سایت شما میشه نشان داده میشه) </label>
        <input type='text' value='{{data["TELEGRAM_FAKE_TLS_DOMAIN"]}}'  class="form-control" name='TELEGRAM_FAKE_TLS_DOMAIN' placeholder='plese enter your telegram fake tls domain'" /> 
        <small class="form-text text-muted">Please use a well known domain in your data center. For example, if you are in azure data center, microsoft.com is a good example</small>
    </div>   
    <details>
<summary>Advanced Configs</summary>
    <div class="form-group">
        <label>Fake CDN site: simulate a cdn site (Highly RECOMMENDED). <a href="https://github.com/hiddify/hiddify-config/wiki/fake-cdn-استفاده-از">more info</a> </label>
        <input type='text' value='{{data["FAKE_CDN_DOMAIN"]}}'  class="form-control" name='FAKE_CDN_DOMAIN' placeholder='plese enter your fake CDN domain'" /> 
        <small class="form-text text-muted">You need to register your domain in a CDN provider. Then enter a not filtered domain that used that CDN. </small>
        <small class="form-text text-muted">Tested with arvancloud.ir and cloudflare.com </small>
    </div>   

    <div class="form-group">
        <label>Secret</label>
        <input type='text'  value='{{data["USER_SECRET"]}}' class="form-control" name='USER_SECRET' placeholder='plese enter your user secret'" /> 
        <small class="form-text text-muted">User Secret will be used for your users</small>
    </div>   
    <div class="form-group">
        <label>Admin Secret</label>
        <input type='text' value='{{data["ADMIN_SECRET"]}}'  class="form-control" name='ADMIN_SECRET' placeholder='plese enter your admin secret'" /> 
        <small class="form-text text-muted">Admin Secret will be used for accessing admin panel</small>
    </div>   

    <div class="form-group">
        <label>Shadowsocks Fake TLS Domain</label>
        <input type='text' value='{{data["SS_FAKE_TLS_DOMAIN"]}}'  class="form-control" name='SS_FAKE_TLS_DOMAIN' placeholder='plese enter your shadowsocks fake tls domain'" /> 
        <small class="form-text text-muted">Please use a well known domain in your data center. For example, if you are in azure data center, microsoft-update.com is a good example</small>
        <small class="form-text text-muted">Shadowsocks fake tls and telegram fake tls should be different</small>
    </div>   

    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_FIREWALL" {{"checked"  if data["ENABLE_FIREWALL"] == "false" else ""}}>
        <label class="form-check-label">Enable Firewall</label>
    </div>

    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_NETDATA" {{"checked" if data["ENABLE_NETDATA"] != "false" else ""}}>
        <label class="form-check-label">Enable Netdata. May use your CPU but not too much</label>
    </div>

<!--
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ALLOW_ALL_SNI_TO_USE_PROXY" {{"checked" if data["ALLOW_ALL_SNI_TO_USE_PROXY"] != "false" else ""}}>
        <label class="form-check-label">Allow all sni to use proxy. NOT RECOMMENDED! NOT SAFE</label>
    </div>-->
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_SS" {{"checked" if data["ENABLE_SS"] != "false" else ""}}>
        <label class="form-check-label">Enable Shadowsocks v2ray and faketls (not recomnded)</label>
    </div>
<!--
    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_HTTP_PROXY" {{"checked" if data["ENABLE_HTTP_PROXY"] != "false" else ""}}>
        <label class="form-check-label">Allow port 80 to use as proxy without SSL. NOT RECOMMENDED! NOT SAFE</label>
    </div>
-->
    

    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_AUTO_UPDATE" {{"checked" if data["ENABLE_AUTO_UPDATE"] != "false" else ""}}>
        <label class="form-check-label">Enable Auto Update</label>
    </div>
    </details>
    <input type='submit' value='Submit' class="btn btn-primary">
    

</form>
<style>
.form-check-input[type=checkbox]{
float: left;
margin-right: .5em;
}
</style>
% include('tail')
