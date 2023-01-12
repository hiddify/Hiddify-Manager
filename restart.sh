for s in **/*.service netdata nginx;do
	s=${s##*/}
	s=${s%%.*}
	printf "%-30s %-30s \n" $s $(systemctl restart $s)
done

bash status.sh