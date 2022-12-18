systemctl stop warp-go
wget -qN --no-check-certificate -O ./warp-go.sh https://raw.githubusercontent.com/fscarmen/warp/main/warp-go.sh && chmod +x ./warp-go.sh && ./warp-go.sh 5 $WARP_PLUS_KEY
