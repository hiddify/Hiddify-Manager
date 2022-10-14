USER_SECRET=$1
DOMAIN=$2
MODE="${3:-all}"
CLOUD_PROVIDER=${4:-$2}
if [[ $MODE == 'all' ]]; then
        MODE="shadowsocks-telegram-vmess";
fi

apt update
apt install -y git

cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config


function install() {
        echo "==========================================================="
        echo "===install $1 $USER_SECRET $DOMAIN $MODE $CLOUD_PROVIDER" 
        echo "==========================================================="        
        pushd $1; bash install.sh $USER_SECRET $DOMAIN $MODE $CLOUD_PROVIDER; popd 
}
install common
install nginx
if [[ $MODE == *'telegram'* ]]; then
  install telegram
fi
if [[ $MODE == *'shadowsocks'* ]]; then
   install shadowsocks
fi
if [[ $MODE == *'vmess'* ]]; then
   install vmess
fi

echo "==========================================================="
echo "Please open the following link in the browser for client setup"
cat nginx/use-link
