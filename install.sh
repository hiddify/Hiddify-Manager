#!/bin/bash
cd $( dirname -- "$0"; )
echo "we are going to install :)"
export DEBIAN_FRONTEND=noninteractive
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
#        exit 1

fi
function error(){
   echo -e "\033[91m$1\033[0m">&2

}
function cleanup() {
    error "Script interrupted. Exiting..."
    rm log/install.lock
    pkill -9 dialog
    echo "1">log/error.lock

    exit 1
}

# Trap the Ctrl+C signal and call the cleanup function
trap cleanup SIGINT


source ./common/ticktick.sh
function update_progress() {
    #title="\033[92m\033[1m${1^}\033[0m\033[0m"
    title="${1^}"
    text="$2"
    percentage="$3"
    echo -e "XXX\n$percentage\n$title\n$text\nXXX"

}


function set_config_from_hpanel(){

        hiddify=`cd hiddify-panel;python3 -m hiddifypanel all-configs`
        if [[ $? != 0 ]];then
                error "Exception in Hiddify Panel. Please send the log to hiddify@gmail.com"
                echo "4">log/error.lock
                exit 4
        fi
        tickParse  "$hiddify"
        # tickVars

        function setenv () {
                echo $1=$2
                export $1="$2"
        }
        for x in ``hconfigs.items()``; do
                setenv "${x/__tick_data_hconfigs_/}" "${!x}" 
        done

        setenv GITHUB_USER hiddify
        setenv GITHUB_REPOSITORY hiddify-config
        setenv GITHUB_BRANCH_OR_TAG main
        
        setenv TLS_PORTS ``hconfigs[tls_ports]``
        setenv HTTP_PORTS ``hconfigs[http_ports]``
        setenv FIRST_SETUP ``hconfigs[first_setup]``
        setenv DB_VERSION ``hconfigs[db_version]``

        TELEGRAM_SECRET=``hconfigs[shared_secret]``

        setenv TELEGRAM_USER_SECRET ${TELEGRAM_SECRET//-/}

        setenv BASE_PROXY_PATH ``hconfigs[proxy_path]``
        setenv TELEGRAM_LIB ``hconfigs[telegram_lib]``
        setenv ADMIN_SECRET ``hconfigs[admin_secret]``

        setenv ENABLE_V2RAY ``hconfigs[v2ray_enable]``
        setenv WARP_MODE ``hconfigs[warp_mode]``
        setenv WARP_PLUS_CODE ``hconfigs[warp_plus_code]``
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
        c=``hconfigs[country]``
        if [[ "$c" == "" ]];then 
                c="ir"
        fi
        setenv COUNTRY  $c
        

        setenv ENABLE_SSR ``hconfigs[ssr_enable]``
        setenv SSR_FAKEDOMAIN ``hconfigs[ssr_fakedomain]``

        setenv ENABLE_VMESS ``hconfigs[vmess_enable]``
        setenv ENABLE_MONITORING false
        setenv ENABLE_FIREWALL ``hconfigs[firewall]``
        # setenv ENABLE_NETDATA ``hconfigs[netdata]``
        setenv ENABLE_HTTP_PROXY ``hconfigs[http_proxy]`` # UNSAFE to enable, use proxy also in unencrypted 80 port
        setenv ALLOW_ALL_SNI_TO_USE_PROXY ``hconfigs[allow_invalid_sni]`` #UNSAFE to enable, true=only MAIN domain is allowed to use proxy
        setenv ENABLE_AUTO_UPDATE ``hconfigs[auto_update]``
        setenv ENABLE_TROJAN_GO false
        setenv ENABLE_SPEED_TEST ``hconfigs[speed_test]``
        setenv BLOCK_IR_SITES ``hconfigs[block_iran_sites]``
        setenv ONLY_IPV4 ``hconfigs[only_ipv4]``
        setenv PATH_VMESS ``hconfigs[path_vmess]``
        setenv PATH_VLESS ``hconfigs[path_vless]``
        setenv PATH_SS ``hconfigs[path_v2ray]``
        setenv PATH_TROJAN ``hconfigs[path_trojan]``
        setenv PATH_TCP ``hconfigs[path_tcp]``
        setenv PATH_WS ``hconfigs[path_ws]``
        setenv PATH_GRPC ``hconfigs[path_grpc]``

        setenv REALITY_SERVER_NAMES ``hconfigs[reality_server_names]``
        setenv REALITY_FALLBACK_DOMAIN ``hconfigs[reality_fallback_domain]``
        setenv REALITY_PRIVATE_KEY ``hconfigs[reality_private_key]``
        setenv REALITY_SHORT_IDS ``hconfigs[reality_short_ids]``

        

        setenv SERVER_IP `curl --connect-timeout 1 -s https://v4.ident.me/`
        setenv SERVER_IPv6 `curl  --connect-timeout 1 -s https://v6.ident.me/`

        function get () {
                group=$1
                index=`printf "%012d" "$2"` 
                member=$3
                
                var="__tick_data_${group}_${index}_${member}";
                echo ${!var}
        }
        REALITY_MULTI=
        REALITY_MULTI_GRPC=
        FORCE_XRAY_DOMAINS_MULTI=
        MAIN_DOMAIN=
        for i in $(seq 0 ``domains.length()``); do
                domain=$(get domains $i domain)
                servernames=$(get domains $i servernames)
                mode=$(get domains $i mode)
                grpc=$(get domains $i grpc)
                case $mode in
                direct|cdn|worker|relay|auto_cdn_ip|old_xtls_direct|sub_link_only)
                        MAIN_DOMAIN="$domain;$MAIN_DOMAIN"
                        if [ "$mode" == "old_xtls_direct" ];then
                                FORCE_XRAY_DOMAINS_MULTI="$domain;$FORCE_XRAY_DOMAINS_MULTI"
                        fi 
                        ;;
                reality)
                        if [ "$grpc" == "true" ];then
                                REALITY_MULTI_GRPC="$domain:${servernames:-$domain};$REALITY_MULTI_GRPC"
                        else 
                                REALITY_MULTI="$domain:${servernames:-$domain};$REALITY_MULTI"
                        fi
                        ;;
                ss_faketls)
                        setenv SS_FAKE_TLS_DOMAIN $domain
                        ;;
                telegram_faketls)
                        setenv TELEGRAM_FAKE_TLS_DOMAIN $domain                        
                        ;;
                fake_cdn)
                        setenv FAKE_CDN_DOMAIN $domain
                        ;;
                *)
                        # Code block to execute for other cases (optional)
                        ;;
                esac

        done
        setenv REALITY_MULTI $REALITY_MULTI
        setenv REALITY_MULTI_GRPC $REALITY_MULTI_GRPC
        setenv MAIN_DOMAIN $MAIN_DOMAIN
        setenv FORCE_XRAY_DOMAINS_MULTI $FORCE_XRAY_DOMAINS_MULTI

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
        
   for req in hexdump dig curl git python3;do
        which $req
        if [[ "$?" != 0 ]];then
                apt update
                apt install -y add-apt-repository
                add-apt-repository -y ppa:deadsnakes/ppa

                apt install -y dnsutils bsdmainutils curl git python3.10 python3.10-dev
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
        if [ "$MODE" != "apply_users" ];then
                systemctl daemon-reload
                update_progress "${1}ing..." "Common Tools" 8
                runsh $1.sh common
                update_progress "${1}ing..." "Redis" 10
                runsh $1.sh other/redis
                update_progress "${1}ing..." "Warp" 15
                runsh $1.sh other/warp $([ "$WARP_MODE" != 'disable' ] || echo "false")
                #runsh $1.sh certbot
                update_progress "${1}ing..." "Getting Certificates" 20
                runsh $1.sh acme.sh
                update_progress "${1}ing..." "Nginx" 30
                runsh $1.sh nginx
                # runsh $1.sh sniproxy
                update_progress "${1}ing..." "Personal SpeedTest" 35
                runsh $1.sh other/speedtest
                update_progress "${1}ing..." "Telegram Proxy" 40
                runsh $1.sh other/telegram $ENABLE_TELEGRAM
                update_progress "${1}ing..." "FakeTlS Proxy" 45
                runsh $1.sh other/ssfaketls $ENABLE_SS
                update_progress "${1}ing..." "V2ray WS Proxy" 50
                runsh $1.sh other/v2ray $ENABLE_V2RAY
                update_progress "${1}ing..." "SSH Proxy" 55
                runsh $1.sh other/ssh $ssh_server_enable
                update_progress "${1}ing..." "ShadowTLS" 60
                runsh $1.sh other/shadowtls $ENABLE_SHADOWTLS
                # runsh $1.sh other/clash-server $ENABLE_TUIC
                # runsh $1.sh deprecated/vmess $ENABLE_VMESS
                # runsh uninstall.sh deprecated/vmess
                # runsh $1.sh deprecated/monitoring $ENABLE_MONITORING
                # runsh uninstall.sh deprecated/monitoring
                # runsh $1.sh other/netdata false $ENABLE_NETDATA
                # runsh $1.sh deprecated/trojan-go  $ENABLE_TROJAN_GO
                #WARP_ENABLE=$([ "$WARP_MODE" != 'disable' ] || echo "false")
                
        fi
        update_progress "${1}ing..." "Haproxy for Spliting Traffic" 70
        runsh $1.sh haproxy
        update_progress "${1}ing..." "Singbox" 80
        runsh $1.sh singbox
        update_progress "${1}ing..." "Xray" 90
        runsh $1.sh xray
        
        update_progress "${1}ing..." "Finished" 100
}


