USER_SECRET=$1
DOMAIN=$2
MODE="${3:-telegram-shadowsocks}"

apt update
apt install -y git

cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config


function install() {
        cd $1 && bash install.sh $USER_SECRET $DOMAIN && cd ..
}
install common
install nginx
if [[ $MODE == *'telegram'* ]]; then
  install telegram
fi
if $MODE == *'shadowsocks'*; then
   install shadowsocks
fi

echo "please open the following link in the browser for client setup"
cat nginx/use-link
