# Infernus Presence Website

Веб-приложение для музыкальной группы Infernus Presence с административной панелью управления контентом и системой подписки на новости.

## Описание проекта

Это полнофункциональное веб-приложение, состоящее из двух основных компонентов:

1. **Frontend** — публичный вебсайт группы, отображающий актуальную информацию и позволяющий посетителям подписаться на новости
2. **Backend** — REST API и административная панель для управления информацией о группе и просмотра подписчиков

## Быстрый старт

### Требования

- Docker 20.10+
- Docker Compose 1.29+

### Подготовка окружения

1. **Добавь запись в `/etc/hosts`** (Linux/macOS) или `C:\Windows\System32\drivers\etc\hosts` (Windows):
   ```
   127.0.0.1  infernus-presence.local
   ```

2. **Создай конфигурацию окружения:**
   ```bash
   # Создай .env в backend/app на основе примера
   cp backend/app/.env.example backend/app/.env
   ```

3. **Запусти все сервисы:**
   ```bash
   docker compose up -d
   # или используй Makefile:
   make up
   ```

4. **Установи зависимости:**
   ```bash
   # Backend: установка PHP зависимостей (выполнить один раз)
   docker compose exec backend composer install
   
   # Frontend: установка Node.js зависимостей (выполнить один раз)
   docker compose exec frontend npm install
   
   # или через Makefile:
   make install
   ```
   
   > **Примечание:** Оба контейнера запустятся и будут готовы к работе даже без предварительного выполнения установки зависимостей. Зависимости можно установить в любой момент после запуска контейнера.

5. **Доступ к приложению:**
   - **Frontend (сайт):** http://infernus-presence.local
   - **Backend API:** http://infernus-presence.local/api
   - **Админ-панель:** http://infernus-presence.local/admin

### Основные команды

```bash
# Управление сервисами
make up              # Запустить все сервисы
make down            # Остановить все сервисы
make restart         # Перезагрузить сервисы
make logs            # Показать логи

# Разработка
make shell-backend   # Открыть shell backend контейнера
make shell-frontend  # Открыть shell frontend контейнера
make test            # Запустить тесты
make lint            # Запустить linters
make format          # Форматировать код

# Полный список команд:
make help
```

## Архитектура и стек технологий

### Docker Compose услуги

Проект использует Docker Compose для оркестрации четырех основных сервисов:

#### 1. Backend (PHP-FPM 8.4 + Symfony 8)
- **Образ**: PHP 8.4-FPM Alpine
- **Внутренний порт**: 9000 (доступен через nginx)
- **Зависимости**: БД (database должен быть в статусе healthy)
- **Ключевые компоненты:**
  - Symfony 8 фреймворк для REST API
  - Doctrine ORM для работы с БД
  - OPcache для оптимизации производительности
  - Расширения: GD, PDO MySQL, Intl
- **Health Check**: Проверка доступности через curl на `/ping`
- **Код приложения**: Пробрасывается через volume — контейнер всегда работает с актуальным кодом
- **Composer зависимости**: Устанавливаются внутри контейнера через `docker compose exec backend composer install`

**Что находится в контейнере:**
- REST API для получения информации о группе и приема подписок
- Административная панель для управления контентом
- Система аутентификации для защиты админпанели
- Валидация и обработка данных

**Архитектура разработки:**
- Весь код источника пробрасывается через volume `./backend:/app`
- Директория `vendor` создается в контейнере при выполнении `composer install`
- Изменения кода в реальном времени отражаются в контейнере без перезагрузки
- Файлы `composer.json` и `composer.lock` пробрасываются вместе с кодом

#### 2. Database (MariaDB 12)
- **Образ**: MariaDB 12 Alpine
- **Порт**: 3306
- **Особенности:**
  - InnoDB storage engine
  - UTF-8MB4 для поддержки Unicode
  - Готовность к репликации

**Управление БД:**
```bash
# Бэкап БД
docker compose exec database mariadb-dump -u root -p infernus_db > backup.sql

# Восстановление из бэкапа
docker compose exec -T database mariadb -u root -p < backup.sql

# Доступ к БД
docker compose exec database mariadb -u infernus_user -p
```

#### 3. Frontend (Node.js 18 + Nuxt 4 + Vue 3)
- **Образ**: Node.js 18 Alpine
- **Порт**: 3000 (для разработки с Hot Module Reload)
- **Ключевые компоненты:**
  - Nuxt 4 для SSR и статической генерации
  - Vue 3 для компонентов
  - HMR для быстрой разработки