function main(){
        update_progress "Please wait..." "We are going to install Hiddify..."  0
        export ERROR=0
        rm -rf log/system/xray*
        

        export MODE="$1"
        
        if [ "$MODE" != "apply_users" ];then
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.4
                runsh install.sh hiddify-panel
        fi
        # source common/set_config_from_hpanel.sh
        update_progress "" "Reading Configs from Panel..." 5
        set_config_from_hpanel
        if [[ $DB_VERSION == "" ]];then
                error "ERROR!!!! There is an error in the installation of python panel. Exit...."
                echo "5">log/error.lock

                exit 5
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
        if [[ $MODE != "apply_configs" && -z "$DO_NOT_INSTALL" || "$DO_NOT_INSTALL" == false  ]];then
                do_for_all install
                systemctl daemon-reload
        fi

        if [[ -z "$DO_NOT_RUN" || "$DO_NOT_RUN" == false ]];then
                update_progress "Applying Configs" "..." 5
                do_for_all run
        fi

        
        # if [[ $(/usr/local/bin/xray run -test -confdir xray/configs) ]];then
        #         echo "xray configuration failed "
        #         exit 33
        # fi
        echo "---------------------Finished!------------------------"
        rm log/install.lock
        if [ "$MODE" != "apply_users" ];then
                systemctl restart hiddify-panel
        fi
        systemctl start hiddify-panel

}       



