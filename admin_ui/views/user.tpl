% include('head')





<main id="maincontent" role="main" aria-label="Content" class="flex-shrink-0">
           
            <div class="d-flex ">

                <div class="card col col-12  col-md-6">
                    <div class="card-header">
                        <i class="fa-solid fa-graduation-cap fa-margin"></i>
                        به بخش آموزش استفاده خوش آمدید

                    </div>
                    <div class="card-body">

                        <p>
                            در این سایت آموزش نحوه استفاده از پروکسی شرح داده شده است.
                        </p>
                        <p>
                            <a href="https://github.com/hiddify/hiddify-config/wiki">آموزش ساخت فیلترشکن به زبان
                                ساده</a>

                        </p>

                        <!-- <p>اگر صفحه قدیمی را میخواهید: <a href="index_old.html">کلیک کنید</a></p> -->
                        <div class="alert alert-info">
                            برای کپی یا به اشتراک گذاشتن لینک‌ها روی قسمت طوسی رنگ کلیک کنید تا QR Code
                            آن نمایش داده شود.

                            <div class="btn-group d-block d-md-none">
                                <a href="https://proxyproviderip/BASE_PATH/usersecret/"
                                    class="btn btn-primary orig-link ">لینک
                                    این صفحه</a>
                            </div>

                        </div>
                        % if data["ENABLE_TELEGRAM"]=='true':
                        <details class="accordion main-details">
                            <summary class="accordion-button">
                                <i class="fa-brands fa-telegram fa-margin"></i> گذرنده تلگرام (برای دور زدن فیلترینگ
                                تلگرام)
                            </summary>
                            <div class="card-body">

                                روی لینک «پروکسی تلگرام» کلیک کنید. سپس کافی است در صفحه‌ای که باز می‌شود، روی دکمه‌ی
                                CONNECT PROXY کلیک
                                کنید:

                                <div class="btn-group">
                                    <a href="tg://proxy?server=serverip&amp;port=443&amp;secret=ee%%TELEGRAM_SECRET%%%%HEX_TELEGRAM_DOMAIN%%"
                                        class="btn btn-primary orig-link">گذرنده پروکسی تلگرام</a>
                                </div>
                            </div>
                        </details>
                        % end
                    </div>



                </div>


                <div class="card col col-md-6 d-none d-md-block">
                    <div class="card-header">
                        <i class="fa-solid fa-qrcode fa-margin"></i> کد qr-code این صفحه
                    </div>
                    <div class="card-body">
                        <div id="qrcode2" style="margin:auto;"></div>
                        <center>
                            <figcaption class="figure-caption">برای مشاهده qr-code یا کپی لینک ها، بر روی بخش
                                خاکستری لینک‌ها کلیک کنید.</figcaption>


                            <div class="btn-group">
                                <a href="https://proxyproviderip/BASE_PATH/usersecret/"
                                    class="btn btn-primary orig-link share-link">لینک این صفحه</a>
                            </div>
                        </center>
                    </div>
                </div>

            </div>



            <!--
