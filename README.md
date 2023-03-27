
<div dir="ltr" markdown="1">

 [فارسی](https://github.com/hiddify/hiddify-config/blob/main/README_fa.md)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Wiki](https://github.com/hiddify/hiddify-config/wiki)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[FAQ](https://github.com/hiddify/hiddify-config/discussions/categories/q-a-%D8%B3%D9%88%D8%A7%D9%84%D8%A7%D8%AA-%D8%B1%D8%A7%DB%8C%D8%AC)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ReportBugs](https://github.com/hiddify/hiddify-config/issues)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

![Hiddify Logo](https://user-images.githubusercontent.com/125398461/227720391-f6360e48-f211-4f56-a5b1-42522c30ecb7.png)


</div>



<div dir="ltr" markdown="1">

## Welcome to Hiddify

Hiddify is a powerful and professional anti-censorship toolbox, which is a multi-user panel with an effortless installation and supporting more than 20 protocols to circumvent filtering plus telegram proxy.  It's optimized for censorship circumvention in China, Russia and Iran and recommended by [xray](https://github.com/XTLS/Xray-core). It's a great replacement of X-UI.


<img width="97%" src="https://user-images.githubusercontent.com/125398461/227835398-b21d1442-1c70-4208-98ea-dcf3898927b6.jpg" align="center" dir="ltr"/>
<img width="97%" src="https://user-images.githubusercontent.com/125398461/227835402-5439eddc-48b0-4694-9bf2-d28c81b3740a.jpg" align="center" dir="ltr"/>


***

### Table of Contents
- [Why Hiddify?](https://github.com/hiddify/hiddify-config/blob/main/README.md#why-hiddify)
- [Installation Guide](https://github.com/hiddify/hiddify-config/blob/main/README.md#installation-guide)
  - [Installation without ssh](https://github.com/hiddify/hiddify-config/blob/main/README.md#installation-without-ssh)
  - [Installation with ssh](https://github.com/hiddify/hiddify-config/blob/main/README.md#installation-with-ssh)
- [Configuration Guide](https://github.com/hiddify/hiddify-config/blob/main/README.md#configuration-guide)
- [Donation and Support](https://github.com/hiddify/hiddify-config/blob/main/README.md#donation-and-support)
- [Collaborate with us](https://github.com/hiddify/hiddify-config/blob/main/README.md#collaborate-with-us)
- [Contact us](https://github.com/hiddify/hiddify-config/blob/main/README.md#contact-us)

***
## Why Hiddify?
Hiddify is a mixture of hidden and simplify. A feature-full panel with a wide range of capabilities that helps you enjoy surfing free internet with ease and peace of mind. 

<details markdown="1"> <summary> <b>Supported protocols</b> </summary> 

| Supported Configs | Supported Configs |
| - | - |
| ♥ **Telegram Proxy** ♥ | **vless+xtls** |
| **Web Socket (cdn support)**:<br> - vless+tls+ws <br>- trojan+tls+ws <br> - vmess+tls+ws | **h2+tls**:<br> - vless+tls<br> - trojan+tls<br> - vmess+tls |
| **grpc+tls**:<br> - vless+grpc+tls<br> - trojan+grpc+tls<br> - vmess+grpc+tls | **http1.1+tls**:  <br>- trojan+tls <br> - vmess+tls|
| **old configs**: <br> - trojango (cdn support) <br> - v2ray+ws (cdn support) <br> - vmess (cdn support) <br> - ss+faketls| **HTTP** <br> -unsafe, default is disable <br> - vless<br> -vmess |

</details>


<details markdown="1"> <summary><b>Smart proxy for domestic and filtered sites</b></summary>
 
You can connect to the internet in 3 modes using Hiddify(Clash) client and Hiddify panel. 
1. This method only circumvents filtered websites via the proxies.
2. This method circumvents all websites except domestic websites based in China, Russia and Iran. This way the domestic websites can be opened without any proxies (recommended)
3. This method circumvents all websites. 

At the same time, the proposed solution is resistant to detection by the internet filtering entities and prevents the usual attacks on the server i.e., the possibility of detection is minimal, however, do not forget to disable other ports except 22, 80 and 443.  

</details>

<details markdown="1"><summary><b>Other fantastic features</b></summary>


<details  markdown="1"> <summary>Supported operating systems</summary>
Hiddify has been tested on Ubuntu 20.04 and 22.04. Ubuntu arm64 or amd64
</details>



<details  markdown="1"> <summary>Speed test</summary>

In this way, you can check the speed of the server with and without anti-filter.

![speed_test](https://user-images.githubusercontent.com/114227601/210183115-4e1f4186-421e-4316-8082-3ce53275adc7.png)

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


##### Installation without ssh
This way you can take advantage of quick and easy installation of this panel using cloud-init scripts with no technical knowledge and even without any ssh connections

- [Installation in Vultr (Recommended option to start) ](https://github.com/hiddify/hiddify-config/wiki/Vultr-نصب-خیلی-خیلی-سریع-در-ولتر)
- [Installation in Oracle Cloud (four free servers)](https://github.com/hiddify/hiddify-config/wiki/Oracle-نصب-خیلی-خیلی-سریع-در-اوراکل-کلود)
- [Installation in OVH ](https://github.com/hiddify/hiddify-config/wiki/OVH-نصب-خیلی-سریع-در-او-وی-اچ)
- [Installation in Hetzner](https://github.com/hiddify/hiddify-config/wiki/Hetzner-نصب-خیلی-سریع-در-هتزنر)

##### Installation with ssh
Here you can use this guide on pre-prepared Ubuntu server with ssh connection

- [Installation on Ubuntu server (one command)](https://github.com/hiddify/hiddify-config/wiki/نصب-سریع-در-اوبونتو)
- [Installation with Docker](https://github.com/hiddify/hiddify-config/wiki/نصب-با-داکر)






## Configuration Guide
**Making best use of this panel via this** [guide](https://github.com/hiddify/hiddify-config/wiki/How-to-configure-Hiddify-Panel-properly).

## Donation and support 
The easiest way to support us is to click on the star (⭐) at the top of [GitHub page](https://github.com/hiddify/hiddify-config).

We also need financial support for our services (all of our activities are done voluntarily and the financial support will be spent on the development of the project). 



 - [Credit card and PayPal](https://opencollective.com/hiddify/contribute/backer-50556/checkout?interval=month&amount=25)
- <details markdown="1"> <summary>Crypto</summary> 
 
  - Ton: [`EQCWnykA-YhavOXgH3sf-uxtXLjy83_9n5bJPGRPE8r2247_`](https://tonwhales.com/explorer/address/EQCWnykA-YhavOXgH3sf-uxtXLjy83_9n5bJPGRPE8r2247_)
  - USDT (TRC20): [`TXZtFUxyBPMSykAWogu7C4zmbjySKqMcDE`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=usdt:TXZtFUxyBPMSykAWogu7C4zmbjySKqMcDE&chld=H)
  - LiteCoin: [`MCHoh7xwaDBBnQgANPpBtXiekagV6KpdrM`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=litecoin:MCHoh7xwaDBBnQgANPpBtXiekagV6KpdrM&chld=H)
  - BNB (smart chain): [`0xF5CFc65ee336B377C2a37EA3BCD0CaD0d0F0CbA0`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=bnb:0xF5CFc65ee336B377C2a37EA3BCD0CaD0d0F0CbA0&chld=H)
  - Ethereum: [`0xF5CFc65ee336B377C2a37EA3BCD0CaD0d0F0CbA0`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=ethereum:0xF5CFc65ee336B377C2a37EA3BCD0CaD0d0F0CbA0&chld=H)
  - Bitcoin: [`bc1qkfp7n3wxu2zc9mdy20cf27d5pujj65myww8f60`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=bitcoin:bc1qkfp7n3wxu2zc9mdy20cf27d5pujj65myww8f60&chld=H)
  - DOGE (Dogecoin): [`DPerFS2vCu5XnE3He32BaPVTkUDcKLsEaj`](https://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=doge:DPerFS2vCu5XnE3He32BaPVTkUDcKLsEaj&chld=H)

</details>

## Collaborate with us 
We need your collaboration in order to develop this project. If you are specialists in these areas, please do not hesitate to [contact us](https://github.com/hiddify/hiddify-config/blob/main/README.md#contact-us--%D8%B1%D8%A7%D9%87%D9%87%D8%A7%DB%8C-%D8%A7%D8%B1%D8%AA%D8%A8%D8%A7%D8%B7-%D8%A8%D8%A7-%D9%85%D8%A7):

* Media production &nbsp;&nbsp;&nbsp;&nbsp;  
* Python developing &nbsp;&nbsp;&nbsp;&nbsp; ‌  
* Kotlin developing &nbsp;&nbsp;&nbsp;&nbsp; 
## Contact us
* Email: [hiddify@gmail.com](mailto:hiddify@gmail.com)
* Annoncements: [Telegram Channel](https://t.me/hiddify)
* Discussion: [Telegram Group](https://t.me/hiddify_board/5)

<p align=center>
 We appreciate all people who are participating in this project. Some people here and many many more out of Github. It means a lot to us ♥
 </p>
 
<p align=center> 
<a href="https://github.com/hiddify/hiddify-config/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-config" />
</a>
</p>
<p align=center>
 Made with <a rel="" target="_blank" href="https://contrib.rocks">contrib.rocks</a> 
</p>
