USER_SECRET=$1
DOMAIN=$2
MODE="${3:-telegram-shadowsocks}"

apt install -y git

cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config

if [[ $MODE == *'telegram'* ]]; then
  cd telegram/install.sh 
  bash install.sh $USER_SECRET $DOMAIN
fi
if $MODE == *'shadowsocks'*; then
  cd shadowsocks/install.sh
  bash install.sh $USER_SECRET $DOMAIN
fi