# گذرنده سیگنال
بر روی لینک زیر کلیک کنید تا بر روی سیگنال شما تنظیم شود.
<a href="https://signal.tube/#proxyproviderip/BASE_PATH/eeusersecret%%HEX_TELEGRAM_DOMAIN%%/" class='btn btn-primary'>گذرنده سیگنال کلیک کنید</a>
-->

            <div class="card d-none d-md-block">
                <div class="card-header">
                    <i class="fa-solid fa-globe fa-margin"></i>
                    گذرنده سایت ها و اپلیکشن ها:
                </div>

            </div>



            <div class="row">
                <div class="col-md-6">
                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-brands fa-android fa-margin"></i> اندروید - Android
                        </summary>
                        <div class="card-body">
                            ابتدا نرم افزار HiddifyProxy را از طریق لینک زیر نصب کنید

                            <div class="alert alert-danger">
                                <h5>مهم: نرم افزار هایدیفای پروکسی را به نسخه 0.7 آپدیت کنید</h5>
                            </div>
                            <div class="btn-group">
                                <a href="/BASE_PATH/gh/hiddify/HiddifyProxyAndroid/releases/download/v0.7/hiddify-2.5.13-pre04-h0.7-meta-alpha-universal-release.apk"
                                    class="btn btn-primary orig-link">دانلود نرم افزار HiddifyProxy</a>
                            </div>
                            <div class="alert alert-info">
                                هایدیفای پروکسی، یک نسخه پیشرفته کلش هست که پروتکل‌های بیشتر را پیشتبانی میکنه.
                                <br>
                                این نرم افزار کاملا امن و کدباز هست و کلیه کدهای آن در
                                <a href="https://github.com/hiddify/HiddifyProxyAndroid">گیت هاب</a>
                                وجود دارد.
                                <br>
                                خیالتون راحت باشه پس 🙃

                                <details>
                                    <summary>نرم افزار جایگزین: کلش اندروید عادی</summary>
                                    <div class="btn-group">
                                        <a href="https://play.google.com/store/apps/details?id=com.github.kr328.clash"
                                            class="btn btn-warning orig-link">دانلود کلش از گوگل پلی</a>
                                    </div>
                                    <div class="btn-group">
                                        <a href="/BASE_PATH/gh/Kr328/ClashForAndroid/releases/download/v2.5.12/cfa-2.5.12-premium-universal-release.apk"
                                            class="btn btn-warning orig-link">دانلود مستقیم کلش</a>
                                    </div>

                                    <div class="alert alert-danger">
                                        توجه کنید کلش اندروید پروتکل vless را ساپورت نمیکنه.

                                        <br>
                                        بنابراین لینک های آن متفاوت است.
                                    </div>
                                    <!--                                             <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/normal/lite.yml&name=lite_proxyproviderip"
                                            class="btn btn-primary orig-link">نصب فقط برای سایت‌های فیلتر</a>
                                    </div>
                                            <br>
                                    <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/normal/normal.yml&name=normal_proxyproviderip"
                                            class="btn btn-primary orig-link">نصب گذرنده برای سایت‌های خارجی</a>
                                    </div>
                                            
                                    <br>
                                        <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/all.yml&name=all_proxyproviderip"
                                            class="btn btn-primary orig-link">نصب گذرنده برای همه سایت‌ها</a>
                                    </div> -->




                                </details>
                            </div>


                            <!--                                         

                                با استفاده از یکی از دو لینک زیر، اپلیکیشن کلش Clash را دانلود و نصب کنید. 
                                
                                <br>
                                 -->


                            <h2>لینک تنظیمات:</h2>
                            حالا با توجه به نیازتان روی یکی از دکمه‌ها کلیک کنید:
                            <div class="alert alert-success">
                                <h5> گذرنده فقط برای سایت‌های فیلتر شده
                                </h5>
                                اگر فقط قصد دسترسی به سایت‌های فیلتر نشده را دارید، از این لینک استفاده کنید. در این
                                حالت سایت‌های فیلتر نشده بدون هیچ افت سرعتی کار می‌کنند.

                                <br>
                                <div class="btn-group">
                                    <a href="clashmeta://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/meta/lite.yml&name=mlite_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب فقط برای سایت‌های فیلتر</a>
                                </div>
                                <details>
                                    <summary>لینک جایگزین برای کلش عادی</summary>
                                    <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/lite.yml&name=lite_proxyproviderip"
                                            class="btn btn-warning orig-link">لینک برای کلش اندروید</a>
                                    </div>
                                </details>
                            </div>
                            <div class="alert alert-info">
                                <h5>
                                    گذرنده فقط برای سایت‌های خارجی
                                </h5>
                                اگر فقط قصد دسترسی به سایت‌های خارجی را دارید، از این لینک استفاده کنید. این حالت
                                برای
                                گذر از برخی از تحریم‌های سایت‌های خارجی مفید است.
                                <br />
                                <div class="btn-group">
                                    <a href="clashmeta://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/meta/normal.yml&name=mnormal_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب گذرنده برای سایت‌های خارجی</a>
                                </div>
                                <details>
                                    <summary>لینک جایگزین برای کلش عادی</summary>
                                    <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/normal.yml&name=normal_proxyproviderip"
                                            class="btn btn-warning orig-link">لینک برای کلش اندروید</a>
                                    </div>
                                </details>
                            </div>
                            % if data["BLOCK_IR_SITES"]=='false':
                            <div class="alert alert-warning">
                                <h5>
                                    گذرنده همه سایت‌ها
                                </h5>
                                اگر می‌خواهید برای دسترسی به همه سایت‌ها (چه فیلتر شده و چه غیر فیلتر) از پروکسی
                                استفاده
                                کنید، از این لینک استفاده کنید. این حالت باعث کاهش سرعت سایت‌های داخلی می‌شود. علاوه
                                بر
                                آن، اگر قصد استفاده از اپ‌های بانکی را دارید، از این لینک استفاده نکنید.

                                <div class="alert alert-danger">
                                    در این حالت سرعت سایت‌های داخلی شدیدا کاهش پیدا می‌کند.
                                </div>

                                <div class="btn-group">
                                    <a href="clashmeta://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/meta/all.yml&name=mall_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب گذرنده برای همه سایت‌ها</a>
                                </div>
                                <details>
                                    <summary>لینک جایگزین برای کلش عادی</summary>
                                    <div class="btn-group">
                                        <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/all.yml&name=all_proxyproviderip"
                                            class="btn btn-warning orig-link">لینک برای کلش اندروید</a>
                                    </div>
                                </details>
                            </div>
                            % end
                            <!--
                                ابندا یکی از لینک تنظیمات کلش را کپی کنید و در بخش 2 مرحله 4 قرار دهید و مراحل را مطابق
                                گیف
                                زیر انجام دهید


                                 <figure class="figure d-block text-center p-3">
                                    <img src="images/clash_android.gif" alt="How to use clash for Android"
                                        class="figure-img img-fluid rounded" />
                                    <figcaption class="figure-caption">
                                        <p>How to use clash for Android</p>
                                    </figcaption>
                                </figure> -->
                        </div>

                    </details>
                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-brands fa-app-store-ios fa-margin"></i>
                            آیفون - iPhone - iOS
                        </summary>
                        <div class="card-body">


                            ابتدا نرم افزار زیر را دانلود کنید:
                            <div class="btn-group">
                                <a href="https://apps.apple.com/us/app/shadowlink-shadowsocks-vpn/id1439686518"
                                    class="btn btn-primary orig-link"> نرم افزار shadow link</a>
                            </div>
                            <details>
                                <summary>نرم افزار جایگزین</summary>
                                <div class="btn-group">
                                    <a href="https://apps.apple.com/us/app/fair-vpn/id1533873488"
                                        class="btn btn-primary orig-link"> نرم افزار fair-vpn</a>

                                </div>
                            </details>
                            <h2>
                                کار در iOS
                            </h2>
                            ابتدا بر روی دکمه "نصب با یک کلیک" کلیک کنید و سپس مود را انتخاب و اجرا نمایید. توجه
                            نمایید
                            در iOS نمیتوان رایگان هوشمند کار کرد.

                            <br />

                            <div class="btn-group">
                                <a href='vless://userguidsecret@cloudprovider:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Fvlessws#CDNvless_ws_proxyproviderip'
                                    class="btn btn-primary orig-link"> CDN vless+ws</a>
                            </div>
                            <div class="btn-group">
                                <a href='trojan://userguidsecret@cloudprovider:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Ftrojanws#CDNtrojan_ws_proxyproviderip'
                                    class="btn btn-primary orig-link"> CDN trojan+ws</a>
                            </div>
                            <div class="btn-group">
                                <a href='vless://userguidsecret@serverip:443?flow=xtls-rprx-direct&security=xtls&alpn=h2&sni=proxyproviderip&type=tcp#vless+xtls_proxyproviderip'
                                    class="btn btn-primary orig-link"> vless+xtls</a>
                            </div>
                            <div class="btn-group">
                                <a href='vless://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=grpc&serviceName=usersecret-vlgrpc&mode=multi#vless-grpc_proxyproviderip'
                                    class="btn btn-primary orig-link"> vless+grpc</a>
                            </div>
                            <div class="btn-group">
                                <a href='trojan://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=grpc&serviceName=usersecret-trgrpc&mode=multi#trojan-grpc_proxyproviderip'
                                    class="btn btn-primary orig-link"> trojan+grpc</a>
                            </div>
                            % if data["ENABLE_VMESS"]=='true':
                            <div class="btn-group">
                                <a href='vmess://{"v":"2", "ps":"CDNvmess_ws_proxyproviderip", "add":"cloudprovider", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"proxyproviderip"}'
                                    class="btn btn-primary orig-link"> CDN vmess+ws</a>
                            </div>
                            % end

                            <!--
        <br/>
        <br/>        
        
        
