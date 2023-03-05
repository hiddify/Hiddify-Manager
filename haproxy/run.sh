ln -sf $(pwd)/haproxy.cfg /etc/haproxy/haproxy.cfg

 systemctl reload haproxy
 systemctl start haproxy