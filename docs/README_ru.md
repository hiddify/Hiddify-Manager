<base target="_blank">

<div dir="ltr" align=center>

[**English 🇬🇧**](../README.md) / [**فارسی 🇮🇷**](README_fa.md) / [**简体中文 🇨🇳**](README_cn.md) &nbsp;&nbsp; [![](https://img.shields.io/badge/Tutorials-hiddify.com-808080?style=flat-square)](https://hiddify.com/manager/) [![](https://img.shields.io/badge/FAQ-Here-512DA8?style=flat-square&logo=Favro)](https://github.com/hiddify/hiddify-manager/discussions/categories/q-a-%D8%B3%D9%88%D8%A7%D9%84%D8%A7%D8%AA-%D8%B1%D8%A7%DB%8C%D8%AC) [![](https://img.shields.io/badge/Report-Bugs-F67909?style=flat-square&logo=Open-Bug-Bounty)](https://github.com/hiddify/hiddify-manager/issues)

</div>
<br>

<div align=center>

<img src="https://raw.githubusercontent.com/hiddify/hiddify.com/main/docs/assets/hiddify-manager-logo.svg" width=60% alt="Hiddify Manager" />

</div>
<br>

<div align=center>

[![Downloads](https://static.pepy.tech/badge/hiddifypanel?style=flat-square)](https://www.pepy.tech/projects/hiddifypanel) [![Last Version](https://img.shields.io/github/release/hiddify/hiddify-manager/all.svg?style=flat-square)](https://github.com/hiddify/hiddify-manager/releases) [![Last Release Date](https://img.shields.io/github/release-date/hiddify/hiddify-manager.svg?style=flat-square)](https://github.com/hiddify/hiddify-manager/releases) [![commits](https://img.shields.io/github/commit-activity/m/hiddify/hiddify-manager?style=flat-square)](https://github.com/hiddify/hiddify-manager/commits/) [![YouTube](https://img.shields.io/badge/YouTube-@hiddify-FF0000?style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify) [![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify) [![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board/5) [![Gurubase](https://img.shields.io/badge/Gurubase-Ask%20Hiddify--Manager%20Guru-006BFF?style=flat-square)](https://gurubase.io/g/hiddify-manager)

</div>

<div dir="ltr" markdown="1">

## Добро пожаловать в Hiddify Manager

Hiddify Manager — это бесплатная панель с открытым исходным кодом для обхода цензуры, которую вы устанавливаете на свой собственный сервер. Она запускает многопользовательский VPN- и прокси-сервер с **более чем 20 протоколами**, включая **Reality** и **Telegram-прокси**, и даёт вам современную веб-панель для управления пользователями, доменами и настройками. Панель оптимизирована для работы в условиях жёсткой фильтрации в **Иране, Китае и России** и указана в списке панелей [Xray](https://github.com/XTLS/Xray-core#installation).

<div align=center>
<img alt="Hiddify Manager panel" width=90% src="demo-en.webp">
</div>

### Содержание

- [Быстрая установка](#быстрая-установка)
- [Почему Hiddify Manager?](#почему-hiddify-manager)
  - [Основные возможности](#основные-возможности)
  - [Поддерживаемые протоколы](#поддерживаемые-протоколы)
- [Установка и руководства](#установка-и-руководства)
- [Благодарности](#благодарности)
- [Пожертвования и поддержка](#пожертвования-и-поддержка)
- [Сотрудничество и контакты](#сотрудничество-и-контакты)

## Быстрая установка

Вам понадобится сервер (VPS) с **Ubuntu 22.04, 24.04 или 26.04** (amd64 или arm64), не менее **1 ГБ оперативной памяти, 1 ядром процессора и 10 ГБ дискового пространства**. Подключитесь к серверу по SSH и выполните:

```bash
bash <(curl https://i.hiddify.com/release)
```

В конце установщик покажет ссылку на панель администратора. Откройте её, пройдите быструю настройку и добавьте первого пользователя. В [руководстве по установке](https://hiddify.com/manager/installation-and-setup/guide/) подробно описан каждый шаг; есть также руководства по установке в один клик для [Hetzner](https://hiddify.com/manager/installation-and-setup/Quick-installation-on-Hetzner-Servers/), [Oracle Cloud](https://hiddify.com/manager/installation-and-setup/Quick-Installation-on-Oracle-Cloud/), [Azure](https://hiddify.com/manager/installation-and-setup/Quick-Installation-on-Microsoft-Azure/) и [cloud-init](https://hiddify.com/manager/installation-and-setup/Cloud-init-installation/).

Для подключения с телефонов и компьютеров мы рекомендуем [приложение Hiddify](https://github.com/hiddify/hiddify-app).

## Почему Hiddify Manager?

Название *Hiddify* образовано от слов **hidden** (скрытый) и **simplify** (упрощать): наша цель — сервер, который трудно обнаружить и легко обслуживать.

### Основные возможности

- 🖥 **Современная панель администратора (Admin V2)** на 28 языках, со светлой и тёмной темами, удобная и на телефоне.
- ⚡ **Быстрая установка** и пошаговая первоначальная настройка; **автоматические обновления** и **автоматическое резервное копирование** (копии также приходят вам в Telegram).
- 🧠 Ядра **Xray и sing-box** вместе, с **умной маршрутизацией**, при которой местные сайты открываются без прокси.
- 🌐 **Любые типы доменов:** прямые, CDN (Cloudflare и другие), relay, домены только для подписки, Reality, fake и wildcard-домены; автоматическое получение сертификатов.
- 👥 **Управление пользователями:** ограничения по трафику и сроку для каждого пользователя, продление, теги и **три роли администраторов** (суперадминистратор, администратор, агент) с индивидуальными ограничениями.
- 📱 **Личная страница** для каждого пользователя: расход трафика, конфигурации, QR-коды и импорт в один клик в приложение Hiddify и другие клиенты.
- 🤖 **Telegram-бот** для вас и ваших пользователей: создание пользователей и управление ими, состояние сервера, бесплатные тестовые аккаунты, напоминания и сообщения в поддержку.
- ✈️ **Telegram-прокси** (MTProxy FakeTLS) и **веб-прокси Telegram через Cloudflare**.
- 🛰 **Несколько серверов:** подключайте несколько серверов (узлов) к одной родительской панели.
- 🧰 **Инструменты:** проверка конфигураций, сканер чистых IP, сканер доменов для Reality, WARP, файрвол, DNS через HTTPS, пользовательские исходящие подключения (outbounds) и шаблоны конфигураций.

### Поддерживаемые протоколы

**VLESS, VMess, Trojan, Reality, Shadowsocks (2022, ShadowTLS), Hysteria2, TUIC, WireGuard, AnyTLS, Snell, Naive, Mieru, SSH, xHTTP, gRPC, WebSocket, HTTPUpgrade,** DNS-туннели (**VayDNS, Slipstream, MasterDnsVPN**) и **Telegram proxy** — через прямые, CDN- и relay-домены.

## Установка и руководства

Все руководства с картинками и видео есть на нашем сайте:

- [Руководство по установке](https://hiddify.com/manager/installation-and-setup/guide/)
- [Как правильно настроить панель](https://hiddify.com/manager/configuration-and-advanced-settings/How-to-configure-Hiddify-panel-properly/)
- [Домены, CDN и Cloudflare](https://hiddify.com/manager/domain-worker-cdn-and-tunneling/How-to-use-Cloudflare-CDN/)
- [Все руководства и видео по Hiddify Manager](https://hiddify.com/manager/)

<div align="center">
 <a href="https://hiddify.com/manager/"><img width="100%" alt="hiddify.com" src="tutorials-ru.webp" /></a>
</div>

## Благодарности

Мы искренне благодарим участников этих проектов: их надёжная основа и возможности сделали этот проект возможным:

- [sing-box](https://github.com/SagerNet/sing-box)
- [Xray](https://github.com/XTLS/Xray-core)
- [Linux от Линуса Торвальдса](https://github.com/torvalds/linux)
- Шрифт: [Vazirmatn от Сабера Растикердара](https://github.com/rastikerdar/vazirmatn)

## Пожертвования и поддержка

Самый простой способ поддержать нас — поставить этому репозиторию звёздочку (⭐) вверху страницы.

<div align=center>
<a href="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history?repo_id=541755332" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=541755332&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Star History of hiddify/Hiddify-Manager" src="https://next.ossinsight.io/widgets/official/analyze-repo-stars-history/thumbnail.png?repo_id=541755332&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>
</div>

Нам также нужна финансовая поддержка для работы наших сервисов. Вся наша работа ведётся на добровольных началах, и каждое пожертвование идёт на развитие проекта. Подробнее — на нашей [странице пожертвований](https://hiddify.com/donation-and-support/).

## Сотрудничество и контакты

Hiddify — проект, который развивает сообщество, и нам нужна ваша помощь. Если вы разбираетесь в одной из этих областей, свяжитесь с нами и расскажите о своих навыках:

- Разработка на Python
- Разработка на Vue / TypeScript
- Разработка на Go
- Создание медиаконтента

<div align=center>
<br>

[![Email](https://img.shields.io/badge/Email-contribute@hiddify.com-005FF9?style=flat-square&logo=gmail)](mailto:contribute@hiddify.com)
[![Telegram Channel](https://img.shields.io/endpoint?label=Channel&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify&color=blue)](https://telegram.dog/hiddify)
[![Telegram Group](https://img.shields.io/endpoint?color=neon&label=Support%20Group&style=flat-square&url=https%3A%2F%2Ftg.sumanjay.workers.dev%2Fhiddify_board)](https://telegram.dog/hiddify_board)
[![YouTube](https://img.shields.io/badge/YouTube-@hiddify-FF0000?style=flat-square&logo=youtube)](https://www.youtube.com/@hiddify)
[![X](https://img.shields.io/twitter/follow/hiddify_com?color=%231DA1F2&logo=x&logoColor=white&style=flat-square)](https://twitter.com/intent/follow?screen_name=hiddify_com)

</div>

<p align=center>
Мы благодарим всех, кто участвует в этом проекте, — здесь, на GitHub, и многих других за его пределами. Это очень много для нас значит. ♥
</p>

<p align=center>
<a href="https://github.com/hiddify/hiddify-manager/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=hiddify/hiddify-manager" alt="Contributors" />
</a>
</p>
<p align=center>
Сделано с помощью <a target="_blank" href="https://contrib.rocks">Contrib.Rocks</a>
</p>

</div>