- **Код приложения**: Пробрасывается через volume — контейнер всегда работает с актуальным кодом
- **npm зависимости**: Устанавливаются внутри контейнера через `docker compose exec frontend npm install`

**Что находится в контейнере:**
- Компоненты Vue и маршруты Nuxt
- Скомпилированный код и метафайлы
- Интеграция с backend API
- Поддержка HMR для быстрой разработки

**Архитектура разработки:**
- Весь код источника пробрасывается через volume `./frontend:/app`
- Директория `node_modules` создается в контейнере при выполнении `npm install`
- Изменения кода в реальном времени отражаются в контейнере с HMR без перезагрузки
- Файлы `package.json` и `package-lock.json` пробрасываются вместе с кодом

**Команды разработки:**
```bash
# Установить зависимости (выполнить один раз после запуска контейнера)
docker compose exec frontend npm install

# Собрать для разработки и запустить dev сервер (с HMR)
docker compose exec frontend npm run build
docker compose exec frontend npm run dev

# Собрать для production
docker compose exec frontend npm run build

# Preview production build
docker compose exec frontend npm run preview
```

#### 4. nginx (Reverse Proxy)
- **Образ**: nginx Alpine
- **Порты**: 80 (HTTP), 443 (HTTPS)
- **Зависимости**: backend и frontend должны быть запущены
- **Функции:**
  - Маршрутизация запросов к backend и frontend
  - Rate limiting для API
  - Gzip сжатие
  - Безопасность заголовков
  - Кэширование статических файлов
  - WebSocket поддержка
- **Health Check**: Проверка доступности через wget на `/health`
- **Логирование**: Сохранение логов в volume `nginx_logs`

**Маршруты:**
- `/api/*` → Symfony backend
- `/admin/*` → Админ-панель (backend)
- `/public/*` → Статические файлы (30 дней кэша)
- `/*` → Nuxt frontend

### Backend
- **Язык**: PHP 8.4 — современная версия с улучшенной типизацией и производительностью
- **Фреймворк**: Symfony 8 — надежный, масштабируемый фреймворк с рядом встроенных инструментов
- **База данных**: MariaDB 12 — открытая реляционная БД, совместимая с MySQL
- **Архитектура**: Code-sharing через Docker volume для разработки в реальном времени

**Компоненты backend'а:**
- REST API для получения информации о группе и приема email-адресов подписчиков
- Административная панель (веб-интерфейс) для управления контентом
- Система аутентификации для защиты админпанели
- Валидация и обработка данных на уровне приложения

**Модель разработки:**
- Весь исходный код находится на хост-машине и пробрасывается в контейнер через volume
- Это обеспечивает актуальность кода без необходимости пересборки образа
- Удобство разработки: код редактируется локально с любимым IDE/редактором
- При запуске контейнера не требуется наличие `composer.json` и `composer.lock` в образе

### Frontend

- **Язык**: JavaScript/TypeScript — современный язык для веб-разработки
- **Фреймворк**: Vue 3 — прогрессивный JavaScript фреймворк для интерактивного пользовательского интерфейса
- **Meta-фреймворк**: Nuxt 4 — полнофункциональный фреймворк на базе Vue с поддержкой SSR, статической генерации и встроенной оптимизацией
- **Архитектура**: Code-sharing через Docker volume для разработки в реальном времени

**Компоненты frontend'а:**
- Главная страница с информацией о группе (фото, лого, описание)
- Форма подписки на новости с валидацией email
- Интеграция с backend API через HTTP-запросы
- Адаптивный дизайн для мобильных и десктопных устройств

**Модель разработки:**
- Весь исходный код находится на хост-машине и пробрасывается в контейнер через volume
- Это обеспечивает актуальность кода без необходимости пересборки образа
- Удобство разработки: код редактируется локально с любимым IDE/редактором
- При запуске контейнера не требуется наличие `package.json` и `package-lock.json` в образе
- Команды `npm install` и `npm run build` выполняются вручную перед запуском dev сервера

## Структура проекта

