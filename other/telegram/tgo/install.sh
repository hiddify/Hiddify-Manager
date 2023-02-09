echo "telegram proxy install.sh $*"
systemctl kill mtproxy.service
systemctl disable mtproxy.service

# sudo add-apt-repository -y ppa:longsleep/golang-backports
# sudo apt update
# apt install -y make golang 

export pkg=$(dpkg --print-architecture)

# wget -q --show-progress -c https://go.dev/dl/go1.19.linux-$pkg.tar.gz  
# tar -xf go1.19.linux-amd64.tar.gz   
# export PATH=$(pwd)/go/bin:$PATH

wget -c https://github.com/9seconds/mtg/releases/download/v2.1.7/mtg-2.1.7-linux-$pkg.tar.gz
tar -xf mtg-2.1.7-linux-$pkg.tar.gz
rm -rf mtg
mv mtg-2.1.7-linux-$pkg/mtg mtg

# export GOPATH=/opt/hiddify-config/other/telegram/tgo/go/
# export GOCACHE=/opt/hiddify-config/other/telegram/tgo/gocache/
# git clone https://github.com/9seconds/mtg/



# if [ ! -f mtg/mtg ];then
#     echo "error in installation of telegram"
#     cd mtg

#     make 

# fi
