# Плагин AIDA для Claude Code

**AIDA** (Agent Integration & Development Architecture) - Фреймворк мультиагентной оркестрации для Claude Code

[English](../../README.md) | [日本語](README_ja.md) | [简体中文](README_zh-CN.md) | [繁體中文](README_zh-TW.md) | Русский | [فارسی](README_fa.md) | [العربية](README_ar.md)

## Обзор

AIDA обеспечивает мультиагентную оркестрацию для проектов разработки программного обеспечения:

- **Генерация новых проектов**: Создание полных проектов из описания на естественном языке
- **Расширение существующих проектов**: Добавление новых функций в существующие проекты
- **Обслуживание проектов**: Обновление зависимостей, аудит безопасности, улучшение качества
- **Импорт внешних проектов**: Импорт и анализ репозиториев GitHub/GitLab

<p align="center">
  <img src="../pics/architecture.svg" alt="Архитектура AIDA" width="600">
</p>

## Быстрый старт

### Установка

**Установка одной командой (рекомендуется)**

```bash
curl -fsSL https://raw.githubusercontent.com/clearclown/claude-code-aida/main/scripts/install.sh | bash
```

**Ручная установка**

```bash
# Клонирование репозитория
git clone https://github.com/clearclown/claude-code-aida.git
cd claude-code-aida

# Запуск скрипта установки
./scripts/install.sh
```

**Проверка установки**

```bash
./scripts/test-aida.sh --quick
```

### Основное использование

```bash
# Инициализация рабочего пространства AIDA
/aida:init

# Генерация нового проекта
/aida:pipeline "Создать клон Twitter"

# Расширение существующего проекта
/aida:enhance /path/to/project "Добавить аутентификацию пользователей"

# Проверка статуса
/aida:status
```

## Команды

### Генерация проектов (новые проекты)

| Команда | Описание |
|---------|----------|
| `/aida:init` | Инициализация структуры каталогов AIDA |
| `/aida:start <описание>` | Запуск нового мультиагентного конвейера |
| `/aida:status` | Показать текущий статус сессии |
| `/aida:work` | Выполнить задачи текущей фазы |
| `/aida:pipeline <описание>` | Запустить полностью автоматический конвейер |

### Поддержка существующих проектов

| Команда | Описание |
|---------|----------|
| `/aida:analyze <путь>` | Анализ структуры проекта, технологического стека, качества |
| `/aida:import <путь\|URL>` | Импорт внешнего проекта в управление AIDA |
| `/aida:enhance <путь> [спец]` | Расширение проекта с помощью документа или естественного языка |
| `/aida:maintain <путь> [опции]` | Задачи обслуживания (зависимости, безопасность, качество) |

### Опции обслуживания

```bash
# Обновление зависимостей
/aida:maintain /path/to/project --update-deps

# Аудит безопасности
/aida:maintain /path/to/project --security

# Улучшение качества
/aida:maintain /path/to/project --improve

# Исправление неудачных тестов
/aida:maintain /path/to/project --fix-tests

# Обработка GitHub Issue
/aida:maintain /path/to/project --issue https://github.com/org/repo/issues/123
```

## Архитектура

### Роли агентов

| Агент | Роль |
|-------|------|
| **Conductor** | Оркестрация всего конвейера, управление Leaders |
| **Leader-Spec** | Обработка фаз спецификации (требования, дизайн) |
| **Leader-Impl** | Обработка фазы реализации (разработка на основе TDD) |
| **Leader-Enhance** | Обработка спецификаций расширения для существующих проектов |
| **Player** | Специализированные работники (Backend, Frontend, Docker) |

## 5-фазный рабочий процесс

<p align="center">
  <img src="../pics/workflow.svg" alt="Рабочий процесс" width="700">
</p>

| Фаза | Название | Описание |
|------|----------|----------|
| 1 | Извлечение и архитектура | Извлечение требований, проектирование архитектуры |
| 2 | Структура и схема | Структура каталогов, определение схемы данных |
| 3 | Согласование | Проверка согласованности требований |
| 4 | Верификация | Проверка плана, выявление ревизий |
| 5 | Реализация | Разработка на основе TDD с контролем качества |

