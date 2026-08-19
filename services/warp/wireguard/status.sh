cd $( dirname -- "$0"; )
source /opt/hiddify-manager/scripts/common/utils.sh

function main(){

# curl -s --interface warp https://cloudflare.com/cdn-cgi/status --connect-timeout 1
warning "- Warp Status:"
warning "  - Profile:"
status=$(./wgcf status 2>&1)
if [ $? -eq 0 ]; then
    echo "$status" | sed 's|^|\t|'
else
    echo -e "$status" | head -n 2 | sed 's|^|\t|'
fi

warning "  - Network:"
curl -s --interface warp --connect-timeout 1 http://ip-api.com?fields=country,city,org,query | sed 's|^|      | ; /[{}]/d'
# warning "  - Warp Trace:"
# curl -s --interface warp https://cloudflare.com/cdn-cgi/trace --connect-timeout 1 | sed 's|^|\t|'
}

mkdir -p /opt/hiddify-manager/data/log/system/
main |& tee /opt/hiddify-manager/data/log/system/warp.log
