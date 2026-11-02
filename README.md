# cheat-sheets

Личное хранилище инструкций, команд, примеров конфигурации и рабочих заметок.

## Разделы

- [Docker](docker/README.md) — команды и руководства по установке и удалению Docker.
- [Git](git/README.md) — создание репозитория и повседневные команды.
- [Java](java/README.md) — команды для создания проектов Spring Boot.
- [Linux](linux/README.md) — команды и управление пакетами.
- [LLM](llm/README.md) — Ollama, DeepSeek Harness, RAG и промпты.
- [Платформы](platforms/README.md) — инструкции, привязанные к конкретным платформам.
- [Соглашения](conventions/README.md) — правила именования и шаблон Markdown-материалов.

## Соглашения репозитория

- Расположение и имена файлов описаны в [правилах репозитория](conventions/repository.md).
- Структура Markdown-материалов описана в [эталонном шаблоне](conventions/markdown-template.md).

## Проверка репозитория

Локальные ссылки между Markdown-файлами можно проверить командой:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-markdown-links.ps1
```

Пути из Compose-файлов проверяются отдельно. Для разбора конфигурации нужен Docker Compose:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-compose-paths.ps1
```

Для проверки Markdown с помощью `markdownlint-cli2` нужны Node.js и `npx`:

```powershell
npx --yes markdownlint-cli2@0.24.0 "**/*.md" "#node_modules"
```

Для проверки синтаксиса Python нужен Python 3:

```powershell
python -m compileall -q .\llm\ollama\examples
```

В Linux и macOS замените `python` на `python3`, если интерпретатор установлен под этим именем.

GitHub Actions при push и pull request также проверяет Markdown, синтаксис Python и корректность Compose-конфигураций.
