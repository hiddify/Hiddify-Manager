apt install -y python3-pip
pip install bottle



pkill -9 python3
python3 main.py &
pid=$!
echo $pid
(sleep 120 && kill -9 $pid)&