## Поддержка языков

AIDA автоматически определяет и поддерживает несколько языков:

| Язык | Обнаружение | Фреймворк тестирования |
|------|-------------|------------------------|
| Go | `go.mod` | `go test` |
| TypeScript/JavaScript | `package.json` | Jest, Vitest |
| Python | `pyproject.toml`, `requirements.txt` | pytest |
| Rust | `Cargo.toml` | `cargo test` |
| Java | `pom.xml`, `build.gradle` | JUnit, Maven/Gradle |
| Ruby | `Gemfile` | RSpec |
| C# | `*.csproj` | dotnet test |
| PHP | `composer.json` | PHPUnit |

## Контрольные точки качества

### Контрольные точки для новых проектов (10 точек)

| Точка | Название | Проверка |
|-------|----------|----------|
| 1 | Сборка Backend | `go build ./...` |
| 2 | Тесты Backend | `go test ./...` |
| 3 | Сборка Frontend | `npm run build` |
| 4 | Тесты Frontend | `npm test -- --run` |
| 5 | Сборка Docker | `docker compose build` |
| 6 | Запуск Docker | `docker compose up -d` |
| 7 | Проверка здоровья | `curl localhost:8080/health` |
| 8 | Покрытие API | 3+ файлов обработчиков, 10+ функций |
| 9 | Покрытие Frontend | 3+ страниц, маршрутизация, API клиент |
| 10 | Интеграция | API клиент, CORS, связи Docker |

## Протокол TDD

<p align="center">
  <img src="../pics/tdd-cycle.svg" alt="Цикл TDD" width="300">
</p>

Вся реализация следует строгому TDD:

1. **RED**: Сначала напишите неудачный тест
2. **GREEN**: Минимальный код для прохождения теста
3. **REFACTOR**: Очистка при прохождении тестов

Нет кода без тестов. Нет тестов без их запуска.

## Скрипты

| Скрипт | Описание |
|--------|----------|
| `scripts/install.sh` | Установка одним кликом |
| `scripts/test-aida.sh` | Самотестирование AIDA |
| `scripts/quality-gates.sh` | Контрольные точки для новых проектов |
| `scripts/enhance-quality-gates.sh` | Контрольные точки расширения |
| `scripts/analyze-project.sh` | Анализ проекта |
| `scripts/checkpoint.sh` | Сохранение/восстановление состояния сессии |

## Среда выполнения контейнеров

AIDA поддерживает как Docker, так и Podman:

```bash
# Автоматическое определение podman или docker

# Принудительное использование Podman
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
./scripts/quality-gates.sh myproject
```

## Лицензия

MIT

## Благодарности и признание

### Основные технологии

| Проект | Автор | Роль |
|--------|-------|------|
| [zoltraak](https://github.com/dai-motoki/zoltraak) | [@dai-motoki](https://github.com/dai-motoki) | Генерация требований |
| [cc-sdd](https://github.com/gotalab/cc-sdd) | [@gotalab](https://github.com/gotalab) | Разработка на основе спецификаций |
| [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) | [@Chachamaru127](https://github.com/Chachamaru127) | Фреймворк TDD |
| orchestrobot (aida-cli) | [@kent8192](https://github.com/kent8192) | Мультиагентная оркестрация |

### Инфраструктура

| Проект | Лицензия |
|--------|----------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic |
| [Redis](https://redis.io/) | BSD-3-Clause |
| [tmux](https://github.com/tmux/tmux) | ISC |
| [Podman](https://podman.io/) | Apache 2.0 |

### Особая благодарность

- [Anthropic](https://www.anthropic.com/) - Создатели Claude
- Всем участникам и тестировщикам, которые помогли улучшить этот проект

## Ссылки

- [Репозиторий GitHub](https://github.com/clearclown/claude-code-aida)
- [Issues](https://github.com/clearclown/claude-code-aida/issues)