<a href="ss://chacha20-ietf-poly1305:usersecret@proxyproviderip:443?plugin=v2ray-plugin%3Bmode%3Dwebsocket%3Bpath%3D%2Fusersecret%2Fv2ray%2F%3Bhost%3Dproxyproviderip%3Btls&udp-over-tcp=true#v2ray_proxyproviderip" class="btn btn-primary orig-link"> نصب کانفیگ قدیمی</a>
<a href="ss://chacha20-ietf-poly1305:usersecret@proxyproviderip:443?plugin=v2ray-plugin%3Bmode%3Dwebsocket%3Bpath%3D%2Fusersecret%2Fv2ray%2F%3Bhost%3Dproxyproviderip%3Btls&udp-over-tcp=true#v2ray_proxyproviderip" class="btn btn-success copylink">کپی لینک</a>
        <br/>
        <br/>
<a href="ss://chacha20-ietf-poly1305:usersecret@proxyproviderip:443?plugin=obfs-local%3Bobfs%3Dtls%3Bobfs-host%3Dwww.google.com&udp-over-tcp=true#proxyproviderip" class="btn btn-primary orig-link">نصب کانفیگ قدیمی2</a>
<a href="ss://chacha20-ietf-poly1305:usersecret@proxyproviderip:443?plugin=obfs-local%3Bobfs%3Dtls%3Bobfs-host%3Dwww.google.com&udp-over-tcp=true#proxyproviderip" class="btn btn-success copylink">کپی لینک</a>
        -->

                            <figure class="figure d-block text-center p-3">
                                <img src="images/ios_shadow.gif" alt="How to use v2 ray for iOS"
                                    class="figure-img img-fluid rounded" />
                                <figcaption class="figure-caption">
                                    <p>How to use clash for iOS</p>
                                </figcaption>
                            </figure>

                        </div>
                    </details>

                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-solid fa-gauge-high fa-margin"></i>
                            تست سرعت (شناسایی IP کثیف)
                        </summary>
                        <div class="card-body">

                            ابتدا بدون فیلترشکن سرعت را تست کنید. اگر سرعت خوب نبود، به معنی آن است که این ip به
                            اصطلاح
                            کثیف
                            شده
                            روی
                            سرویس دهنده اینترنت شما.
                            <br>
                            اگر بدون فیلترشکن سرعت پایین بود دیگر وقت خود را تلف نکنید.
                            <br>
                            در غیر این صورت با پروکسی های مختلف این سایت تست بگیرید و اگر سرعت آن مشابه سرعت بدون
                            فیلترشکن
                            بود
                            یعنی
                            بهترین پروتکل را پیدا کردید.

                            <br />
                            <div class="btn-group">
                                <a href="/BASE_PATH/speedtest/?test=upload" class="btn btn-primary">تست آپلود</a>
                                <a href="/BASE_PATH/speedtest/?test=download" class="btn btn-primary">تست دانلود</a>
                                <a href="/BASE_PATH/speedtest/?run" class="btn btn-primary">تست کامل</a>
                            </div>
                        </div>
                    </details>
                </div>


































                <div class="col-md-6">

                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-brands fa-windows fa-margin"></i> ویندوز، <i
                                class="fa-brands fa-apple fa-margin"></i>
                            macOS و <i class="fa-brands fa-linux fa-margin"></i> لینوکس
                        </summary>

                        <div class="card-body">
                            ابتدا نرم‌افزار کلشClash را با توجه به سیستم عامل خود دانلود و نصب کنید.
                            <br>

                            <div class="btn-group">
                                <a class="btn btn-primary"
                                    href="/BASE_PATH/gh/Fndroid/clash_for_windows_pkg/releases/download/0.20.9/Clash.for.Windows.Setup.0.20.9.exe"><i
                                        class="fa-brands fa-windows fa-margin"></i> Windows</a>
                                <a class="btn btn-secondary"
                                    href="/BASE_PATH/gh/Fndroid/clash_for_windows_pkg/releases/download/0.20.9/Clash.for.Windows-0.20.9.dmg"><i
                                        class="fa-brands fa-apple fa-margin"></i> macOS</a>
                                <a class="btn btn-success"
                                    href="/BASE_PATH/gh/Fndroid/clash_for_windows_pkg/releases/download/0.20.9/Clash.for.Windows-0.20.9-x64-linux.tar.gz"><i
                                        class="fa-brands fa-linux fa-margin"></i> Linux</a>

                            </div>
                            <br>

                            حالا با توجه به نیازتان می‌توانید روی یکی از دکمه‌ها کلیک کنید. با مشاهده‌‌ی پنجره در
                            مرورگرتان کافی است روی گزینه‌ی Open Clash for Windows کلیک کنید تا به صورت خودکار لینک
                            سرور به کلش اضافه شود.

                            <h2>لینک تنظیمات:</h2>
                            حالا با توجه به نیازتان روی یکی از دکمه‌ها کلیک کنید:
                            <div class="alert alert-success">
                                <h5> گذرنده فقط برای سایت‌های فیلتر شده
                                </h5>
                                اگر فقط قصد دسترسی به سایت‌های فیلتر نشده را دارید، از این لینک استفاده کنید. در این
                                حالت سایت‌های فیلتر نشده بدون هیچ افت سرعتی کار می‌کنند.

                                <br>
                                <div class="btn-group">
                                    <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/lite.yml&name=lite_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب فقط برای سایت‌های فیلتر</a>
                                </div>
                            </div>
                            <div class="alert alert-info">
                                <h5>
                                    گذرنده فقط برای سایت‌های خارجی
                                </h5>
                                اگر فقط قصد دسترسی به سایت‌های خارجی را دارید، از این لینک استفاده کنید. این حالت
                                برای
                                گذر از برخی از تحریم‌های سایت‌های خارجی مفید است.
                                <br />
                                <div class="btn-group">
                                    <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/normal.yml&name=normal_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب گذرنده برای سایت‌های خارجی</a>
                                </div>
                            </div>
                            % if data["BLOCK_IR_SITES"]=='false':
                            <div class="alert alert-warning">
                                <h5>
                                    گذرنده همه سایت‌ها
                                </h5>
                                اگر می‌خواهید برای دسترسی به همه سایت‌ها (چه فیلتر شده و چه غیر فیلتر) از پروکسی
                                استفاده
                                کنید، از این لینک استفاده کنید. این حالت باعث کاهش سرعت سایت‌های داخلی می‌شود. علاوه
                                بر
                                آن، اگر قصد استفاده از اپ‌های بانکی را دارید، از این لینک استفاده نکنید.

                                <div class="alert alert-danger">
                                    در این حالت سرعت سایت‌های داخلی شدیدا کاهش پیدا می‌کند.
                                </div>

                                <div class="btn-group">
                                    <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/all.yml&name=all_proxyproviderip"
                                        class="btn btn-primary orig-link">نصب گذرنده برای همه سایت‌ها</a>
                                </div>
                            </div>
                            % end
                            <h2>
                                کار با کلش ویندوز، مک و لینوکس
                            </h2>
                            چنانچه بر روی دکمه "نصب با یک کلیک" کلیک کرده اید دیگر نیاز به انجام مرحله دوم را ندارید
                            فقط
                            مرحله اول کافی است
                            ابندا یکی از لینک تنظیمات کلش را کپی کنید و در قسمت 1 تصویر دوم گیف قرار دهید و مراحل را
                            مطابق گیف زیر انجام دهید

                            <figure class="figure d-block text-center p-3">
                                <img src="images/clash_windows.gif" alt="How to use clash for windows and macOS"
                                    class="figure-img img-fluid rounded" />
                                <figcaption class="figure-caption">
                                    <p>How to use clash for windows and macOS</p>
                                </figcaption>
                            </figure>


                        </div>
                    </details>






















                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-solid fa-grip fa-margin"></i> همه کانفیگ ها
                        </summary>

                        <div class="card-body">
                            در این بخش کلیه کانفیگ ها قرار گرفته است. کافی است کانفیگ مورد نظر خورد را انتخاب و
                            استفاده کنید.

                            <!-- <div class="btn-group">
                                    <a href="/BASE_PATH/gh/hiddify/HiddifyProxyAndroid/releases/download/v0.6/hiddify-2.5.13-pre04-h0.6-meta/alpha-universal-release.apk"
                                        class="orig-link"><img src="images/android-apk-badge.png" /></a>
                                </div> -->


                            <details>
                                <summary>نرم افزار های پیشنهادی</summary>
                                <details>
                                    <summary>اندروید</summary>
                                    <div class="btn-group">
                                        <a href="/BASE_PATH/gh/hiddify/HiddifyProxyAndroid/releases/download/v0.7/hiddify-2.5.13-pre04-h0.7-meta-alpha-universal-release.apk"
                                            class="btn btn-primary orig-link">دانلود نرم افزار HiddifyProxy</a>
                                    </div>

                                    <div class="btn-group">
                                        <a href="https://play.google.com/store/apps/details?id=moe.matsuri.lite"
                                            class="btn btn-primary orig-link">نرم افزار Matsuri از گوگل پلی</a>
                                    </div>

                                    <div class="btn-group">
                                        <a href="/BASE_PATH/gh/MatsuriDayo/Matsuri/releases/"
                                            class="btn btn-primary orig-link">نرم
                                            افزار Matsuri مستقیم</a>
                                    </div>
                                    <div class="btn-group">
                                        <a href="https://play.google.com/store/apps/details?id=com.v2ray.ang"
                                            class="btn btn-primary orig-link">نرم افزار v2rayng از گوگل پلی</a>
                                    </div>

                                    <div class="btn-group">
                                        <a href="/BASE_PATH/gh/2dust/v2rayNG/releases/"
                                            class="btn btn-primary orig-link">نرم
                                            افزار v2rayng مستقیم</a>
                                    </div>

                                    <div class="btn-group">
                                        <a href="https://play.google.com/store/apps/details?id=io.nekohasekai.sagernet"
                                            class="btn btn-primary orig-link">نرم افزار sagernet از گوگل پلی</a>
                                    </div>

                                    <div class="btn-group">
                                        <a href="/BASE_PATH/gh/SagerNet/SagerNet/releases/"
                                            class="btn btn-primary orig-link">نرم
                                            افزار sagernet مستقیم</a>
                                    </div>
                                </details>
                            </details>

                            <!-- 
                                ابتدا نرم افزار SagerNet را از طریق یکی از لینک‌های زیر دانلود کنید.
                                <br>
                                <div class="btn-group">
                                <a href="https://play.google.com/store/apps/details?id=io.nekohasekai.sagernet" class="orig-link"><img
                                        src="images/google-play-badge.png" /></a>
                                        </div>
                                        <div class="btn-group">
                                <a href="/BASE_PATH/gh/SagerNet/SagerNet/releases/download/0.8.1-rc03/SN-0.8.1-rc03-arm64-v8a.apk" class="orig-link"><img
                                        src="images/android-apk-badge.png" /></a>
                                    </div>

                                <br> -->
                            سپس روی یکی از دکمه‌های زیر (به دلخواه) کلیک کنید تا لینک با اپ هایدیفای باز شود. سپس در
                            نرم افزار HiddifyProxy با زدن روی دکمه YES درخواست وارد کردن لینک را تایید کنید.
                            <br />
                            <details class="accordion">
                                <summary class="card-header">تنظیمات تکی</summary>
                                % if data["FAKE_CDN_DOMAIN"]!='':
                                <h5>تنظیمات با پشتیبانی FakeCDN</h5>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@data["FAKE_CDN_DOMAIN"]:443?security=tls&sni=data["FAKE_CDN_DOMAIN"]&type=ws&host=proxyproviderip&path=%2FBASE_PATH%2Fvlessws#FakeCDNvless_ws_proxyproviderip'
                                        class="btn btn-primary orig-link">FakeCDN vless+ws</a>
                                </div>
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@data["FAKE_CDN_DOMAIN"]:443?security=tls&sni=data["FAKE_CDN_DOMAIN"]&type=ws&host=proxyproviderip&path=%2FBASE_PATH%2Ftrojanws#FakeCDNtrojan_ws_proxyproviderip'
                                        class="btn btn-primary orig-link">FakeCDN trojan+ws</a>
                                </div>
                                    % if data["ENABLE_VMESS"]=='true':
                                    <div class="btn-group">
                                        <a href='vmess://{"v":"2", "ps":"FakeCDNvmess_ws_proxyproviderip", "add":"cloudprovider", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"proxyproviderip", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"data["FAKE_CDN_DOMAIN"]"}'
                                            class="btn btn-primary orig-link">FakeCDN vmess+ws</a>
                                    </div>
                                    % end
                                % end
                                <h5>تنظیمات با پشتیبانی CDN</h5>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@cloudprovider:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Fvlessws#CDNvless_ws_proxyproviderip'
                                        class="btn btn-primary orig-link"> CDN vless+ws</a>
                                </div>
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@cloudprovider:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Ftrojanws#CDNtrojan_ws_proxyproviderip'
                                        class="btn btn-primary orig-link"> CDN trojan+ws</a>
                                </div>
                                % if data["ENABLE_VMESS"]=='true':
                                <div class="btn-group">
                                    <a href='vmess://{"v":"2", "ps":"CDNvmess_ws_proxyproviderip", "add":"cloudprovider", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"proxyproviderip"}'
                                        class="btn btn-primary orig-link"> CDN vmess+ws</a>
                                </div>
                                % end
                                <h5>تنظیمات بدون CDN</h5>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Fvlessws#vless_ws_proxyproviderip'
                                        class="btn btn-primary orig-link"> vless+ws</a>
                                </div>
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=ws&path=%2Fusersecret%2Ftrojanws#trojan_ws_proxyproviderip'
                                        class="btn btn-primary orig-link"> trojan+ws</a>
                                </div>
                                % if data["ENABLE_VMESS"]=='true':
                                <div class="btn-group">
                                    <a href='vmess://{"v":"2", "ps":"vmess_ws_proxyproviderip", "add":"serverip", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"ws", "type":"none", "host":"", "path":"/BASE_PATH/vmessws", "tls":"tls", "sni":"proxyproviderip"}'
                                        class="btn btn-primary orig-link"> vmess+ws</a>
                                </div>
                                % end
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?flow=xtls-rprx-direct&security=xtls&alpn=h2&sni=proxyproviderip&type=tcp#vless+xtls_proxyproviderip'
                                        class="btn btn-primary orig-link"> vless+xtls</a>
                                </div>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=grpc&serviceName=usersecret-vlgrpc&mode=multi#vless-grpc_proxyproviderip'
                                        class="btn btn-primary orig-link"> vless+grpc</a>
                                </div>
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@serverip:443?security=tls&alpn=h2&sni=proxyproviderip&type=grpc&serviceName=usersecret-trgrpc&mode=multi#trojan-grpc_proxyproviderip'
                                        class="btn btn-primary orig-link"> trojan+grpc</a>
                                </div>
                                % if data["ENABLE_VMESS"]=='true':
                                <div class="btn-group">
                                    <a href='vmess://{"v":"2", "ps":"vmess_grpc_proxyproviderip", "add":"serverip", "port":"443", "id":"userguidsecret", "aid":"0", "scy":"auto", "net":"grpc", "type":"multi", "host":"", "path":"usersecret-vmgrpc", "tls":"tls", "sni":"proxyproviderip"}'
                                        class="btn btn-primary orig-link">vmess+grpc</a>
                                </div>
                                % end
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=h2&type=tcp#trojan+tls_proxyproviderip'
                                        class="btn btn-primary orig-link">trojan+tls</a>
                                </div>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=h2&type=tcp#vless+tls_proxyproviderip'
                                        class="btn btn-primary orig-link">vless+tls</a>
                                </div>
                                % if data["ENABLE_VMESS"]=='true':
                                <div class="btn-group">
                                    <a href='vmess://{"v": "2", "ps": "vmess+tls_proxyproviderip", "add": "serverip", "port": "443", "id": "userguidsecret", "aid": "0", "scy": "auto", "net": "tcp", "type":"http", "host": "", "path": "/BASE_PATH/vmtc", "tls": "tls", "sni": "proxyproviderip", "alpn": "h2"}'
                                        class="btn btn-primary orig-link">vmess+tls</a>
                                </div>
                                % end
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=http/1.1&type=tcp#vless+tls+http1.1_proxyproviderip'
                                        class="btn btn-primary orig-link">vless+tls+http/1.1</a>
                                </div>
                                <div class="btn-group">
                                    <a href='vless://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=http/1.1&type=tcp&path=/BASE_PATH/trtc&headerType=http#vless+tls+http1.1+path_proxyproviderip'
                                        class="btn btn-primary orig-link">vless+tls+http/1.1+path</a>
                                </div>
                                <div class="btn-group">
                                    <a href='trojan://userguidsecret@serverip:443?security=tls&sni=proxyproviderip&alpn=http/1.1&type=tcp&headerType=http&path=/BASE_PATH/trtc#trojan+tls+http1.1_proxyproviderip'
                                        class="btn btn-primary orig-link">trojan+tls+http/1.1</a>
                                </div>
                                % if data["ENABLE_VMESS"]=='true':
                                <div class="btn-group">
                                    <a href='vmess://{"v": "2", "ps": "vmess+tls+http1.1_proxyproviderip", "add": "serverip", "port": "443", "id": "userguidsecret", "aid": "0", "scy": "auto", "net": "tcp", "type": "http", "host": "", "path": "/BASE_PATH/vmtc", "tls": "tls", "sni": "proxyproviderip", "alpn": "http/1.1"}'
                                        class="btn btn-primary orig-link">vmess+tls+http/1.1</a>
                                </div>
                                % end

                            </details>



                            <h5>همه در یک فایل</h5>
                            <div class="btn-group">
                                <a href="clashmeta://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/meta/all.yml&name=meta_normal_proxyproviderip"
                                    class="btn btn-primary orig-link">فایل هایدیفای پروکسی</a>
                            </div>
                            <div class="btn-group">
                                <a href="clash://install-config?url=https://proxyproviderip/BASE_PATH/usersecret/clash/all.yml&name=new_normal_proxyproviderip"
                                    class="btn btn-primary orig-link">فایل کلش</a>
                            </div>
                            <div class="btn-group">
                                <a href="https://proxyproviderip/BASE_PATH/usersecret/all.txt?name=new_link_proxyproviderip"
                                    class="btn btn-primary orig-link">همه تنظیمات به صورتی لینکی</a>
                            </div>

                        </div>
                    </details>



                    <details class="accordion main-details">
                        <summary class="accordion-button">
                            <i class="fa-solid fa-sitemap fa-margin"></i>
                            DNS over HTTPS
                        </summary>
                        <div class="card-body">
                            کافی است در مرورگر خود عبارت زیر را وارد کنید:

                            <pre dir="ltr">
