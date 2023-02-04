

echo "Installing Telegramlib $TELEGRAM_LIB"
if [ -d "$TELEGRAM_LIB" ];then 
    cd $TELEGRAM_LIB&& bash install.sh
fi
