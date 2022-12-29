% include('head')

<div class="btn-group">
    <a href="config/" class="btn btn-primary">تنظیمات سیستم</a>
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
            <a href="stats/daily/asn/7/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/asn/30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <h6>گزارش بر مبنای شهر</h6>
        <div class="btn-group">
            <a href="stats/daily/city/0/" class="btn btn-primary">امروز تا الان</a>
            <a href="stats/daily/city/1/" class="btn btn-primary">دیروز</a>
            <a href="stats/daily/city/7/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/city/30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <h6>گزارش بر مبنای پروتکل</h6>
        <div class="btn-group">
            <a href="stats/daily/proto/0/" class="btn btn-primary">امروز تا الان</a>
            <a href="stats/daily/proto/1/" class="btn btn-primary">دیروز</a>
            <a href="stats/daily/proto/7/" class="btn btn-primary">هفتگی</a>
            <a href="stats/daily/proto/30/" class="btn btn-primary">ماهیانه</a>
        </div>
        <div class="btn-group">
            <a href="stats/" class="btn btn-primary orig-link">جزییات</a>
        </div>
    </div>
</div>


% include('tail')