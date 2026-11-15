# Ollama, Open WebUI и DeepSeek Harness

Пример запускает Ollama на одной NVIDIA GPU и Open WebUI в режиме одного пользователя без входа. DeepSeek Harness (DSH) подключается отдельно через профиль `harness`. Все опубликованные порты привязаны к `127.0.0.1`.

## Перед началом

- Нужны Docker с Compose v2, интернет и свободное место для образов и моделей.
- Для Windows нужен Docker Desktop с Linux-контейнерами и WSL 2, актуальный драйвер NVIDIA и доступная из Docker GPU. Для Linux нужен настроенный NVIDIA Container Toolkit.
- В конфигурации запрашивается одна NVIDIA GPU. На компьютере без неё запуск Ollama завершится ошибкой; для работы на CPU удалите блок `deploy.resources.reservations.devices` у `ollama-local`.
- Порты `11434`, `3000` и, при запуске DSH, `3080` должны быть свободны. Другие примеры Ollama и DSH из репозитория публикуют те же порты: остановите их или измените внешние порты здесь.
- Команды ниже выполняются в каталоге этого примера, рядом с `compose.yaml`.

Проверка конфигурации не запускает контейнеры и не проверяет наличие GPU:

```bash
docker compose --profile harness config --quiet
```

## Запуск Ollama и Open WebUI

Запустите основные сервисы и дождитесь готовности API и интерфейса. Модели автоматически не загружаются:

```bash
docker compose up -d --wait --wait-timeout 300
```

После готовности Ollama загрузите модель. Для `qwen3:4b` потребуется около 2.5 GB на диске и дополнительная память во время выполнения:

```bash
docker compose exec ollama-local ollama pull qwen3:4b
docker compose exec ollama-local ollama list
```

Откройте `http://localhost:3000`, выберите `qwen3:4b` и отправьте сообщение. После ответа можно проверить размещение модели в памяти:

```bash
docker compose exec ollama-local ollama ps
```

В колонке `PROCESSOR` видно, использует ли модель GPU полностью или частично. `OLLAMA_KEEP_ALIVE=30m` сохраняет модель в памяти до 30 минут после последнего запроса.

Адрес Ollama для Open WebUI — `http://ollama-local:11434`, а для программ на хосте — `http://localhost:11434`. `host.docker.internal` здесь не требуется: сервисы общаются в сети Compose.

## Запуск DeepSeek Harness

Профиль `harness` добавляет DSH к уже запущенному окружению. Конфигурация и сессии сохраняются в отдельном томе, рабочие файлы доступны на хосте в [`workspace`](workspace/README.md).

В Linux DSH работает с UID/GID `1000:1000`. Если владелец каталога `workspace` другой, перед запуском предоставьте этому пользователю право записи. Следующая команда меняет владельца только самого каталога:

```bash
sudo chown 1000:1000 workspace
```

В Docker Desktop на Windows этот шаг обычно не требуется. Запустите DSH с ожиданием встроенной проверки готовности:

```bash
docker compose --profile harness up -d --wait --wait-timeout 300 dsh-local
```

Откройте `http://localhost:3080`. В `Settings` → `Models` добавьте провайдера `Custom model API`:

| Поле | Значение |
| --- | --- |
| API key | `ollama` — непустое значение для клиента, локальная Ollama его не проверяет |
| Provider ID | `ollama-local` |
| Display name | `Ollama local` |
| Base URL | `http://ollama-local:11434/v1` |
| API Protocol | `OpenAI Chat Completions` |

Нажмите `Fetch available models`, выберите `qwen3:4b`, затем `Add selected` и `Create provider`. Создайте Workspace с рабочим каталогом `/workspace`, выберите модель и отправьте тестовый запрос. Иллюстрации настройки находятся в [руководстве DSH](../../deepseek-harness/guides/install-with-ollama.md).

DSH может изменять и удалять файлы в `workspace`. Не подключайте к нему домашний каталог, Docker socket или файлы с секретами.

## Диагностика

Покажите все контейнеры проекта, включая DSH, и последние сообщения сервисов:

