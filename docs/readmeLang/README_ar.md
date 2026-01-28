<div dir="rtl">

# إضافة AIDA لـ Claude Code

**AIDA** (Agent Integration & Development Architecture) - إطار تنسيق الوكلاء المتعددين لـ Claude Code

[English](../../README.md) | [日本語](README_ja.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | [Русский](README_ru.md) | [فارسی](README_fa.md) | العربية

## نظرة عامة

يوفر AIDA تنسيق الوكلاء المتعددين لمشاريع تطوير البرمجيات:

- **توليد مشاريع جديدة**: إنشاء مشاريع كاملة من وصف اللغة الطبيعية
- **تحسين المشاريع الموجودة**: توسيع المشاريع الموجودة بميزات جديدة
- **صيانة المشاريع**: تحديث التبعيات، تدقيق الأمان، تحسين الجودة
- **استيراد المشاريع الخارجية**: استيراد وتحليل مستودعات GitHub/GitLab

<p align="center">
  <img src="../pics/architecture.svg" alt="بنية AIDA" width="600">
</p>

## البدء السريع

### التثبيت

**التثبيت بسطر واحد (موصى به)**

```bash
curl -fsSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

**التثبيت اليدوي**

```bash
# استنساخ المستودع
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# تشغيل سكريبت التثبيت
./scripts/install.sh
```

**التحقق من التثبيت**

```bash
./scripts/test-aida.sh --quick
```

### الاستخدام الأساسي

```bash
# تهيئة مساحة عمل AIDA
/aida:init

# توليد مشروع جديد
/aida:pipeline "إنشاء نسخة من تويتر"

# تحسين مشروع موجود
/aida:enhance /path/to/project "إضافة مصادقة المستخدم"

# التحقق من الحالة
/aida:status
```

## الأوامر

### توليد المشاريع (مشاريع جديدة)

| الأمر | الوصف |
|-------|-------|
| `/aida:init` | تهيئة هيكل دليل AIDA |
| `/aida:start <وصف>` | بدء خط أنابيب الوكلاء المتعددين |
| `/aida:status` | عرض حالة الجلسة الحالية |
| `/aida:work` | تنفيذ مهام المرحلة الحالية |
| `/aida:pipeline <وصف>` | تشغيل خط أنابيب آلي كامل |

### دعم المشاريع الموجودة

| الأمر | الوصف |
|-------|-------|
| `/aida:analyze <مسار>` | تحليل هيكل المشروع، المكدس التقني، الجودة |
| `/aida:import <مسار\|URL>` | استيراد مشروع خارجي إلى إدارة AIDA |
| `/aida:enhance <مسار> [مواصفات]` | تحسين المشروع بوثيقة أو لغة طبيعية |
| `/aida:maintain <مسار> [خيارات]` | مهام الصيانة (التبعيات، الأمان، الجودة) |

### خيارات الصيانة

```bash
# تحديث التبعيات
/aida:maintain /path/to/project --update-deps

# تدقيق الأمان
/aida:maintain /path/to/project --security

# تحسين الجودة
/aida:maintain /path/to/project --improve

# إصلاح الاختبارات الفاشلة
/aida:maintain /path/to/project --fix-tests

# معالجة GitHub Issue
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123
```

## البنية

### أدوار الوكلاء

| الوكيل | الدور |
|--------|-------|
| **Conductor** | تنسيق خط الأنابيب بالكامل، توجيه القادة |
| **Leader-Spec** | معالجة مراحل المواصفات (المتطلبات، التصميم) |
| **Leader-Impl** | معالجة مرحلة التنفيذ (التطوير المبني على TDD) |
| **Leader-Enhance** | معالجة مواصفات التحسين للمشاريع الموجودة |
| **Player** | عمال متخصصون (Backend، Frontend، Docker) |

## سير العمل من ٥ مراحل

<p align="center">
  <img src="../pics/workflow.svg" alt="سير العمل" width="700">
</p>

| المرحلة | الاسم | الوصف |
|---------|-------|-------|
| ١ | الاستخراج والبنية | استخراج المتطلبات، تصميم البنية |
| ٢ | الهيكل والمخطط | هيكل الدليل، تعريف مخطط البيانات |
| ٣ | المحاذاة | التحقق من اتساق المتطلبات |
| ٤ | التحقق | التحقق من الخطة، تحديد المراجعات |
| ٥ | التنفيذ | التطوير المبني على TDD مع بوابات الجودة |

## دعم اللغات

يكتشف AIDA تلقائياً ويدعم لغات متعددة:

| اللغة | الكشف | إطار الاختبار |
|-------|-------|---------------|
| Go | `go.mod` | `go test` |
| TypeScript/JavaScript | `package.json` | Jest, Vitest |
| Python | `pyproject.toml`, `requirements.txt` | pytest |
| Rust | `Cargo.toml` | `cargo test` |
| Java | `pom.xml`, `build.gradle` | JUnit, Maven/Gradle |
| Ruby | `Gemfile` | RSpec |
| C# | `*.csproj` | dotnet test |
| PHP | `composer.json` | PHPUnit |

## بوابات الجودة

### بوابات المشاريع الجديدة (١٠ بوابات)

| البوابة | الاسم | التحقق |
|---------|-------|--------|
| ١ | بناء Backend | `go build ./...` |
| ٢ | اختبارات Backend | `go test ./...` |
| ٣ | بناء Frontend | `npm run build` |
| ٤ | اختبارات Frontend | `npm test -- --run` |
| ٥ | بناء Docker | `docker compose build` |
| ٦ | تشغيل Docker | `docker compose up -d` |
| ٧ | فحص الصحة | `curl localhost:8080/health` |
| ٨ | تغطية API | ٣+ ملفات معالج، ١٠+ دوال |
| ٩ | تغطية Frontend | ٣+ صفحات، التوجيه، عميل API |
| ١٠ | التكامل | عميل API، CORS، روابط Docker |

## بروتوكول TDD

<p align="center">
  <img src="../pics/tdd-cycle.svg" alt="دورة TDD" width="300">
</p>

يتبع كل التنفيذ TDD صارم:

١. **RED**: اكتب اختباراً فاشلاً أولاً
٢. **GREEN**: أقل كود لاجتياز الاختبار
٣. **REFACTOR**: التنظيف أثناء اجتياز الاختبارات

لا كود بدون اختبارات. لا اختبارات بدون تشغيلها.

## السكريبتات

| السكريبت | الوصف |
|----------|-------|
| `scripts/install.sh` | التثبيت بنقرة واحدة |
| `scripts/test-aida.sh` | الاختبار الذاتي لـ AIDA |
| `scripts/quality-gates.sh` | بوابات جودة المشاريع الجديدة |
| `scripts/enhance-quality-gates.sh` | بوابات جودة التحسين |
| `scripts/analyze-project.sh` | تحليل المشروع |
| `scripts/checkpoint.sh` | حفظ/استعادة حالة الجلسة |

## بيئة تشغيل الحاويات

يدعم AIDA كلاً من Docker و Podman:

```bash
# الكشف التلقائي عن podman أو docker

# فرض Podman
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
./scripts/quality-gates.sh myproject
```

## الترخيص

MIT

## شكر وتقدير

### التقنيات الأساسية

| المشروع | المؤلف | الدور |
|---------|--------|-------|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | توليد المتطلبات |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | التطوير المبني على المواصفات |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | إطار TDD |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | تنسيق الوكلاء المتعددين |

### البنية التحتية

| المشروع | الترخيص |
|---------|---------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Redis](https://redis.io/) | BSD-3-Clause |
| [tmux](https://github.com/tmux/tmux) | ISC |
| [Podman](https://podman.io/) | Apache 2.0 |

### شكر خاص

- [Anthropic](https://www.anthropic.com/) - منشئو Claude
- جميع المساهمين والمختبرين الذين ساعدوا في تحسين هذا المشروع

## الروابط

- [مستودع GitHub](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)

</div>
