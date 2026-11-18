# Локальное LLM-окружение

Ollama с одной NVIDIA GPU, Open WebUI для локального чата и необязательный DeepSeek Harness. Сервисы используют общую Ollama и сохраняют данные между запусками.

- [Запускаемый Compose-пример](examples/README.md) — требования, запуск, настройка DSH, диагностика и остановка.
- [Continue в VS Code](examples/README.md#использование-локальной-llm-в-vs-code-через-continue) — локальный чат, редактирование и автодополнение через Ollama.
- [Рабочий каталог DSH](examples/workspace/README.md) — файлы, доступные агенту для изменения.

Конфигурация перенесена из `compose.yaml` в `examples/compose.yaml`. Имя Compose-проекта `llm-local-staff` и имена томов Ollama и Open WebUI сохранены. Перед повторным использованием уже существующих данных учитывайте [ограничения перехода](examples/README.md#переход-с-исходной-конфигурации).