function check(){
        export MODE="$1"
        if [ "$MODE" != "apply_users" ];then        
                echo ""
                echo ""
                bash status.sh
                echo "==========================================================="
                bash common/logo.ico
                echo "Finished! Thank you for helping to skip filternet."
                echo "Please open the following link in the browser for client setup"
                
                cat use-link
                        
        fi
        for s in hiddify-xray hiddify-singbox hiddify-nginx hiddify-haproxy;do
                s=${s##*/}
                s=${s%%.*}
                if [[ "$(systemctl is-active $s)" != "active" ]];then
                        error "an important service $s is not working yet"
                        sleep 5
                        error "checking again..."
                        if [[ "$(systemctl is-active $s)" != "active" ]];then
                                error "an important service $s is not working again"
                                error "Installation Failed!"
                                echo "32">log/error.lock
                                exit 32
                        fi
                        
                fi
                
        done
}
mkdir -p log/system/

if [[ -f log/install.lock && $(( $(date +%s) - $(cat log/install.lock) )) -lt 120 ]]; then
    error "Another installation is running.... Please wait until it finishes or wait 5 minutes or execute 'rm -f log/install.lock'"
    echo "12">log/error.lock
    exit 12
fi


echo "$(date +%s)" > log/install.lock

which dialog >/dev/null 2>&1
if [[ "$?" != 0 ]];then
        apt install -y dialog
fi
echo "0"> log/error.lock
BACKTITLE="Welcome to Hiddify Panel (config version=$(cat VERSION))"
let width=$(tput cols)
let height=$(tput lines)

log_h=$((height - 10))
if [[ $log_h < 0 ]];then 
log_h=0
fi
log_file=log/system/0-install.log

main $@|& tee $log_file|dialog \
        --backtitle "$BACKTITLE" \
        --title "Installing Hiddify" \
        --begin 2 2 \
        --tailboxbg $log_file $log_h $((width - 6)) \
        --and-widget \
        --begin $(($log_h + 2)) 2 \
        --gauge "Please wait..., We are going to install Hiddify" 7 $((width - 6)) 0


#dialog --title "Installing Hiddify" --backtitle "$BACKTITLE" --gauge "Please wait..., We are going to install Hiddify" 8 60 0

rm -f log/install.lock  >/dev/null 2>&1

if [[ $(cat log/error.lock) != "0" ]];then
        less -r -P"Installation Failed! Press q to exit" +G "$log_file"
else
        check $@|& tee -a $log_file
fi
pkill -9 dialog