```
infernus-presence-website/
├── backend/                      # Контейнер backend (PHP 8.4 + Symfony 8)
│   ├── app/                      # Symfony приложение
│   │   ├── src/
│   │   │   ├── Controller/       # API контроллеры и админпанель
│   │   │   ├── Entity/           # Doctrine сущности (Band, Subscriber)
│   │   │   ├── Repository/       # Репозитории для работы с БД
│   │   │   ├── Service/          # Бизнес-логика
│   │   │   ├── Form/             # Формы для админпанели
│   │   │   └── Kernel.php
│   │   ├── templates/            # Шаблоны Twig для админпанели
│   │   ├── migrations/           # Doctrine миграции базы данных
│   │   ├── tests/                # Юнит и интеграционные тесты
│   │   ├── config/               # Конфигурация Symfony
│   │   ├── vendor/               # PHP зависимости (создается в контейнере)
│   │   ├── public/               # Веб-корень (index.php)
│   │   ├── .env                  # Переменные окружения (создается из .env.example)
│   │   ├── .env.example          # Пример переменных окружения
│   │   ├── composer.json         # PHP зависимости
│   │   ├── composer.lock         # Lock файл зависимостей
│   │   └── phpunit.dist.xml      # Конфигурация PHPUnit
│   ├── docker/                   # Dockerfile и конфиги для контейнера
│   │   ├── Dockerfile
│   │   ├── php.ini
│   │   └── www.conf
│   └── ...
│
├── frontend/                     # Frontend приложение (Nuxt 4 + Vue 3)
│   ├── app.vue                   # Корневой компонент
│   ├── pages/                    # Маршруты
│   │   └── index.vue             # Главная страница
│   ├── components/               # Переиспользуемые Vue компоненты
│   │   ├── BandInfo.vue
│   │   ├── SubscriptionForm.vue
│   │   └── ...
│   ├── composables/              # Переиспользуемая логика (hooks)
│   │   └── useBandData.ts        # Получение данных о группе
│   ├── utils/                    # Утилиты (валидация, helpers)
│   ├── assets/                   # Статические ресурсы (CSS, изображения)
│   ├── public/                   # Публичные файлы
│   ├── package.json              # Node.js зависимости
│   ├── nuxt.config.ts            # Конфигурация Nuxt
│   └── docker/                   # Dockerfile для контейнера
│
├── docker-compose.yml            # Конфигурация Docker Compose
├── nginx/                        # Конфигурация nginx
│   ├── nginx.conf                # Основная конфигурация
│   ├── ssl/                      # SSL сертификаты
│   └── conf.d/
│       └── default.conf          # Маршрутизация запросов
│
├── runtime/                      # Runtime данные (логи, сокеты)
│   └── php-fpm/
│       └── php-fpm.sock
│
├── Makefile                      # Удобные команды для управления
├── .env → backend/app/.env       # Симлинк на .env приложения
└── .gitignore                    # Git конфигурация
```

### Управление переменными окружения

Файл `.env` должен находиться в `backend/app/` — именно там его использует Symfony приложение. В корне проекта создается символический симлинк на этот файл для удобства доступа:

```bash
# Первоначальная подготовка:
cp backend/app/.env.example backend/app/.env  # Создай .env в приложении

# Далее можно редактировать файл через обе пути:
nano .env                      # Через симлинк в корне
nano backend/app/.env          # Или напрямую в приложении
```

## Функциональные требования

### Frontend приложение

#### Главная страница
- **Отображение информации о группе:**
  - Лого группы
  - Название и описание
  - Фотографии участников или обложки альбомов
  - Текстовый пресс-релиз с информацией о группе
  
- **Форма подписки:**
  - Поле ввода email
  - Валидация корректности email на клиенте и сервере
  - Кнопка подписки
  - Обработка успешной подписки (уведомление пользователю)
  - Обработка ошибок (вывод сообщений об ошибках)

#### Технические требования
- Данные о группе загружаются через API с backend'а при загрузке страницы
- Email-адреса отправляются на backend API при отправке формы
- Адаптивный дизайн (mobile-first подход)
- Оптимизация производительности (код-сплиттинг, ленивая загрузка, минификация)

### Backend приложение

#### REST API с версионированием

API использует версионирование через URL path для обеспечения обратной совместимости при эволюции интерфейса.

**Текущая версия API: v1**

Все endpoints находятся под префиксом `/api/v1/`

**Endpoints v1:**

1. **GET /api/v1/band** — получение информации о группе
   - Возвращает: название, описание, фото, лого, пресс-релиз
   - Аутентификация: не требуется
   - Кэширование: рекомендуется на уровне nginx/приложения

