for s in **/*.service v2ray nginx xray;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl is-active $s)
done