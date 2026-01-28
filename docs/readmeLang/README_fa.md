<div dir="rtl">

# پلاگین AIDA برای Claude Code

**AIDA** (Agent Integration & Development Architecture) - فریم‌ورک هماهنگی چند عامله برای Claude Code

[English](../../README.md) | [日本語](README_ja.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | فارسی | [العربية](README_ar.md)

## مرور کلی

AIDA هماهنگی چند عامله را برای پروژه‌های توسعه نرم‌افزار فراهم می‌کند:

- **تولید پروژه جدید**: تولید پروژه‌های کامل از توضیحات زبان طبیعی
- **بهبود پروژه موجود**: گسترش پروژه‌های موجود با ویژگی‌های جدید
- **نگهداری پروژه**: به‌روزرسانی وابستگی‌ها، ممیزی امنیتی، بهبود کیفیت
- **وارد کردن پروژه خارجی**: وارد کردن و تحلیل مخازن GitHub/GitLab

<p align="center">
  <img src="../pics/architecture.svg" alt="معماری AIDA" width="600">
</p>

## شروع سریع

### نصب

**نصب یک خطی (توصیه شده)**

```bash
curl -fsSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

**نصب دستی**

```bash
# کلون کردن مخزن
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# اجرای اسکریپت نصب
./scripts/install.sh
```

**تأیید نصب**

```bash
./scripts/test-aida.sh --quick
```

### استفاده پایه

```bash
# راه‌اندازی فضای کار AIDA
/aida:init

# تولید پروژه جدید
/aida:pipeline "ایجاد یک برنامه کلون توییتر"

# بهبود پروژه موجود
/aida:enhance /path/to/project "افزودن احراز هویت کاربر"

# بررسی وضعیت
/aida:status
```

## دستورات

### تولید پروژه (پروژه‌های جدید)

| دستور | توضیحات |
|-------|---------|
| `/aida:init` | راه‌اندازی ساختار دایرکتوری AIDA |
| `/aida:start <توضیحات>` | شروع خط لوله چند عامله جدید |
| `/aida:status` | نمایش وضعیت جلسه فعلی |
| `/aida:work` | اجرای وظایف فاز فعلی |
| `/aida:pipeline <توضیحات>` | اجرای خط لوله کاملاً خودکار |

### پشتیبانی پروژه موجود

| دستور | توضیحات |
|-------|---------|
| `/aida:analyze <مسیر>` | تحلیل ساختار پروژه، پشته فناوری، کیفیت |
| `/aida:import <مسیر\|URL>` | وارد کردن پروژه خارجی به مدیریت AIDA |
| `/aida:enhance <مسیر> [مشخصات]` | بهبود پروژه با سند یا زبان طبیعی |
| `/aida:maintain <مسیر> [گزینه‌ها]` | وظایف نگهداری (وابستگی‌ها، امنیت، کیفیت) |

### گزینه‌های نگهداری

```bash
# به‌روزرسانی وابستگی‌ها
/aida:maintain /path/to/project --update-deps

# ممیزی امنیتی
/aida:maintain /path/to/project --security

# بهبود کیفیت
/aida:maintain /path/to/project --improve

# رفع تست‌های ناموفق
/aida:maintain /path/to/project --fix-tests

# رسیدگی به Issue گیت‌هاب
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123
```

## معماری

### نقش‌های عامل

| عامل | نقش |
|------|-----|
| **Conductor** | هماهنگی کل خط لوله، هدایت Leaders |
| **Leader-Spec** | مدیریت فازهای مشخصات (نیازمندی‌ها، طراحی) |
| **Leader-Impl** | مدیریت فاز پیاده‌سازی (توسعه مبتنی بر TDD) |
| **Leader-Enhance** | مدیریت مشخصات بهبود برای پروژه‌های موجود |
| **Player** | کارگران متخصص (Backend، Frontend، Docker) |

## گردش کار ۵ فازی

<p align="center">
  <img src="../pics/workflow.svg" alt="گردش کار" width="700">
</p>

| فاز | نام | توضیحات |
|-----|-----|---------|
| ۱ | استخراج و معماری | استخراج نیازمندی‌ها، طراحی معماری |
| ۲ | ساختار و طرحواره | ساختار دایرکتوری، تعریف طرحواره داده |
| ۳ | هم‌ترازی | بررسی سازگاری نیازمندی‌ها |
| ۴ | تأیید | تأیید برنامه، شناسایی اصلاحات |
| ۵ | پیاده‌سازی | توسعه مبتنی بر TDD با دروازه‌های کیفیت |

## پشتیبانی زبان

AIDA به طور خودکار چندین زبان را شناسایی و پشتیبانی می‌کند:

| زبان | شناسایی | فریم‌ورک تست |
|------|---------|--------------|
| Go | `go.mod` | `go test` |
| TypeScript/JavaScript | `package.json` | Jest, Vitest |
| Python | `pyproject.toml`, `requirements.txt` | pytest |
| Rust | `Cargo.toml` | `cargo test` |
| Java | `pom.xml`, `build.gradle` | JUnit, Maven/Gradle |
| Ruby | `Gemfile` | RSpec |
| C# | `*.csproj` | dotnet test |
| PHP | `composer.json` | PHPUnit |

## دروازه‌های کیفیت

### دروازه‌های پروژه جدید (۱۰ دروازه)

| دروازه | نام | اعتبارسنجی |
|--------|-----|------------|
| ۱ | ساخت Backend | `go build ./...` |
| ۲ | تست‌های Backend | `go test ./...` |
| ۳ | ساخت Frontend | `npm run build` |
| ۴ | تست‌های Frontend | `npm test -- --run` |
| ۵ | ساخت Docker | `docker compose build` |
| ۶ | اجرای Docker | `docker compose up -d` |
| ۷ | بررسی سلامت | `curl localhost:8080/health` |
| ۸ | پوشش API | ۳+ فایل handler، ۱۰+ تابع |
| ۹ | پوشش Frontend | ۳+ صفحه، مسیریابی، کلاینت API |
| ۱۰ | یکپارچه‌سازی | کلاینت API، CORS، پیوندهای Docker |

## پروتکل TDD

<p align="center">
  <img src="../pics/tdd-cycle.svg" alt="چرخه TDD" width="300">
</p>

تمام پیاده‌سازی‌ها از TDD دقیق پیروی می‌کنند:

۱. **RED**: ابتدا تست ناموفق بنویسید
۲. **GREEN**: حداقل کد برای عبور از تست
۳. **REFACTOR**: پاکسازی در حالی که تست‌ها عبور می‌کنند

بدون تست کدی نیست. بدون اجرا تستی نیست.

## اسکریپت‌ها

| اسکریپت | توضیحات |
|---------|---------|
| `scripts/install.sh` | نصب یک کلیکی |
| `scripts/test-aida.sh` | خودآزمایی AIDA |
| `scripts/quality-gates.sh` | دروازه‌های کیفیت پروژه جدید |
| `scripts/enhance-quality-gates.sh` | دروازه‌های کیفیت بهبود |
| `scripts/analyze-project.sh` | تحلیل پروژه |
| `scripts/checkpoint.sh` | ذخیره/بازیابی وضعیت جلسه |

## محیط اجرای کانتینر

AIDA هر دو Docker و Podman را پشتیبانی می‌کند:

```bash
# شناسایی خودکار podman یا docker

# اجبار Podman
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
./scripts/quality-gates.sh myproject
```

## مجوز

MIT

## اعتبارات و قدردانی

### فناوری‌های هسته‌ای

| پروژه | نویسنده | نقش |
|-------|---------|-----|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | تولید نیازمندی‌ها |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | توسعه مبتنی بر مشخصات |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | فریم‌ورک TDD |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | هماهنگی چند عامله |

### زیرساخت

| پروژه | مجوز |
|-------|------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Redis](https://redis.io/) | BSD-3-Clause |
| [tmux](https://github.com/tmux/tmux) | ISC |
| [Podman](https://podman.io/) | Apache 2.0 |

### تشکر ویژه

- [Anthropic](https://www.anthropic.com/) - سازندگان Claude
- تمام مشارکت‌کنندگان و آزمایش‌کنندگانی که به بهبود این پروژه کمک کردند

## پیوندها

- [مخزن GitHub](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)

</div>
