mkdir -p videos
which yt-dlp
if [[ "$?" != 0 ]];then
    source /opt/hiddify-manager/common/utils.sh
    activate_python_venv
    pip3 install yt-dlp
fi
declare -A arr
arr["features"]="https://www.youtube.com/watch?v=-a4tfRUsrNY"
arr["webapp-ios"]="https://youtube.com/shorts/GBywNl2KZMM"
arr["webapp-android"]="https://youtube.com/shorts/_-Iyr_RtIH0"
arr["ios-fair"]="https://youtu.be/01m7w-I4JXE"
arr["ios-wingx"]="https://youtu.be/qFKv4I-MNQc"
arr["ios-stash"]="https://youtu.be/D0Xv54nRSY8"
arr["ios-shadowrocket"]="https://youtu.be/F2bC_mtbYmQ"
arr["android-v2rayng"]="https://youtu.be/6HncctDHXVs"
arr['android-hiddifyng']="https://youtu.be/7B0PO3HM6Vg"
arr['android-hiddifyclash']="https://youtu.be/8P887E-KMls"
arr['windows-hiddifyn']="https://youtu.be/o9L2sI2T53Q"

for key in ${!arr[@]}; do
    dst=videos/$key.mp4
    link=${arr[${key}]}
    if [[ ! -f $dst ]];then
        yt-dlp --socket-timeout 10 $link -o $dst
    fi
    if [[ ! -f $dst ]];then
        yt-dlp --socket-timeout 10 --proxy socks5://127.0.0.1:3000/  $link -o $dst
    fi
done
