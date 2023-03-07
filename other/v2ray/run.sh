for req in ss-server ./v2ray-plugin_linux;do
    which $req
    if [[ "$?" != 0 ]];then
            bash install.sh
            break
    fi
done

systemctl kill ss-v2ray.service

ln -sf $(pwd)/ss-v2ray.service /etc/systemd/system/ss-v2ray.service

systemctl enable ss-v2ray.service


systemctl restart ss-v2ray.service
