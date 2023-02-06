
bash uninstall.sh
if [ -d "$TELEGRAM_LIB" ];then 
    cd $TELEGRAM_LIB&& bash run.sh
fi
