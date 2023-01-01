% include('head')


<div class="card">
    <h5 class="card-header">
        لینک عمومی کاربران
    </h5>
    <div class="card-body">
        <p class="card-text">
        با اشتراک گذاشتن لینک زیر می‌توانید لینک عمومی پروکسی را به اشتراک بگذارید
        </p>
        <div class="btn-group">
            <a href="https://{{data["MAIN_DOMAIN"]}}/{{data["USER_SECRET"]}}/" class="btn btn-primary">صفحه عمومی کاربران</a>
        </div>
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
    </div>
</div>


% include('tail')