https://proxyproviderip/BASE_PATH/dns/dns-query
                    </pre>
                            <div dir="ltr">
                                <h4>Configure DoH on your browser</h4>
                                There are several browsers compatible with DNS over HTTPS (DoH). This protocol lets
                                you
                                encrypt
                                your connection to 1.1.1.1 in order to protect your DNS queries from privacy
                                intrusions
                                and
                                tampering.

                                Some browsers might already have this setting enabled.

                                <h5>​​Mozilla Firefox</h5>
                                Select the menu button > Settings.
                                In the General menu, scroll down to access Network Settings.
                                Select Settings.
                                Select Enable DNS over HTTPS. By default, it resolves to Cloudflare DNS.
                                ​<h5>​Google Chrome</h5>
                                Select the three-dot menu in your browser > Settings.
                                Select Privacy and security > Security.
                                Scroll down and enable Use secure DNS.
                                Select the With option, and from the drop-down menu choose Cloudflare (1.1.1.1).
                                <h5>​​Microsoft Edge</h5>
                                Select the three-dot menu in your browser > Settings.
                                Select Privacy, Search, and Services, and scroll down to Security.
                                Enable Use secure DNS.
                                Select Choose a service provider.
                                Select the Enter custom provider drop-down menu and choose Cloudflare (1.1.1.1).
                                ​<h5>​Brave</h5>
                                Select the menu button in your browser > Settings.
                                Select Security and Privacy > Security.
                                Enable Use secure DNS.
                                Select With Custom and choose Cloudflare (1.1.1.1) as a service provider from the
                                drop-down
                                menu.
                            </div>
                        </div>
                    </details>
                </div>
        </main>
        <div class="b-example-divider"></div>
        <div class="container">
            <footer class="d-flex flex-wrap justify-content-between align-items-center py-3 my-4 border-top" dir="ltr">
                <div class="col-md-4 d-flex align-items-center">
                    <a href="/" class="mb-3 me-2 mb-md-0 text-muted text-decoration-none lh-1">
                        <svg class="bi" width="30" height="24">
                            <use xlink:href="#bootstrap"></use>
                        </svg>
                    </a>
                    <span class="mb-3 mb-md-0 text-muted">© 2023 Hiddify <a
                            href="https://github.com/hiddify/hiddify-config/wiki">Source Code</a></span>
                </div>

                <ul class="nav col-md-4 justify-content-end list-unstyled d-flex">
                    <li class="ms-3"><a class="text-muted"
                            href="https://twitter.com/intent/follow?screen_name=hiddify1">
                            Twitter </a></li>
                    <li class="ms-3"><a class="text-muted" href="https://t.me/hiddify">Telegram</a></li>
                </ul>
            </footer>
        </div>
    </div>

    <style>
        .fa-margin {
            margin-left: 10px;
            margin-right: 5px;
        }

        .text-break {
            word-wrap: break-word !important;
            word-break: break-word !important;
        }

        .btn-group {
            margin-bottom: 10px;
        }

        #qrcode2 img {
            margin: auto;
        }
    </style>

    <script>
        function parseQuery(queryString) {
            var query = {};
            var pairs = (queryString[0] === '?' ? queryString.substr(1) : queryString).split('&');
            for (var i = 0; i < pairs.length; i++) {
                var pair = pairs[i].split('=');
                query[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1] || '');
            }
            return query;
        }

        secret = document.location.pathname.split('/')[1];

        host = document.location.host;
        cloudprovid = document.location.host;

        function replace_info(str) {
            // str = str.replaceAll('usersecret', secret);
            // str = str.replaceAll('proxyproviderip', host);
            // str = str.replaceAll('cloudprovider', cloudprovid);

            if (str.includes('vmess://')) {
                splt = str.split('vmess://')
                return "vmess://" + btoa(splt[1])
            }

            if (str.includes('vmess%3A%2F%2F')) {
                splt = str.split('vmess%3A%2F%2F')
                return splt[0] + "vmess%3A%2F%2F" + btoa(splt[1])
            }
            return str;
        }


        codes = document.getElementsByTagName('code');
        for (i = 0; i < codes.length; i++) {
            codes[i].innerHTML = replace_info(codes[i].innerHTML);
        }

        as = document.getElementsByTagName('a');
        for (i = 0; i < as.length; i++) {
            as[i].href = replace_info(as[i].href);
            as[i].innerHTML = replace_info(as[i].innerHTML);
        }


    </script>
    <div class="modal fade" id="share-qr-code" tabindex="-1" role="dialog" aria-labelledby="exampleModalLongTitle"
        aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="exampleModalLongTitle">لینک اشتراک برای شبکه های اجتماعی</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <center>
                        <a id='qrcode-link' class="btn btn-primary copy-link" href="">کپی لینک</a>
                        <a id="share-link-redirect" class="btn btn-success copy-link" href="">کپی لینک جهت اشتراک
                            گذاری</a>
                        <br />
                        <div id="qrcode" style="margin:10px;"></div>
                    </center>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary close" data-dismiss="modal">بستن</button>
                </div>
            </div>
        </div>
    </div>
