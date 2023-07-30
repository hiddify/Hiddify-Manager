# 查 WARP+ 余额流量接口
cd $( dirname -- "$0"; )
check_quota() {
  if [ -e wgcf-account.toml ];then
    file_content=$(cat wgcf-account.toml)
    DEVICE_ID=$(echo "$file_content" | grep -oP "device_id = '\K[^']+") 
    ACCESS_TOKEN=$(echo "$file_content" | grep -oP "access_token = '\K[^']+")

  elif [ -e warp.conf ]; then
    ACCESS_TOKEN=$(grep 'Token' warp.conf | cut -d= -f2 | sed 's# ##g')
    DEVICE_ID=$(grep 'Device' warp.conf | cut -d= -f2 | sed 's# ##g')
    
  fi
    API=$(curl -s "https://api.cloudflareclient.com/v0a884/reg/$DEVICE_ID" -H "User-Agent: okhttp/3.12.1" -H "Authorization: Bearer $ACCESS_TOKEN")
    QUOTA=$(sed 's/.*quota":\([^,]\+\).*/\1/g' <<< $API)
  # 部分系统没有依赖 bc，所以两个小数不能用 $(echo "scale=2; $QUOTA/1000000000000000" | bc)，改为从右往左数字符数的方法
  if [[ "$QUOTA" != 0 && "$QUOTA" =~ ^[0-9]+$ && "$QUOTA" -ge 1000000000 ]]; then  
    CONVERSION=("1000000000000000000" "1000000000000000" "1000000000000" "1000000000")
    UNIT=("EB" "PB" "TB" "GB")
    for ((o=0; o<${#CONVERSION[*]}; o++)); do
      [[ "$QUOTA" -ge "${CONVERSION[o]}" ]] && break
    done

    QUOTA_INTEGER=$(( $QUOTA / ${CONVERSION[o]} ))
    QUOTA_DECIMALS=${QUOTA:0-$(( ${#CONVERSION[o]} - 1 )):2}
    QUOTA="$QUOTA_INTEGER.$QUOTA_DECIMALS ${UNIT[o]}"
  fi
  echo $QUOTA
}
check_quota

wgcf update
