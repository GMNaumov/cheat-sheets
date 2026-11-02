# Выбранные модели Ollama

Названия моделей для команд Ollama и их примерные размеры. Список составлен в октябре 2026 года; доступность и размеры следует сверять перед загрузкой.

Имя модели можно подставлять в [команды Ollama](commands.md). Например:

```bash
docker exec -it ollama ollama pull qwen3:4b
```

В скобках ниже указан примерный размер загружаемых файлов, а не объём RAM или VRAM во время запуска. Рабочая память зависит от модели, длины контекста, параллельных запросов и параметров запуска, поэтому должна быть больше размера файла модели.

## [llama3.1](https://ollama.com/library/llama3.1)

- `llama3.1:8b` (4.9 GB)
- `llama3.1:70b` (43 GB)
- `llama3.1:405b` (243 GB)

## [llama3.2](https://ollama.com/library/llama3.2)

- `llama3.2:1b` (1.3 GB)
- `llama3.2:3b` (2.0 GB)

## [qwen3](https://ollama.com/library/qwen3)

- `qwen3:0.6b` (0.5 GB)
- `qwen3:1.7b` (1.4 GB)
- `qwen3:4b` (2.5 GB)
- `qwen3:8b` (5.2 GB)
- `qwen3:14b` (9.3 GB)
- `qwen3:30b` (19 GB)
- `qwen3:32b` (20 GB)
- `qwen3:235b` (142 GB)

## [phi4-mini](https://ollama.com/library/phi4-mini)

- `phi4-mini:3.8b` (2.5 GB)
