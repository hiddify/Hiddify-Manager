

wget -N https://raw.githubusercontent.com/fscarmen/warp/main/api.sh && bash api.sh -u -f wgcf-account.toml
# Change directory to the location of WARP files
cd /opt/hiddify-manager/other/warp/wireguard
mv wgcf-account.toml wgcf-account.toml.backup
# curl --connect-timeout 1 -Lo wgcf.zip https://api.zeroteam.top/warp?format=wgcf
# unzip -o wgcf.zip
bash run.sh
