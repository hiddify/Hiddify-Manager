for req in ./clashmeta;do
    which $req
    if [[ "$?" != 0 ]];then
            bash install.sh
            break
    fi
done

systemctl enable clash-server.service
systemctl restart clash-server.service