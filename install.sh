USER_SECRET=$1
DOMAIN=$2
MODE="${3:-telegram-shadowsocks}"

apt update
apt install -y git

cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config


function install() {
        echo "==========================================================="
        echo "===install $1 $USER_SECRET $DOMAIN"
        echo "==========================================================="        
        pushd $1; bash install.sh $USER_SECRET $DOMAIN; popd 
}
install common
install nginx
if [[ $MODE == *'telegram'* ]]; then
  install telegram
fi
if [[ $MODE == *'shadowsocks'* ]]; then
   install shadowsocks
fi

echo "please open the following link in the browser for client setup"
cat nginx/use-link
