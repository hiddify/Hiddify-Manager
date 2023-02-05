% include('head')

<div class="alert alert-danger">
توجه! این نسخه قدیمی است و دیگر پشتیبانی و آپدیت نمی شود.
<br/>
از تاریخ 4 فوریه 2023 یا 18 بهمن 1401 می‌توانید به صورت دستی به نسخه جدید ارتقا دهید.
<br/>
در این عملیات ممکن است برخی کانکشنها دیگر متصل نشوند و یا لینک صفحه کاربران تغییر کند.
<br/>
پس با احتیاط این عمل را انجام دهید.

<div class="btn-group">
            <a href="update" class="btn btn-primary">به روز رسانی</a>
        </div>
</div>


<div class="card">
    <h5 class="card-header">
        لینک عمومی کاربران
    </h5>
    <div class="card-body">
        <p class="card-text">
        با اشتراک گذاشتن لینک زیر می‌توانید لینک عمومی پروکسی را به اشتراک بگذارید
        </p>
        % for domain in data["MAIN_DOMAIN"].split(";"): 
            <h5>دامنه {{domain}}<h5>
            
            % for i,user in enumerate(data["USER_SECRET"].split(";")): 
                <div class="btn-group">    
                    <a href="https://{{domain}}/{{data["BASE_PROXY_PATH"]}}/{{user}}/" class="btn btn-primary">صفحه عمومی کاربر {{i}}</a>
                </div>
            % end
        % end
    </div>
</div>

<div class="card">
    <h5 class="card-header">
        صفحه تنظیمات سیستم
    </h5>
    <div class="card-body">
        <p class="card-text">
        در این بخش می توانید تنظیمات سیستم را تغییر دهید.
        </p>
        <div class="btn-group">
            <a href="config" class="btn btn-primary">تنظیمات</a>
        </div>

        <div class="btn-group">
            <a href="apply_configs" class="btn btn-primary">اجرای مجدد</a>
        </div>

        <div class="btn-group">
            <a href="reinstall" class="btn btn-primary">نصب مجدد</a>
        </div>

        <div class="btn-group">
            <a href="update" class="btn btn-primary">به روز رسانی</a>
        </div>

        <div class="btn-group">
            <a href="log/" class="btn btn-primary">مشاهده لاگ ها</a>
        </div>
    </div>
</div>
<div class="card">
    <h5 class="card-header">
        گزارش وضعیت سرویس
    </h5>
    <div class="card-body">
        <div class="btn-group">
            <a href="status" class="btn btn-primary">مشاهده وضعیت سرویس ها</a>
        </div>

        <div class="btn-group">
            <a href="netdata/" class="btn btn-primary">مشاهده کامل وضعیت سرور CPU و رم و ...</a>
        </div>
        <iframe src="netdata/dash.html" style="width:100%;height:500px;">
        </iframe>
        <details>
        <summary>گزارش بر مبنای شهر موقتا غیر فعال است</summary>
        
        <p class="card-text">
            از طریق لینک زیر میتوانید وضعیت هر پروتکل در هر اوپراتور بر مبنای هر شهر را مشاهده نمایید.
        </p>
        <h6>گزارش بر مبنای اپراتور</h6>
        <div class="btn-group">
            <a href="stats/daily/asn/0/" class="btn btn-primary">امروز تا الان</a>
            <a href="stats/daily/asn/1/" class="btn btn-primary">دیروز</a>
            <a href="stats/daily/asn/0:6/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/asn/0:30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <h6>گزارش بر مبنای شهر</h6>
        <div class="btn-group">
            <a href="stats/daily/city/0/" class="btn btn-primary">امروز تا الان</a>
            <a href="stats/daily/city/1/" class="btn btn-primary">دیروز</a>
            <a href="stats/daily/city/0:6/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/city/0:30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <h6>گزارش بر مبنای پروتکل</h6>
        <div class="btn-group">
            <a href="stats/daily/proto/0/" class="btn btn-primary">امروز تا الان</a>
            <a href="stats/daily/proto/1/" class="btn btn-primary">دیروز</a>
            <a href="stats/daily/proto/0:6/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/proto/0:30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <div class="btn-group">
            <a href="stats/" class="btn btn-primary orig-link">جزییات</a>
        </div>
        </details>
    </div>
</div>


% include('tail')
