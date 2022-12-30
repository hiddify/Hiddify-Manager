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
    <details>
<summary>Advanced Configs</summary>

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
        <label>Telegram Fake TLS Domain</label>
        <input type='text' value='{{data["TELEGRAM_FAKE_TLS_DOMAIN"]}}'  class="form-control" name='TELEGRAM_FAKE_TLS_DOMAIN' placeholder='plese enter your telegram fake tls domain'" /> 
        <small class="form-text text-muted">Please use a well known domain in your data center. For example, if you are in azure data center, microsoft.com is a good example</small>
    </div>   
    <div class="form-group">
        <label>Shadowsocks Fake TLS Domain</label>
        <input type='text' value='{{data["SS_FAKE_TLS_DOMAIN"]}}'  class="form-control" name='SS_FAKE_TLS_DOMAIN' placeholder='plese enter your shadowsocks fake tls domain'" /> 
        <small class="form-text text-muted">Please use a well known domain in your data center. For example, if you are in azure data center, microsoft-update.com is a good example</small>
        <small class="form-text text-muted">Shadowsocks fake tls and telegram fake tls should be different</small>
    </div>   

    <div class="form-group">
        <label>If you are using CDN, which CDN you are using</label>
        <select class="form-control" name="CDN_NAME">
        <option value="" {{"selected" if data["CDN_NAME"] == "" else "" }} >No CDN</option>
        <option value="ar" {{"selected" if data["CDN_NAME"] == "ar" else "" }} >ArvanCloud</option>
        <option value="cf" {{"selected" if data["CDN_NAME"] == "cf" else "" }} >Cloudflare</option>
        </select>
        <small class="form-text text-muted">This will be used only for translating proxy ips for better report</small>
    </div>   

    <div class="form-check">
        <input type="checkbox" class="form-check-input" name="ENABLE_FIREWALL" {{"checked"  if data["ENABLE_FIREWALL"] == "false" else ""}}>
        <label class="form-check-label">Enable Firewall</label>
    </div>
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
