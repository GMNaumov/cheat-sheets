# Команды Ollama в Docker

Команды для сервиса `ollama` в примерах этого раздела. Выполняйте их в каталоге соответствующего `compose.yaml`; в примерах управления моделями используется `phi4-mini`. Имя контейнера знать не требуется.

## Контейнер и окружение

### Узнать версию Ollama

```bash
docker compose exec ollama ollama --version
```

### Показать скачанные модели

```bash
docker compose exec ollama ollama list
```

### Проверить состояние сервиса

Показывает состояние контейнера Ollama в текущем Compose-проекте.

```bash
docker compose ps ollama
```

### Посмотреть логи Ollama

Выводит последние сообщения и продолжает показывать новые. Выход из просмотра: `Ctrl+C`.

```bash
docker compose logs --tail=100 -f ollama
```

### Остановить окружение Compose

Останавливает и удаляет контейнеры и сеть проекта. Данные остаются в именованном томе.

```bash
docker compose down
```

### Запустить окружение Compose

```bash
docker compose up -d
```

### Посмотреть использование ресурсов

```bash
docker compose stats ollama
```

### Открыть оболочку контейнера

```bash
docker compose exec ollama sh
```

## Модели

### Показать модели в памяти

`ollama ps` показывает модели, которые сейчас загружены для выполнения запросов.

```bash
docker compose exec ollama ollama ps
```

### Загрузить модель

Скачивает `phi4-mini` в контейнер. Понадобятся интернет и свободное место на диске.

```bash
docker compose exec ollama ollama pull phi4-mini
```

### Посмотреть сведения о модели

```bash
docker compose exec ollama ollama show phi4-mini
```

### Запустить интерактивный чат

`docker compose exec` по умолчанию подключает интерактивный терминал для ввода сообщений.

```bash
docker compose exec ollama ollama run phi4-mini
```

### Остановить модель

Выгружает модель из памяти, сохраняя её файлы.

```bash
docker compose exec ollama ollama stop phi4-mini
```

### Удалить модель с диска

Удаляет файлы модели `phi4-mini` из хранилища Ollama.

```bash
docker compose exec ollama ollama rm phi4-mini
```