2. **POST /api/v1/subscribers** — добавление нового подписчика
   - Параметры: email
   - Валидация: корректность формата email, проверка на дубликаты
   - Возвращает: статус успеха/ошибки
   - Аутентификация: не требуется

#### Административная панель

**Доступ:** `/admin` — защищена аутентификацией

**Функциональность:**

1. **Редактирование информации о группе**
   - Форма с полями: название, описание, текст пресс-релиза
   - Загрузка файлов: лого (PNG/JPEG, макс. 5MB), фото (PNG/JPEG, макс. 10MB)
   - Сохранение изменений в БД
   - Валидация входных данных
   - Уведомление об успешном сохранении

2. **Просмотр списка подписчиков**
   - Таблица со всеми email-адресами подписчиков
   - Дата подписки
   - Возможность сортировки и фильтрации
   - Возможность экспорта (опционально)
   - Удаление подписчиков (с подтверждением)

3. **Система аутентификации**
   - Логин/пароль
   - Сессии или JWT токены
   - Защита от несанкционированного доступа

## Модель данных

Детальная модель данных (сущности, атрибуты, связи) будет описана в процессе разработки.

## Безопасность

### Backend
- **CORS**: Настроить правильно для разрешения запросов только с frontend домена
- **Валидация входных данных**: Все пользовательские данные валидируются на сервере
- **SQL Injection**: Использование ORM (Doctrine) предотвращает SQL инъекции
- **CSRF**: Защита от CSRF атак на уровне Symfony
- **Аутентификация админпанели**: Использование встроенных средств Symfony для управления доступом
- **HTTPS**: В production использовать HTTPS для всех соединений
- **Хранение файлов**: Загруженные файлы хранятся вне web root для безопасности

### Frontend
- **XSS Prevention**: Vue 3 автоматически экранирует выводимые данные
- **Валидация на клиенте**: Как дополнение к серверной валидации
- **Защита данных**: Чувствительные данные не хранятся в localStorage
- **HTTPS**: Все запросы к API через HTTPS в production

### Переменные окружения

Файл конфигурации `.env` находится в `backend/app/.env`. Создай его на основе `backend/app/.env.example`. В корне проекта используется символический симлинк `.env → backend/app/.env` для удобства доступа.

**Структура:**
```bash
backend/app/.env.example  # Исходный шаблон с документацией и примерами
backend/app/.env          # Реальный файл конфигурации (создается один раз)
.env                      # Симлинк в корне проекта → backend/app/.env
```

**Все переменные подробно задокументированы в `backend/app/.env.example`** с описанием их назначения и значений.

**Важно для production:**
- Никогда не коммитай `backend/app/.env` или `.env` в Git (они в `.gitignore`)
- Измени все пароли на сильные значения
- Установи `APP_DEBUG=0` и `APP_ENV=prod`
- Настрой HTTPS с SSL сертификатами

## Команды разработки

### Использование Makefile

Проект включает Makefile с удобными командами:

```bash
# Помощь и список команд
make help

# Управление сервисами
make up                    # Запустить сервисы
make down                  # Остановить сервисы
make restart               # Перезагрузить
make ps                    # Показать статус
make logs                  # Показать логи

# Backend (PHP/Symfony)
make shell-backend         # Открыть shell контейнера
make composer-install      # Установить зависимости
make composer-update       # Обновить зависимости
make migrate               # Запустить миграции БД
make cache-clear           # Очистить кэш
make test-backend          # Запустить тесты
make lint-fix              # Исправить стиль кода

# Frontend (Node.js/Nuxt)
make shell-frontend        # Открыть shell контейнера
make npm-install           # Установить зависимости
make test-frontend         # Запустить тесты
make format                # Форматировать код

# Database
make shell-database        # Открыть shell БД
```

### Прямые команды Docker Compose

```bash
# Service management
docker compose up -d       # Запустить в фоне
docker compose down        # Остановить
docker compose ps          # Статус
docker compose logs -f [service]  # Логи

# Backend — установка зависимостей и команды
docker compose exec backend composer install      # Установить PHP зависимости
docker compose exec backend composer update       # Обновить зависимости
docker compose exec backend php bin/console [command]  # Symfony команды
docker compose exec backend php bin/phpunit       # Запустить тесты

# Frontend
docker compose exec frontend npm install
docker compose exec frontend npm run dev
docker compose exec frontend npm run build

# Database
docker compose exec database mariadb -u infernus_user -p
```

### Важно о работе с контейнерами