```bash
docker compose --profile harness ps -a
docker compose --profile harness logs --tail=100
```

У запущенных сервисов ожидается состояние `healthy`. Если `up --wait` завершился ошибкой, уже созданные контейнеры могут продолжить работу: изучите логи и остановите их командой из следующего раздела.

Если модели есть в `ollama list`, но не видны в Open WebUI, проверьте `Admin Panel` → `Settings` → `Connections`. Настройки подключения, ранее сохранённые в базе WebUI, имеют приоритет над `OLLAMA_BASE_URL`. Укажите там `http://ollama-local:11434`, сохраните и обновите список моделей.

## Остановка

Удаляет контейнеры обоих режимов и сеть проекта. Модели, история WebUI, конфигурация DSH и файлы `workspace` сохраняются:

```bash
docker compose --profile harness down
```

## Удаление данных

Следующая команда безвозвратно удалит тома с моделями Ollama, историей и настройками Open WebUI, конфигурацией и сессиями DSH. Файлы `workspace` на хосте сохранятся. Не выполняйте её для обычной остановки или обновления:

```bash
docker compose --profile harness down --volumes
```

## Версии и ограничения

- Ollama зафиксирована на `0.40.7`, Open WebUI — на `v0.13.3-slim`. Для обновления сначала сохраните данные, измените тег, выполните `docker compose pull` и повторите запуск. Запущенный DSH обновляется отдельно через профиль `harness`.
- Вариант WebUI `slim` предназначен для чата через внешний сервер моделей. Локальные обработчики PDF, эмбеддингов и речи не включены; для них требуются отдельные сервисы или стандартный образ WebUI.
- Образ DSH из проекта `omdsh-dev/dsh-container` закреплён по многоплатформенному digest, проверенному 2026-11-15. Это другой контейнерный образ, чем исходный `m11s/deepseek-harness`; его каталог настроек — `/home/node/.dsh`.
- У Open WebUI отключён вход; у DSH не задан ключ доступа; API Ollama не требует ключа. Режим предназначен для локального компьютера. Для доступа из сети нужны отдельная настройка авторизации и защита соединения, а не только изменение привязки портов.
- Ключ WebUI автоматически создаётся в `/app/backend/data/.webui_secret_key` и сохраняется вместе с данными. Не публикуйте этот том.

## Переход с исходной конфигурации

Compose-файл перемещён на один уровень ниже, в `examples/`. Имя проекта `llm-local-staff` и ключи томов `ollama-local-data`, `open-webui-local-data` и `dsh-local-data` сохранены, поэтому Compose выберет прежние тома при запуске без переопределения имени проекта. Если раньше использовали `-p` или `COMPOSE_PROJECT_NAME`, используйте то же значение.

Перед первым запуском новой версии сохраните резервные копии существующих данных. Миграции базы WebUI могут мешать возврату к старому образу. Существующую базу WebUI нельзя свободно переключать между режимами с авторизацией и без неё; здесь сохранён исходный режим `WEBUI_AUTH=false`.

Настройки старого образа DSH из `/home/dsh/.dsh` не считаются совместимыми с новым образом. При наличии важных сессий сначала экспортируйте или сохраните старый том, затем проверьте перенос отдельно. Если ранее подключался каталог `../workspace`, его файлы нужно перенести в `workspace` рядом с новым Compose-файлом либо скорректировать bind mount.

## Источники

- [Ollama в Docker](https://docs.ollama.com/docker) — настройка NVIDIA GPU.
- [Образы и режимы Open WebUI](https://docs.openwebui.com/getting-started/quick-start/) — вариант `slim`, авторизация и ограничения обновлений.
- [Переменные Open WebUI](https://docs.openwebui.com/reference/env-configuration/) — подключение к Ollama и приоритет сохранённых настроек.
- [Скрипт запуска Open WebUI v0.13.3](https://github.com/open-webui/open-webui/blob/v0.13.3/backend/start.sh) — сохранение ключа в `WEBUI_SECRET_KEY_FILE`.
- [Образ DSH от omdsh-dev](https://github.com/omdsh-dev/dsh-container) — переменные, доверенные хосты и сохранение данных.
