# Hiddify Config
در این مقاله به شما آموزش میدهیم چگونه یک فیلترشکن اختصاصی مالتی پروتوکل در پورت 443 ایجاد کنید.
موارد پشتیبانی شده:
<details markdown="1"> <summary>Telegram MTProxy Proxy</summary>
 
 پروکسی ایجاد شده یک پروکسی faketls هست که در صورتی که کلاینت غیر تلگرام به آن متصل شود سایت گوگل را نشان می‌دهد.

 `(faketls domain=mail.google.com)`
 
</details>
<details  markdown="1"> <summary>Shadowsocks+obfs </summary>
 
 پروکسی شدوساکس مشابه پروکسی تلگرام فوق، از faketls استفاده میکند تا ترافیک شدوساکس را پنهان کند.

 `faketls domain=www.google.com` 
 
</details>
<details markdown="1"> <summary>Shadowsocks+v2ray (cdn support)</summary>
 
 این پروکسی، از v2ray استفاده میکند و یک زیرمسیر از سایت که با tls و http2 فعال است استفاده میکند

</details>
<details markdown="1"> <summary>vmess (cdn support)</summary>

Same as v2ray

</details>
<details markdown="1"> <summary>DNS over HTTPS (cdn support)</summary>
 
 برای استفاده از DNS over HTTPS کافی است در مرورگر از dns زیر استفاده کنید:
 
 `https://yourdomain.com/yoursecret/dns/dns-query{?dns}`
 
</details>
<details markdown="1"> <summary>Redirector (cdn support)</summary> 
 
 نکته این امر آن است که برای مثال وقتی میخواهید پروکسی تلگرام یا پروکسی شدوساکس را از طریق برنامه های دیگر به اشتراک بگذارید امکان آن فراهم می شود. برای مثال اگر کانفیگ شدوساکس را به جای `fullURL` آن قرار دهید باعث میشود با کلیک بر روی این لینک، نرم افزار شدوساکس باز شده و پروکسی بر روی آن فعال شود.
 
 `https://yourdomain.com/yoursecret/redirect/fullURL` 
 
 به عنوان مثال:
 
 `https://yourdomain.com/yoursecret/redirect/ss://secret/` 
 
</details>
 <details  markdown="1"> <summary>پروکسی هوشمند برای سایت های غیر ایرانی و فیلترشده </summary>
 
 با استفاده از کلاینت کلش و کانفیگی که درست کردیم میتوانید در 3 مود به اینترنت وصل بشید. 

1-  روش اول فقط سایت فیلترشده را از فیلترشکن عبور دهد.

2- فقط سایت های ایرانی بدون فیلترشکن باز شود (پیشنهادی)

3- تمام سایت ها از فیلترشکن عبور کنند

</details>
 <details markdown="1"> <summary>مقاوم در برابر کشف توسط فیلترچی</summary>
 
 سعی شده جلوی حملات معمول به سرور گرفته شود و امکان شناسایی حداقل باشد با این وجود فراموش نکنید که سایر پورت ها به جز 22، 80 و 443 را غیر فعال کنید

