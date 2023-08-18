# bash download_wgcf.sh
which wgcf > /dev/null 2>&1
if [[ "$?" != 0 ]];then
    curl -fsSL git.io/wgcf.sh | sudo bash
fi
sudo apt install -y wireguard-dkms wireguard-tools resolvconf

# wgcf register --accept-tos -m hiddify -n $(hostname)