**Backend контейнер:**
- Запускается без необходимости предварительной установки зависимостей через `composer install`
- Все файлы вашего приложения пробрасываются через volume, поэтому контейнер видит актуальный код
- Зависимости устанавливаются внутри контейнера по мере необходимости: `docker compose exec backend composer install`
- При удалении контейнера директория `vendor` может быть очищена — это нормально, переустановите зависимости

**Frontend контейнер:**
- Аналогично backend, код пробрасывается через volume
- Установите зависимости после запуска: `docker compose exec frontend npm install`

## Production развёртывание

### Предварительная подготовка

1. **Безопасность:**
   - [ ] Установи сильные пароли для всех сервисов
   - [ ] Сгенерируй сильный `APP_SECRET`
   - [ ] Настрой SSL сертификаты (Let's Encrypt)
   - [ ] Включи HTTPS редирект в nginx конфиге
   - [ ] Проверь CORS настройки для production домена

2. **Производительность:**
   - [ ] Оптимизируй OPcache настройки
   - [ ] Настрой CDN для статических файлов

3. **Данные:**
   - [ ] Настрой регулярные бэкапы БД
   - [ ] Проверь процедуры восстановления

4. **Инфраструктура:**
   - [ ] Используй Docker Swarm или Kubernetes
   - [ ] Настрой мониторинг контейнеров
   - [ ] Настрой алёрты при сбоях
   - [ ] Настрой сбор логов (ELK stack или аналог)

### Масштабируемость

**Backend:**
- Множество PHP-FPM контейнеров за nginx load balancer
- Database оптимизация через индексы и пагинацию
- Rate limiting для API защиты

**Frontend:**
- Code splitting по маршрутам
- Оптимизация изображений
- CDN для статических ресурсов
- Lazy loading компонентов

## Тестирование

### Backend

```bash
# Запустить юнит тесты
docker compose exec backend php bin/phpunit

# С покрытием кода
docker compose exec backend php bin/phpunit --coverage-html coverage
```

### Frontend

```bash
# Запустить тесты
docker compose exec frontend npm run test

# С покрытием кода
docker compose exec frontend npm run coverage
```

## Мониторинг и логирование

- **Backend**: Monolog (встроен в Symfony), логирование в `var/log/`
- **Frontend**: Console errors, custom error tracking
- **Database**: Монитор медленных запросов, статистика использования
- **Контейнеры**: Docker stats, Prometheus metrics
- **nginx**: Access и error логи в `/var/log/nginx/`

## Разрешение проблем

### Сервисы не запускаются

```bash
# Проверь логи
docker compose logs [service_name]

# Пересобери образы
docker compose build --no-cache

# Очистись и пересоздай
docker compose down -v
docker compose up -d
```

### Проблемы с подключением к БД

```bash
# Проверь здоровье БД
docker compose exec database mariadb-admin ping -u root -p

# Перезагрузи БД контейнер
docker compose restart database
```

### Hot reload не работает

```bash
# Перезагрузи frontend
docker compose restart frontend

# Проверь WebSocket в browser console на ошибки
# Убедись, что nginx позволяет WebSocket upgrade'ы
```

### Порт уже занят

```bash
# Найди процесс, использующий порт
lsof -i :80  # или :3000, :3306, etc.

# Или измени порты в .env
HTTP_PORT=8080
FRONTEND_PORT=3001
DB_PORT=3307
```

## Требования к окружению

- **Docker**: версия 20.10+
- **Docker Compose**: версия 1.29+
- **Node.js**: 18+ (для локальной разработки frontend)
- **PHP**: 8.4 (в контейнере)
- **MariaDB**: 12 (в контейнере)

## Возможные расширения в будущем

- Система управления событиями/концертами
- Галерея изображений
- Интеграция с социальными сетями
- Email-рассылки подписчикам
- Система комментариев/отзывов
- Интеграция с музыкальными платформами (Spotify, Apple Music)
- Многоязычная поддержка
- **Система кэширования (Redis)** — внедрение Redis для оптимизации производительности при кэшировании данных о группе и часто запрашиваемых API endpoints, что улучшит отзывчивость системы при масштабировании

## Дополнительные ресурсы

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Symfony Documentation](https://symfony.com/doc)
- [Nuxt Documentation](https://nuxt.com/docs)
- [nginx Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/)

---

**Статус:** Спроектировано (в разработке)

**Дата последнего обновления:** Февраль 2026

**Версия:** 0.1