</details>
 <details markdown="1"> <summary>صفحات راهنمای کاربران</summary> 
 
 با امکان تولید qrcode

 
 ![صفحه راهنمای کاربران](https://user-images.githubusercontent.com/114227601/205199749-a3b93e75-7818-4deb-9924-706aef467f97.png)


</details>
<details markdown="1"> <summary>Open Source</summary> 

کلیه سورس کدها در [گیت هاب](https://github.com/hiddify/hiddify-config) 
</details>

<details markdown="1"> <summary>ارائه گزارش وضعیت سرویس </summary>
نمایش میزان مصرف پروکسی و تعداد کاربران،  بر اساس،پروتوکل، شهر و اپراتور اینترنت با حفظ حریم خصوصی کاربران

از طریق لینک زیر میتوانید مشاهده کنید وضعیت سرور رو

`https://yourdomain.com/yoursecret/stats/` 

</details>
<details  markdown="1"> <summary>Supported OS: Ubuntu arm64 or amd64</summary>
It is tested on Ubuntu 20.04 and 22.04
</details>

<details  markdown="1"> <summary>Auto Up to date (به روز رسانی خودکار)</summary>

به صورت پیش فرض به روزرسانی خودکار فعال است
جهت غیرفعال کردن آن کد زیر را در `config.env` اضافه کنید
```
ENABLE_AUTO_UPDATE=false
```
</details>


<details  markdown="1"> <summary>code for cloud-init</summary>

در بعضی از شرکت ها شما میتوانید با استفاده از اسکریپت زیر به صورت خودکار پروکسی را نصب کنید و از آدرس  `https://yourip.nip.io/`یا `http://yourip/` لینک صفحه کاربران را مشاهدهد کنید کافی است به جای yourip آی پی خود را قرار دهید.

ضمنا این لینک موقت فقط به مدت یک ساعت فعال خواهد بود و پس از آن غیرفعال خواهد شد

```
#cloud-config
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - wget
  - gnupg-agent
  - software-properties-common
  - git

runcmd:
  - cd /opt
  - git clone https://github.com/hiddify/hiddify-config/
  - cd hiddify-config
 # uncomment it for using a special secret other wise it will be createed automatically
 # - echo "USER_SECRET=0123456789abcdef0123456789abcdef" >config.env
 # - echo "MAIN_DOMAIN=" >>config.env
  - echo "TELEGRAM_AD_TAG=" >>config.env
  - bash install.sh

final_message: "The system is finally up, after $UPTIME seconds"
output: { all: "| tee -a /root/cloud-init-output.log" }

# you can see the generated link from the website by using http://yourip/ or https://yourip.nip.io in one hour, after that, it will be disapear. 
```

</details>
# نصب خیلی خیلی سریع!!!!! فقط با کلیک 

<details markdown="1"><summary>نصب خیلی خیلی سریع در اوراکل کلود</summary>

دکمه زیر فشار دهید: 

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/hiddify/hiddify-config/archive/refs/heads/main.zip)

همه مراحل را next بزنید

و در پایان لینک را از زیر کپی کنید. توجه کنید باید حداقل 15 دقیقه صبر کنید تا لینک فعال شود.

![image](https://user-images.githubusercontent.com/114227601/206861477-7967ac8d-ea9f-4742-b414-e848898668c7.png)


</details>

<details markdown="1"><summary>نصب خیلی خیلی سریع در هتزنر</summary>
![image](https://user-images.githubusercontent.com/114227601/206861285-58832cec-a2a3-441e-91d4-8300d16584d6.png)

حالا کد زیر را کپی کنید
```
#cloud-config
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - wget
  - gnupg-agent
  - software-properties-common
  - git

runcmd:
  - cd /opt
  - git clone https://github.com/hiddify/hiddify-config/
  - cd hiddify-config
 # uncomment it for using a special secret other wise it will be createed automatically
 # - echo "USER_SECRET=0123456789abcdef0123456789abcdef" >config.env
 # - echo "MAIN_DOMAIN=" >>config.env
  - echo "TELEGRAM_AD_TAG=" >>config.env
  - bash install.sh

final_message: "The system is finally up, after $UPTIME seconds"
output: { all: "| tee -a /root/cloud-init-output.log" }

# you can see the generated link from the website by using http://yourip/ or https://yourip.nip.io in one hour, after that, it will be disapear. 
```
کد بالا را در محل نشان داده در عکس قرار دهید.
![image](https://user-images.githubusercontent.com/114227601/206861304-656682b4-17a3-44c1-89f9-7b0d89566728.png)

پس از حداکثر 10 تا 15 دقیقه سرور شما آماده و پروکسی فعال خواهد بود
مطابق عکس IP خود را کپی کنید و در مرورگر باز کنید

![image](https://user-images.githubusercontent.com/114227601/206861323-1de41700-6ce4-403a-a644-0836e2a22876.png)


پس از این لینک صفحه پروکسی را مشاهده میکنید. توجه کنید که این لینک را در تلگرام خود کپی کنید وگرنه بعد از یک ساعت دیگر قابل دسترسی نیست.

</details>

# نصب سریع اگر یک سرور دارید

دستور زیر را در ترمینال کپی کنید و اجرا کنید

```
sudo bash -c "$(URL=https://raw.githubusercontent.com/hiddify/hiddify-config/main; curl -Lfo- $URL/config.env.default $URL/common/download_install.sh)"
```
در پایان لینکی ایجاد میشود که لینک پروکسی شما است.

# Update (به روز رسانی)
دستور زیر را در ترمینال کپی کنید و اجرا کنید
```
cd /opt/hiddify-config
sudo git pull
sudo bash install.sh
```

<details markdown="1"> <summary>Optional: Advanced Setup (اختیاری: نصب پیشرفته) </summary>

این قسمت برای افراد آشنا با کامپیوتر آماده شده است. میتوانید از آن صرفه نظر کنید.


<details markdown="1"><summary>اگر زیر دامنه ندارید، میتوانید زیردامنه سفارشی خود،  را بسازید</summary>

1- وارد [این سایت](https://freedns.afraid.org/signup/?plan=starter) و یک یوزر بسازید (لازم نیست که اطلاعاتتان واقعی باشد فقط ایمیل باید درست باشد)

2- ایمیلی که به شما ارسال شده را اکتیو کنید

3- روی [این لینک](https://freedns.afraid.org/subdomain/edit.php?edit_domain_id=1184493) کلیک کنید و آی پی سرور را خود و نام مورد نظر را در آن قرار دهید.

4- زیر دامنه ایجاد شده را کپی کنید.
</details>

```
cd /opt/
git clone https://github.com/hiddify/hiddify-config
cd hiddify-config
```
change the varibales in config.env and insert your domain and secret
then run 
```
sudo bash install.sh
```
</details>



<details markdown="1"> <summary>Optional: CDN Support</summary>
       
       
برای سرعت بالاتر و گذر از اینترانت کافی است که یک دامنه خریداری کنید (برای مثال از 
[اینجا به قیمت 1 دلار](https://www.namecheap.com/promos/99-cent-domain-names/)
یا 
[اینجا رایگان](https://www.freenom.com/) 
       
- قبل از خرید دامنه ابتدا دامنه را چک کنید که در ابرآروان مورد پذیرش قرار دهد
- سپس یک اکانت در ابرآروان ایجاد کنید میتوانید با یک شماره خارجی اینکار را انجام دهید
- سپس nameserver بر روی دامنه ای که خریداری کرده اید را مطابق اعلامی ابرآروان پر کنید
- سپس روی زیر دامنه دلخواه، آی پی سرور را تنظیم کنید و تیک کلود سرویس  را تنظیم کنید و سپس به جای `myservice.hiddify.com`  زیردامنه جدید خود را تنظیم کنید. لازم است این زیر دامنه با دامنه ای که در بالا انتخاب کرده اید متفاوت باشد.
- سپس لینک زیر را با تغییر در نامه دامنه در مرورگر جهت مشاهده تنظیمات باز کنید.


در زیر توضیحات با تصویر نشان داده شده است.
       
       


 ### 2. Arvancloud setup

4. Log in to the Arvancloud account and add your domain.

```
Domain List > Add new domains
```

![Arvancloud dashboard > Add new domain](https://raw.githubusercontent.com/WeAreMahsaAmini/FreeInternet/main/protocols/media/arvanclound_adddomain.jpg 'Click on Add new domain')

Then:

- Enter your domain name
- Select Free plan
- Skip DNS Records
- Note the nameservers presented on the last step

![Add new domain > Nameservers](https://raw.githubusercontent.com/WeAreMahsaAmini/FreeInternet/main/protocols/media/arvanclound_nameservers.jpg 'Copy these nameservers')

- Go to your domain registrar (the website where you bought your domain, e.g. Godaddy, Namecheap, ...)
- Update the nameservers to the one you got in Arvancloud (after adding the domain).

After your domain nameservers changed successfully (depending on the registrar, it can take a few hours, but it's usually quite fast), your domain is now using Arvancloud DNS.

5. Connect your domain to your server's IP address using `A` records. Make sure the `Cloud Service` option is enabled for each record.
   ![Add new domain > Nameservers](https://raw.githubusercontent.com/WeAreMahsaAmini/FreeInternet/main/protocols/media/arvanclound_add_dns.jpg 'Enable cloud services')

6. Go to `HTTPS settings` on the navbar, select `Issue certificate`. It will take around 30 minutes for the certificate to be ready.

7. After the certificate is issued, enable the `Activate HTTPS` option.
   ![HTTPS Settings > Activate HTTPS](https://raw.githubusercontent.com/WeAreMahsaAmini/FreeInternet/main/protocols/media/arvanclound_https.jpg 'Enable cloud services')









توضیحات بخش CDN برگرفته از دوستان  
[FreeInternet](https://github.com/WeAreMahsaAmini/FreeInternet/tree/main/protocols/shadowsocks-v2ray-tls)
       


<!-- # اگر از ابرآروان استفاده میکنید
 به جای `CLOUD_PROVIDER` چهارم در فایل `config.env` عبارت `arvancloud.com` را قرار دهید. -->


</details>

# صفحه راهنمای کاربران

با امکان تولید qrcode

![صفحه راهنمای کاربران](https://user-images.githubusercontent.com/114227601/205199749-a3b93e75-7818-4deb-9924-706aef467f97.png)


# One Click Setup

توجه کنید پس از اجرای دکمه زیر حداقل 5 دقیقه زمان لازم است که به صورت کامل همه کامپوننت ها نصب گردد. پس صبر داشته باشید :) و پس از ده دقیقه لینک تولید شده را آزمایش کنید تا صفحه را مشاهده کنید

Oracle: 

<!-- For Azure: -> Telegram: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Ftelegram%2Ftelegram-vm-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
MultiProxy: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Fshadowsocks%2Fss-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a> -->

<!-- 

# Gost Proxy (deprecated)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Fgost%2Fgost-vm-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
 -->

