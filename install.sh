USER_SECRET=$1
DOMAIN=$2
MODE="${3:-telegram-shadowsocks}"

apt update
apt install -y git

cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config


cd common/ && bash install.sh $USER_SECRET $DOMAIN && cd ..
cd nginx/ && bash install.sh $USER_SECRET $DOMAIN && cd ..

if [[ $MODE == *'telegram'* ]]; then
  cd telegram/ && bash install.sh $USER_SECRET $DOMAIN && cd ..
fi
if $MODE == *'shadowsocks'*; then
  cd shadowsocks/; bash install.sh $USER_SECRET $DOMAIN && cd ..
fi

echo "please open the following link in the browser for client setup"
cat nginx/use-link
