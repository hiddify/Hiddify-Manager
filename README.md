
<div dir="ltr" markdown="1">

### [جهت مشاهده توضیحات فارسی کلیک کنید](https://github.com/hiddify/hiddify-config/wiki)



</div>



***
[Installation Guide](https://github.com/hiddify/hiddify-config/wiki#%D8%B1%D8%A7%D9%87%D9%86%D9%85%D8%A7%DB%8C-%D9%86%D8%B5%D8%A8) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [User Interface](https://github.com/hiddify/hiddify-config/wiki#%D8%AF%D9%85%D9%88%DB%8C-%D8%B3%DB%8C%D8%B3%D8%AA%D9%85) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [FAQs](https://github.com/hiddify/hiddify-config/discussions/categories/q-a-%D8%B3%D9%88%D8%A7%D9%84%D8%A7%D8%AA-%D8%B1%D8%A7%DB%8C%D8%AC) &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [Report Bugs](https://github.com/hiddify/hiddify-config/issues)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Telegram Channel](https://t.me/hiddify)
***


<div dir="ltr" markdown="1">

## Introduction
Hiddify multi-user anti-filtering panel, with an effortless installation and supporting more than 20 protocols to circumvent filtering plus the telegram proxy.  It is a X-UI replacement.

<details markdown="1"> <summary>Supported protocols</summary> 

| Supported Configs | Supported Configs |
| - | - |
| ♥ **Telegram Proxy** ♥ | **vless+xtls** |
| **Web Socket (cdn support)**:<br> - vless+tls+ws <br>- trojan+tls+ws <br> - vmess+tls+ws | **h2+tls**:<br> - vless+tls<br> - trojan+tls<br> - vmess+tls |
| **grpc+tls**:<br> - vless+grpc+tls<br> - trojan+grpc+tls<br> - vmess+grpc+tls | **http1.1+tls**:  <br>- trojan+tls <br> - vmess+tls|
| **old configs**: <br> - trojango (cdn support) <br> - v2ray+ws (cdn support) <br> - vmess (cdn support) <br> - ss+faketls| **HTTP** <br> -unsafe, default is disable <br> - vless<br> -vmess |

</details>


<details markdown="1"> <summary>Smart proxy for non-Iranian and filtered sites</summary>
 
You can connect to the internet in 3 modes using Clash client and Hiddify panel. 
1. This method only circumvents the filtered websites via the anti-filter.
2. This method circumvents all websites except for the Iranian websites, and they can be opened without ant-filter (recommended)
3. This method circumvents all websites. 

At the same time, the proposed solution is resistant to detection by the internet filtering entities and prevents the usual attacks on the server i.e., the possibility of detection is minimal, however, do not forget to disable other ports except 22, 80 and 443.  

</details>

<details markdown="1"><summary>Other features</summary>


<details  markdown="1"> <summary>Supported operating systems</summary>
Hiddify has been tested on Ubuntu 20.04 and 22.04. Ubuntu arm64 or amd64
</details>



<details  markdown="1"> <summary>Speed test</summary>

In this way, you can check the speed of the server with and without anti-filter.

![image](https://user-images.githubusercontent.com/114227601/210183115-4e1f4186-421e-4316-8082-3ce53275adc7.png)

</details>

 

<details markdown="1"> <summary>DNS over HTTPS (CDN support)</summary>
 
To use DNS over HTTPS, just use the following DNS in the browser. 
 
 `https://yourdomain.com/yoursecret/dns/dns-query{?dns}`
 
</details>

<details markdown="1"> <summary>Redirector (CDN support)</summary> 
When you want to share Telegram proxy or Shadowsocks proxy through other programs, it is possible to redirect with CDN support. For example, if you put the Shadowsocks configuration instead of "fullURL", clicking on this link will open Shadowsocks app and activate the proxy on it. For example:
 `https://yourdomain.com/yoursecret/redirect/fullURL` 

 Replace "fullURL" by the Shadowsocks configuration. 

 
 `https://yourdomain.com/yoursecret/redirect/ss://secret/` 
 
</details>


</details>
</details>

## Installation Guide


##### Quick and easy installation guide with no technical knowledge and ssh required

- [Installation in Vultr (Recommended option to start) ](https://github.com/hiddify/hiddify-config/wiki/Vultr-نصب-خیلی-خیلی-سریع-در-ولتر)
- [Installation in Oracle Cloud (four free servers)](https://github.com/hiddify/hiddify-config/wiki/Oracle-نصب-خیلی-خیلی-سریع-در-اوراکل-کلود)
- [Installation in OVH ](https://github.com/hiddify/hiddify-config/wiki/OVH-نصب-خیلی-سریع-در-او-وی-اچ)
- [Installation in Hetzner](https://github.com/hiddify/hiddify-config/wiki/Hetzner-نصب-خیلی-سریع-در-هتزنر)

##### Installation guide on pre-prepared Ubuntu server with ssh

- [Installation on Ubuntu server (one command)](https://github.com/hiddify/hiddify-config/wiki/نصب-سریع-در-اوبونتو)
- [Installation with Docker](https://github.com/hiddify/hiddify-config/wiki/نصب-با-داکر)


<details  markdown="1"> <summary>Code for cloud-init</summary>
On some server provider websites, you can automatically install the proxy using the following script. For example, see [Hetzner]

(https://github.com/hiddify/hiddify-config/wiki/Hetzner-%D9%86%D8%B5%D8%A8-%D8%AE%DB%8C%D9%84%DB%8C-%D8%B3%D8%B1%DB%8C%D8%B9-%D8%AF%D8%B1-%D9%87%D8%AA%D8%B2%D9%86%D8%B1) and [OVH ](https://github.com/hiddify/hiddify-config/wiki/OVH-%D9%86%D8%B5%D8%A8-%D8%AE%DB%8C%D9%84%DB%8C-%D8%B3%D8%B1%DB%8C%D8%B9-%D8%AF%D8%B1-%D8%A7%D9%88-%D9%88%DB%8C-%D8%A7%DA%86)


And from `https://yourip.sslip.io`or `http://yourip` you can see the link of the user page, just put your IP instead of "yourip"

Note that this temporary link will only be active for one hour, after which it will be deactivated. 
<div dir="ltr" markdown="1">

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
  - bash install.sh

final_message: "The system is finally up, after $UPTIME seconds"
output: { all: "| tee -a /root/cloud-init-output.log" }

# you can see the generated link from the website by using http://yourip/ or https://yourip.sslip.io in one hour, after that, it will be disappeared. 
```
</div>

</details>




## User Interface
- For users
![Hiddify User Page](https://user-images.githubusercontent.com/114227601/220698460-c8b56096-f34d-413b-8129-cfd6dd29cc7e.png)

- For admin
![Hiddify Admin page](https://user-images.githubusercontent.com/114227601/220697943-b25af716-eb26-4220-867d-3c1eee4fc21b.png)











</div>

***
## Donation and support &nbsp;&nbsp;&nbsp;&nbsp; از ما حمایت کنید
The easiest way to support us is to click on the star (⭐) at the top of [GitHub page](https://github.com/hiddify/hiddify-config).
<div dir="rtl" markdown="1">

ساده‌ترین راه حمایت از ما کلیک کردن روی ستاره (⭐) بالای صفحه [گیتهاب](https://github.com/hiddify/hiddify-config) است.

</div>
We also need financial support for our services (all of our activities are done voluntarily and the financial support will be spent on the development of the project). 

<div dir="rtl" markdown="1">
ما برای سرویس هایمان به کمک مالی هم نیاز داریم (تمامی فعالیت‌های ما به صورت داوطلبانه انجام می‌شود و حمایت‌های مالی صرف توسعه پروژه می‌شود).
</div>

  - [Credit card and PayPal](https://opencollective.com/hiddify/contribute/backer-50556/checkout?interval=month&amount=25)
  - Ton: [`EQCWnykA-YhavOXgH3sf-uxtXLjy83_9n5bJPGRPE8r2247_`](https://tonwhales.com/explorer/address/EQCWnykA-YhavOXgH3sf-uxtXLjy83_9n5bJPGRPE8r2247_)
  - LiteCoin: [`MCHoh7xwaDBBnQgANPpBtXiekagV6KpdrM`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=litecoin%3AMCHoh7xwaDBBnQgANPpBtXiekagV6KpdrM&chld=H)
  - Ethereum: [`0xF15ec158318d7F5236d82d040102340B0974C3E0`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=ethereum%3A0xF15ec158318d7F5236d82d040102340B0974C3E0&chld=H)
  - Bitcoin: [`3Epy7jyUUCVb1w12MNTu2JFVVhmfpr4EGX`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=bitcoin%3A3Epy7jyUUCVb1w12MNTu2JFVVhmfpr4EGX&chld=H)
  - Dogecoin: `DJy27pQKwnhaRxWDbU6dG7UdHHif6yp8Jb`


## Collaborate with us &nbsp;&nbsp;&nbsp;&nbsp; با ما همکاری کنید
We need your collaboration in order to develop this project. If you are specialists in these areas, please do not hesitate to [contact us](https://github.com/hiddify/hiddify-config/blob/main/README.md#contact-us--%D8%B1%D8%A7%D9%87%D9%87%D8%A7%DB%8C-%D8%A7%D8%B1%D8%AA%D8%A8%D8%A7%D8%B7-%D8%A8%D8%A7-%D9%85%D8%A7):
<div dir="rtl" markdown="1">

اگر در هر یک از زمینه‌های زیر توانایی دارید، با ما در [تماس](https://github.com/hiddify/hiddify-config/blob/main/README.md#contact-us--%D8%B1%D8%A7%D9%87%D9%87%D8%A7%DB%8C-%D8%A7%D8%B1%D8%AA%D8%A8%D8%A7%D8%B7-%D8%A8%D8%A7-%D9%85%D8%A7)  باشید:
</div>

* Media production &nbsp;&nbsp;&nbsp;&nbsp; تولید محتوا
* Python developing &nbsp;&nbsp;&nbsp;&nbsp; برنامه‌نویسی پایتون 
* Kotlin developing &nbsp;&nbsp;&nbsp;&nbsp; برنامه‌نویسی کاتلین

## Contact us &nbsp;&nbsp;&nbsp;&nbsp; راه‌های ارتباط با ما
* Email: [hiddify@gmail.com](mailto:hiddify@gmail.com)
* Annoncements: [Telegram Channel](https://t.me/hiddify)
* Discussion: [Telegram Topics](https://t.me/hiddify_board)


