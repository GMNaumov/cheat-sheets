# Правила именования проектов и инфраструктуры

Соглашения об идентификаторах проектов, расположении файлов и именах инфраструктурных ресурсов.

## Основные правила

- Основная сущность — **project-id**: `ngm-<domain>-<project>`. Пример: `ngm-llm-rag`.

- В идентификаторах проектов и инфраструктурных ресурсов используем только lowercase и дефис `-` как разделитель. Пробелы, PascalCase, camelCase, точки и нижние подчёркивания не используем. Стандартные имена и требования инструментов, например `README.md`, `.env` или поля сторонних форматов, остаются без изменений.

## Структура хранения

Пример расположения исходников, артефактов и резервных копий:

```text
/srv/
├── git/
│   └── ngm/
│       └── <domain>/
│           └── <project-id>.git
├── work/
│   └── ngm/
│       └── <domain>/
│           └── <project-id>/
│               ├── .git/
│               ├── project.yaml
│               ├── README.md
│               ├── docs/
│               │   ├── tasks/
│               │   │   └── TASK-<project-id>-<NNNN>-<slug>.md
│               │   ├── adr/
│               │   │   └── ADR-<project-id>-<NNNN>-<slug>.md
│               │   └── runbooks/
│               │       └── RUNBOOK-<project-id>-<slug>.md
│               ├── deploy/
│               │   └── docker/
│               │       ├── compose.yaml
│               │       ├── compose.prod.yaml
│               │       └── .env.example
│               ├── src/
│               └── tests/
├── artifacts/
│   └── <project-id>/
│       └── <component>/
│           └── <version>/
└── backups/
    └── docker-volumes/
        └── <volume-name>/
            └── <YYYY-MM-DDTHH-MM-SSZ>/
```

## Пример YAML проекта

Описание проекта в `project.yaml`:

```yaml
schema: 1
id: ngm-pdm-workflow
org: ngm
domain: pdm
project: workflow
display_name: "Workflow processes customization"
components:
  - id: api
    type: service
    language: C#
    image: registry.local/ngm/pdm/workflow/api
  - id: worker
    type: service
    language: python
    image: registry.local/ngm/pdm/workflow/worker
  - id: db
    type: datastore
    engine: postgres
environments: [local, dev, stage, prod]
```

## Пример Docker Compose

Фрагмент демонстрирует соглашения об именовании ресурсов и не является полной конфигурацией развёртывания.

```yaml
name: ngm-pdm-workflow-prod

services:
  api:
    image: registry.local/ngm/pdm/workflow/api:v1.4.2
    container_name: ngm-pdm-workflow-api-prod-01
    networks:
      - ngm-pdm-workflow-prod-net

  worker:
    image: registry.local/ngm/pdm/workflow/worker:v1.4.2
    container_name: ngm-pdm-workflow-worker-prod-01
    networks:
      - ngm-pdm-workflow-prod-net

volumes:
  ngm-pdm-workflow-db-data-prod:
    name: ngm-pdm-workflow-db-data-prod

networks:
  ngm-pdm-workflow-prod-net:
    name: ngm-pdm-workflow-prod-net
```
