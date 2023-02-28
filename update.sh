#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

cd $( dirname -- "$0"; )

function get_commit_version(){
    COMMIT=$(curl -s https://api.github.com/repos/hiddify/$1/git/refs/heads/main|jq -r .object.sha)
    echo ${COMMIT:0:7}
}

function main(){
    # temporary
    echo "/opt/hiddify-config/menu.sh">>~/.bashrc
    echo "cd /opt/hiddify-config/">>~/.bashrc

    PACKAGE_MODE=$(cd hiddify-panel;python3 -m hiddifypanel all-configs|jq -r ".hconfigs.package_mode")
    
    if [[ "$PACKAGE_MODE" == "develop" ]];then
        echo "you are in develop mode"
        LATEST=$(get_commit_version HiddifyPanel)
        INSTALL_DIR=$(pip show hiddifypanel |grep Location |awk -F": " '{ print $2 }')
        CURRENT=$(cat $INSTALL_DIR/hiddifypanel/VERSION)
        echo "DEVLEOP: hiddify panel version current=$CURRENT latest=$LATEST"
        if [[ "$LATEST" != "$CURRENT" ]];then
            pip3 uninstall -y hiddifypanel
            pip3 install -U git+https://github.com/hiddify/HiddifyPanel
            echo $LATEST>$INSTALL_DIR/hiddifypanel/VERSION
            echo "__version__='$LATEST'">$INSTALL_DIR/hiddifypanel/VERSION.py
        fi
    else 
        CURRENT=`pip3 freeze |grep hiddifypanel|awk -F"==" '{ print $2 }'`
        LATEST=`lastversion hiddifypanel --at pip`
        echo "hiddify panel version current=$CURRENT latest=$LATEST"
        if [[ "$CURRENT" != "$LATEST" ]];then
            echo "panel is outdated! updating...."
            pip3 install -U hiddifypanel
        fi
    fi

    
    
    CURRENT_CONFIG_VERSION=$(cat VERSION)
    if [[ "$PACKAGE_MODE" == "develop" ]];then
        LAST_CONFIG_VERSION=$(get_commit_version hiddify-config)
        echo "DEVELOP: Current Config Version=$CURRENT_CONFIG_VERSION -- Latest=$LAST_CONFIG_VERSION"
        if [[ "$CURRENT_CONFIG_VERSION" != "$LAST_CONFIG_VERSION" ]];then
            wget -c https://github.com/hiddify/hiddify-config/archive/refs/heads/main.tar.gz
            tar xvzf main.tar.gz --strip-components=1
            rm main.tar.gz
            echo $LAST_CONFIG_VERSION > VERSION
            bash install.sh
        fi
    else 
        LAST_CONFIG_VERSION=$(lastversion hiddify/hiddify-config)
        echo "Current Config Version=$CURRENT_CONFIG_VERSION -- Latest=$LAST_CONFIG_VERSION"
        if [[ "$CURRENT_CONFIG_VERSION" != "$LAST_CONFIG_VERSION" ]];then
            echo "Config is outdated! updating..."
            wget -c $(lastversion hiddify/hiddify-config --source)
            tar xvzf hiddify-config-v$LAST_CONFIG_VERSION.tar.gz --strip-components=1
            rm hiddify-config-v$LAST_CONFIG_VERSION.tar.gz
            bash install.sh
        fi
    fi
    if [[ "$CURRENT" != "$LATEST" ]];then
        systemctl restart hiddify-panel
    fi
}

mkdir -p log/system/
main |& tee log/system/update.log