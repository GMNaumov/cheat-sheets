# Пример DeepSeek Harness

Compose-конфигурация запускает DeepSeek Harness и Ollama в общей внутренней сети. Полная последовательность запуска и настройки описана в [руководстве](../guides/install-with-ollama.md).

## Запуск

Выполните команды в каталоге примера:

```bash
docker compose up -d ollama
docker compose exec ollama ollama pull qwen3:latest
docker compose up -d dsh
```

Интерфейс DSH будет доступен по адресу `http://localhost:3080`.

## Проверка состояния

Показывает состояние сервисов проекта и последние строки логов DSH. Для непрерывного просмотра добавьте `-f` к команде `logs`.

```bash
docker compose ps
docker compose logs --tail=100 dsh
```

## Остановка

Останавливает контейнеры и сеть проекта. Данные в именованных томах сохраняются.

```bash
docker compose down
```

## Удаление данных

Следующая команда безвозвратно удалит том Ollama с загруженными моделями, а также тома DSH с настройками и рабочими файлами. Пропустите этот шаг, если данные нужны для повторного запуска.

```bash
docker compose down --volumes
```
