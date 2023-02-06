# Hiddify Config

This repository help you to create a dedicated multiprotocol proxy on port 443.
Supported items:

در این ریپازیتوری ساخت فیلترشکن حرفه‌ای را فقط با چند کلیک ساده فراهم کردیم.

| Supported Configs | کانفیگ های پشتیبانی شده|
| - | - |
| **Telegram Proxy** | **vless+xtls** |
| **Web Socket (cdn support)**:<br> - vless+tls+ws <br>- trojan+tls+ws <br> - vmess+tls+ws | **h2+tls**:<br> - vless+tls<br> - trojan+tls<br> - vmess+tls |
| **grpc+tls**:<br> - vless+grpc+tls<br> - trojan+grpc+tls<br> - vmess+grpc+tls | **http1.1+tls**:  <br>- trojan+tls <br> - vmess+tls|
| **old configs**: <br> - trojango (cdn support) <br> - v2ray+ws (cdn support) <br> - vmess (cdn support) <br> - ss+faketls| **HTTP** <br> -unsafe, default is disable <br> - vless<br> -vmess |
 


- DNS over HTTPS (supports CDN)

<details markdown="1"> <summary>Redirector (supports CDN)</summary> 
 
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

 ![صفحه راهنمای کاربران](https://user-images.githubusercontent.com/114227601/206908372-db1fc206-4c6a-4206-ad39-e6b6b44a55c4.png)

</details>
<details markdown="1"> <summary>Open Source</summary> 

کلیه سورس کدها در [گیت هاب](https://github.com/hiddify/hiddify-config) 
</details>

<details  markdown="1"> <summary>Supported OS: Ubuntu arm64 or amd64</summary>
It is tested on Ubuntu 20.04 and 22.04
</details>

<details  markdown="1"> <summary>Auto Up to date (به روز رسانی خودکار)</summary></details>


# [Installation Guide (Click) آموزش نصب و راه اندازی (کلیک کنید)](https://github.com/hiddify/hiddify-config/wiki#کانال-تلگرام-ما-کلیک-کنید)


# [(Telegram Channel) کانال تلگرام ما](https://t.me/hiddify)

# Admin and User Area صفحه کاربران و ادمین

با امکان تولید qrcode

![HiddifyPanel](https://raw.githubusercontent.com/hiddify/hiddify-config/main/docs/HiddifyPanel.webp)

<!--
![HiddifyPanel](https://user-images.githubusercontent.com/114227601/211161591-13ec01df-b4a9-4bbb-b147-c8ecc52dc0f9.gif)
![صفحه راهنمای کاربران](https://user-images.githubusercontent.com/114227601/206908372-db1fc206-4c6a-4206-ad39-e6b6b44a55c4.png)


# صفحه ادمین

![HiddifyPanel](https://raw.githubusercontent.com/hiddify/hiddify-config/main/docs/HiddifyPanel.webp)

![image](https://user-images.githubusercontent.com/114227601/209979538-cb3196aa-a832-4b06-95c4-37e9795e00cb.png)
-->
<!-- For Azure: -> Telegram: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Ftelegram%2Ftelegram-vm-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
MultiProxy: <a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Fshadowsocks%2Fss-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a> -->

<!-- 

# Gost Proxy (deprecated)
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhiddify%2Fconfig%2Fmain%2Fgost%2Fgost-vm-azure-template.json" target="_blank"><img src="https://aka.ms/deploytoazurebutton"/></a>
 -->

----
به کمک شما در توسعه این پروژه نیاز داریم

اگر توانایی برنامه نویسی یا تولید محتوا دارید با ما در تماس باشید

hiddify@gmail.com
