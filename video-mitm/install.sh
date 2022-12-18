systemctl stop x-ui

wget https://github.com/kontorol/good-mitm/releases/download/0.4.1/video-mitm-0.4.0-x86_64-unknown-linux-gnu.tar.xz
xz -d ./video-mitm-0.4.0-x86_64-unknown-linux-gnu.tar.xz
tar -xvf ./video-mitm-0.4.0-x86_64-unknown-linux-gnu.tar

./video-mitm genca
# ./good-mitm run -r netflix.yaml

ln -s $(pwd)/video-mitm.service /etc/systemd/system/video-mitm.service

systemctl daemon-reload
