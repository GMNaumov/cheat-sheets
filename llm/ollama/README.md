# Ollama

Команды, модели и примеры локального запуска Ollama.

## Документация

- [Команды Ollama в Docker](commands.md) — управление контейнером и моделями.
- [Выбранные модели](models.md) — названия и примерные размеры.

## Примеры

- [Ollama через Docker Compose](examples/compose/) — запуск с ограничениями ресурсов.
- [Python-клиент Ollama](examples/python-client/) — клиент и Ollama в Compose.
- [Локальный RAG](examples/rag/) — Ollama, Qdrant и Streamlit.

Все три примера по умолчанию публикуют Ollama на порт `11434`. Запускайте их по одному или измените внешний порт в соответствующем `compose.yaml`, чтобы избежать конфликта.
