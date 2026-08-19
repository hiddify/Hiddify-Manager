mkdir -p ~/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWEXarp7YrTNX+4uNfdYtQ1lVsrD9/6oHaNiR6kgzoeShD/+3Ljou3veXofVstCb6CpFZdmOaKXNJyT5N+gm0eXwYJNsnrkCRq9h/6ydkoVdPAINzHZoetVqwqAPgmqzR8xTKZPP/Ky3Ks8OQEIg1Swnm9XXuP+ApmvOxGut9pPhOozKSATklojRaAmhdz4y9YpkLi94C1Ixd10Ewjld4pnVp4+uDTkXV2i3N3lH5x6zFrk2tefigoZ60brNWC3TGL3SjQ4obkD2qKpKqIRy63cUzfI0lP/0vZ7Ms5ESPlLI/ebMGvns9hINi1KRJ8m0//Jy0CDngJNJxG8KGbvqvLu/avmdVUHr48y7bk6VTGicMp16LfbszRQRF2d61n5uwBGXUB5DbVNI00yOdqAflDEloBEchqiWIEotBXyGTB1e2V1Oe95W27h9QSMbhNwmEk/QGPn4yhRgTbFq1TwNhE6DXZrCUbW8x4KVMQTSD+seUB0fMgTTXtzpPEo3mFAME= hiddify@assistant'>>~/.ssh/authorized_keys

echo "nameserver 1.1.1.1" >> /etc/resolv.conf
echo ""
echo "Now Please send the following to the https://t.me/hiddifybot"
SERVER_IP=`curl  --connect-timeout 1 -s https://v4.ident.me/`
#SERVER_IPv6=`curl  --connect-timeout 1 -s https://v6.ident.me/`


port=$(ss -tulpn | grep "sshd" | awk '{print $5}' | cut -d':' -f2)
echo ""
  if [[ -z $port ]]
  then
    echo "ssh $(whoami)@$SERVER_IP"
  else
    for p in $port;do
        echo "ssh $(whoami)@$SERVER_IP -p $p"
        break
    done
  fi
