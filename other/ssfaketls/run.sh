

for req in ss-server obfs-server;do
    which $req
    if [[ "$?" != 0 ]];then
            bash install.sh
            break
    fi
done

systemctl kill ss-faketls.service





systemctl enable ss-faketls.service


systemctl restart ss-faketls.service
systemctl status ss-faketls.service --no-pager