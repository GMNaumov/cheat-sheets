# Подключение DeepSeek Harness к Ollama

Подключение DeepSeek Harness, запущенного в контейнере, зависит от хостовой системы и способа запуска Ollama:

| Где работает Ollama | Адрес API для DSH | Условие |
| --- | --- | --- |
| На хосте Windows или macOS, DSH в Docker Desktop | `http://host.docker.internal:11434/v1` | Ollama принимает подключения от контейнера. |
| На хосте Linux, DSH в Docker | `http://host.docker.internal:11434/v1` | В сервис DSH добавлен `host-gateway`; Ollama принимает подключения от контейнера. |
| В одной сети Docker Compose с DSH | `http://ollama:11434/v1` | Имя сервиса Ollama в Compose — `ollama`. |

## Настройка `host.docker.internal` в Linux

Добавьте в описание сервиса DSH в `compose.yaml`:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Сопоставление `host-gateway` поддерживается Docker 20.10 и новее. Если этот вариант недоступен, можно использовать адрес настроенного Docker-моста, например `172.17.0.1`, но его необходимо предварительно проверить: он может отличаться.

Ollama должна принимать соединения с адреса Docker-моста. Настраивайте сетевой доступ только для доверенной сети: открытие API на всех интерфейсах без дополнительной защиты может сделать Ollama доступной другим устройствам.