<script src="static/js/jquery-3.6.1.min.js"></script>
<script src="static/js/qrcode.js"></script>

    <script>
        // When the user scrolls down from the top of the document, show the button
        window.onscroll = function () {
            if (document.body.scrollTop > 500 || document.documentElement.scrollTop > 500) {
                document.getElementById("scroll-to-top").style.display = "block";
            } else {
                document.getElementById("scroll-to-top").style.display = "none";
            }
        }
        // scroll to top function
        function scrollToTop() {
            window.scroll({
                top: 0,
                left: 0,
                behavior: 'smooth'
            });
        }
        function copy_click(e) {
            e.preventDefault();
            console.log(this); console.log(e);
            var link = this.href;
            navigator.clipboard.writeText(link).then(function () {
                alert('Link Copied to clipboard ' + link);
            }, function (err) {
                window.prompt("Copy to clipboard: Ctrl+C, Enter", link);
            });
        }
        w = Math.min(window.innerWidth, window.innerHeight) * .75;
        qrcode = new QRCode(document.getElementById("qrcode"), { width: w, height: w, correctLevel: 1 });
        w = Math.min(window.innerWidth, window.innerHeight) * .75;
        qrcode2 = new QRCode(document.getElementById("qrcode2"), { width: w / 2, height: w / 2, correctLevel: 1 });
        qrcode2.clear()
        qrcode2.makeCode(document.location.href);
        function share_click(e) {
            e.preventDefault();
            var link = this.href;
            qrcode.clear()
            qrcode.makeCode(link);
            hrefshare = "https://proxyproviderip/BASE_PATH/redirect/" + link.replaceAll('://', '%3A%2F%2F')
            $('#qrcode-link')[0].href = link
            $('#share-link-redirect')[0].href = hrefshare
            if (link.startsWith("http"))
                $('#share-link-redirect').hide()
            else
                $('#share-link-redirect').show()
            $('#share-qr-code').modal('show');
        }
        $(document).ready(function () {
            $('a.orig-link').each((i, p) => {
                href = p.href
                if (href.startsWith("clash://install-config?url=")) {
                    href = href.replaceAll('clash://install-config?url=', '');
                    href = href.replaceAll(".yml&", ".yml?")
                }
                if (href.startsWith("clashmeta://install-config?url=")) {
                    href = href.replaceAll('clashmeta://install-config?url=', '');
                    href = href.replaceAll(".yml&", ".yml?")
                }

                // ecopy = ' <a href="' + href + '" class="btn btn-success copy-link">کپی لینک</a>'
                eshare = ' <a href="' + href + '" class="btn btn-secondary share-link"><i class="fa-solid fa-qrcode"></i></a>'
                $(eshare).insertBefore(p);
                // $(ecopy).insertAfter(p);
            });
            $('a.copy-link').click(copy_click)
            $('a.share-link').click(share_click)
            $('.close').click(() => $('.modal').modal('hide'))
        });


        const Main_Details = document.querySelectorAll('.main-details');

        Main_Details.forEach(deet => {
            deet.addEventListener('toggle', toggleOpenOneOnly)
        })

        function toggleOpenOneOnly(e) {
            if (this.open) {
                Main_Details.forEach(deet => {
                    if (deet != this && deet.open) deet.open = false
                });
            }
        }
    </script>


% include('tail')
