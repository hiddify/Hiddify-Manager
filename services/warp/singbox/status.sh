cd $( dirname -- "$0"; )
function main(){
curl https://cloudflare.com/cdn-cgi/status --connect-timeout 1 -x socks://127.0.0.1:3000

wgcf status

curl -s -x socks://127.0.0.1:3000 --connect-timeout 1 http://ip-api.com?fields=message,country,countryCode,city,isp,org,as,query

}
mkdir -p /opt/hiddify-manager/data/log/system/
main |& tee /opt/hiddify-manager/data/log/system/warp.log
