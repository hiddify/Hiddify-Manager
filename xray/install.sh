
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.0

systemctl stop xray
systemctl disable xray

mkdir -p run
