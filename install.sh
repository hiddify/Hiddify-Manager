#!/bin/bash
cd $( dirname -- "$0"; )
echo "we are going to install :)"
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
#        exit 1

fi

source ./common/ticktick.sh

function set_config_from_hpanel(){

        hiddify=`cd hiddify-panel;python3 -m hiddifypanel all-configs`
        tickParse  "$hiddify"
        tickVars

        function setenv () {
                echo $1=$2
                export $1="$2"
        }


        setenv GITHUB_USER hiddify
        setenv GITHUB_REPOSITORY hiddify-config
        setenv GITHUB_BRANCH_OR_TAG main
        
        setenv FIRST_SETUP ``hconfigs[first_setup]``
        setenv DB_VERSION ``hconfigs[db_version]``

        TELEGRAM_SECRET=``hconfigs[shared_secret]``

        setenv TELEGRAM_USER_SECRET ${TELEGRAM_SECRET//-/}

        setenv BASE_PROXY_PATH ``hconfigs[proxy_path]``
        setenv TELEGRAM_LIB ``hconfigs[telegram_lib]``
        setenv ADMIN_SECRET ``hconfigs[admin_secret]``

        setenv ENABLE_V2RAY ``hconfigs[v2ray_enable]``

        setenv ENABLE_SS ``hconfigs[ssfaketls_enable]``
        setenv SS_FAKE_TLS_DOMAIN ``hconfigs[ssfaketls_fakedomain]``
        
        setenv DECOY_DOMAIN ``hconfigs[decoy_domain]``

        setenv SHARED_SECRET ``hconfigs[shared_secret]``
        

        setenv ENABLE_TELEGRAM ``hconfigs[telegram_enable]``
        setenv TELEGRAM_FAKE_TLS_DOMAIN ``hconfigs[telegram_fakedomain]``
        setenv TELEGRAM_AD_TAG ``hconfigs[telegram_adtag]``

        setenv ENABLE_SHADOW_TLS ``hconfigs[shadowtls_enable]``
        setenv SHADOWTLS_FAKEDOMAIN ``hconfigs[shadowtls_fakedomain]``

        setenv FAKE_CDN_DOMAIN ``hconfigs[fake_cdn_domain]``

        setenv ENABLE_SSR ``hconfigs[ssr_enable]``
        setenv SSR_FAKEDOMAIN ``hconfigs[ssr_fakedomain]``

        setenv ENABLE_VMESS ``hconfigs[vmess_enable]``
        setenv ENABLE_MONITORING false
        setenv ENABLE_FIREWALL ``hconfigs[firewall]``
        setenv ENABLE_NETDATA ``hconfigs[netdata]``
        setenv ENABLE_HTTP_PROXY ``hconfigs[http_proxy]`` # UNSAFE to enable, use proxy also in unencrypted 80 port
        setenv ALLOW_ALL_SNI_TO_USE_PROXY ``hconfigs[allow_invalid_sni]`` #UNSAFE to enable, true=only MAIN domain is allowed to use proxy
        setenv ENABLE_AUTO_UPDATE ``hconfigs[auto_update]``
        setenv ENABLE_TROJAN_GO false
        setenv ENABLE_SPEED_TEST ``hconfigs[speed_test]``
        setenv BLOCK_IR_SITES ``hconfigs[block_iran_sites]``
        setenv ONLY_IPV4 ``hconfigs[only_ipv4]``

        setenv SERVER_IP `curl --connect-timeout 1 -s https://v4.ident.me/`
        setenv SERVER_IPv6 `curl  --connect-timeout 1 -s https://v6.ident.me/`

        function get () {
                group=$1
                index=`printf "%012d" "$2"` 
                member=$3
                
                var="__tick_data_${group}_${index}_${member}";
                echo ${!var}
        }

        MAIN_DOMAIN=
        for i in $(seq 0 ``domains.length()``); do
                domain=$(get domains $i domain)
                mode=$(get domains $i mode)
                if [ "$mode"  == "direct" ] || [ "$mode"  == "cdn" ] || [ "$mode"  == "relay" ];then
                        MAIN_DOMAIN="$domain;$MAIN_DOMAIN"
                fi
                if [ "$mode"  = "ss_faketls" ];then
                        setenv SS_FAKE_TLS_DOMAIN $domain
                fi
                if [ "$mode"  = "telegram_faketls" ];then
                        setenv TELEGRAM_FAKE_TLS_DOMAIN $domain
                fi

                if [ "$mode"  = "fake_cdn" ];then
                        setenv FAKE_CDN_DOMAIN $domain
                fi
        done

        setenv MAIN_DOMAIN $MAIN_DOMAIN

        USER_SECRET=
        for i in $(seq 0 ``users.length()``); do
        uuid=$(get users $i uuid)
        secret=${uuid//-/}
        if [ "$secret" != "" ];then
                USER_SECRET="$secret;$USER_SECRET"
        fi
        done


        setenv USER_SECRET $USER_SECRET
}
function check_req(){
        
   for req in hexdump dig curl git;do
        which $req
        if [[ "$?" != 0 ]];then
                apt update
                apt install -y dnsutils bsdmainutils curl git
                break
        fi
   done
   
}

function runsh() {          
        command=$1
        if [[ $3 == "false" ]];then
                command=uninstall.sh
        fi
        pushd $2 >>/dev/null 
        # if [[ $? != 0]];then
        #         echo "$2 not found"
        # fi
        if [[ $? == 0 && -f $command ]];then
                echo "==========================================================="
                echo "===$command $2"
                echo "==========================================================="        
                bash $command
        fi
        popd >>/dev/null
}

function do_for_all() {
        #cd /opt/$GITHUB_REPOSITORY
        bash common/replace_variables.sh
        systemctl daemon-reload
        if [ "$MODE" != "apply_users" ];then
                runsh $1.sh common
                #runsh $1.sh certbot
                runsh $1.sh acme.sh
                runsh $1.sh nginx
                # runsh $1.sh sniproxy
                runsh $1.sh haproxy
                runsh $1.sh other/speedtest
                runsh $1.sh other/telegram $ENABLE_TELEGRAM
                runsh $1.sh other/ssfaketls $ENABLE_SS
                runsh $1.sh other/v2ray $ENABLE_V2RAY
                runsh $1.sh other/shadowtls $ENABLE_SHADOWTLS
                #runsh $1.sh other/next-version/clash-server $ENABLE_TUIC
                # runsh $1.sh deprecated/vmess $ENABLE_VMESS
                runsh uninstall.sh deprecated/vmess
                # runsh $1.sh deprecated/monitoring $ENABLE_MONITORING
                runsh uninstall.sh deprecated/monitoring
                runsh $1.sh other/netdata $ENABLE_NETDATA
                runsh $1.sh deprecated/trojan-go  $ENABLE_TROJAN_GO
        fi

        runsh $1.sh xray
        
}


function main(){
        which hiddifypanel
        if [[ "$?" != 0 ]];then
            echo "/opt/hiddify-config/menu.sh">>~/.bashrc
            echo "cd /opt/hiddify-config/">>~/.bashrc
        fi

        export MODE="$1"
        rm /dev/shm/hiddify-xtls-main.sock
        if [ "$MODE" != "apply_users" ];then
                runsh install.sh hiddify-panel
        fi
        # source common/set_config_from_hpanel.sh
        set_config_from_hpanel
        if [[ $DB_VERSION == "" ]];then
                echo "ERROR!!!! There is an error in the installation of python panel. Exit...."
                exit 1
        fi
        
        # check_req
        
        
        # set_env_if_empty config.env.default
        # set_env_if_empty config.env      

        # if [[ "$BASE_PROXY_PATH" == "" ]]; then
        #         replace_empty_env BASE_PROXY_PATH "" $USER_SECRET ".*"
        # fi
        # if [[ "$TELEGRAM_USER_SECRET" == "" ]]; then
        #         replace_empty_env TELEGRAM_USER_SECRET "" $USER_SECRET ".*"
        # fi
        
        # cd /opt/$GITHUB_REPOSITORY
        # git pull

        # if [[ -z "config.env $FIRST_SETUP" == "" ]];then
        #         replace_empty_env FIRST_SETUP "First Setup Detected!" false ".*"
        #         export FIRST_SETUP="true"
        # fi

        if [ "$MODE" == "install-docker" ];then
                echo "install-docker"
                export DO_NOT_RUN=true
                export ENABLE_SS=true
                export ENABLE_TELEGRAM=true
                export ENABLE_FIREWALL=false
                export ENABLE_AUTO_UPDATE=false
                export ONLY_IPV4=false
        fi
        if [ "$MODE" == "apply_users" ];then
                export DO_NOT_INSTALL=true
        fi
        if [[ -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false  ]];then
                do_for_all install
                systemctl daemon-reload
        fi

        if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
                do_for_all run
                if [ "$MODE" != "apply_users" ];then        
                        echo ""
                        echo ""
                        bash status.sh
                        echo "==========================================================="
                        echo "Finished! Thank you for helping Iranians to skip filternet."
                        echo "Please open the following link in the browser for client setup"
                        
                        cat use-link
                        echo "---------------------Finished!------------------------"
                fi
        fi

        if [ "$MODE" != "apply_users" ];then
                systemctl restart hiddify-panel
        fi
}

mkdir -p log/system/
main $@|& tee log/system/0-install.log
