
bash uninstall.sh
echo "Running Telegramlib $TELEGRAM_LIB"
if [ -d "$TELEGRAM_LIB" ];then 
    cd $TELEGRAM_LIB&& bash run.sh
fi
