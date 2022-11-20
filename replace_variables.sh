
HEX_TELEGRAM_DOMAIN=$(echo -n "$TELEGRAM_FAKE_TLS_DOMAIN"| xxd -ps | tr -d '\n')

for template_file in $(find . -name "*.template"); do
    out_file=${template_file/.template/}
    

    sed "s/defaultusersecret/$USER_SECRET/g" $template_file >$out_file
    sed "s/defaultuserguidsecret/$guid/g" $template_file >$out_file
    sed "s/defaultcloudprovider/$cloudprovider/g" $template_file >$out_file
    sed "s/defaultserverip/$IP/g" $template_file >$out_file
    sed "s/defaultserverhost/$DOMAIN/g" $template_file >$out_file
    sed "s/telegramadtag/$TELEGRAM_AD_TAG/g" $template_file >$out_file
    sed "s/telegramtlsdomain/$TELEGRAM_FAKE_TLS_DOMAIN/g" $template_file >$out_file
    sed "s/sstlsdomain/$SS_FAKE_TLS_DOMAIN/g" $template_file >$out_file
    sed "s/hextelegramdomain/$HEX_TELEGRAM_DOMAIN/g" $template_file >$out_file

    sed "s/GITHUB_REPOSITORY/$GITHUB_REPOSITORY/g" $template_file >$out_file
    sed "s/GITHUB_USER/$GITHUB_USER/g" $template_file >$out_file
    sed "s/GITHUB_BRANCH/$GITHUB_BRANCH_OR_TAG/g" $template_file >$out_file
    
    

done
