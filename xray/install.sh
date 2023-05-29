
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.1

systemctl stop xray > /dev/null 2>&1
systemctl disable xray > /dev/null 2>&1

mkdir -p run
