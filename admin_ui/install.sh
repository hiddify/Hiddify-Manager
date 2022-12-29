systemctl stop hiddify-admin.service
systemctl disable hiddify-admin.service

apt install -y python3-pip
pip install bottle



pkill -9 python3
ln -s $(pwd)/hiddify-admin.service /etc/systemd/system/hiddify-admin.service
# python3 main.py &
# pid=$!
# echo $pid
# (sleep 2h && kill -9 $pid)&

