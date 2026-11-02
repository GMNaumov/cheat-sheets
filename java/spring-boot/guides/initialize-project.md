# Скрипт для инициализации нового проекта Spring Boot

Команда загружает готовый ZIP-архив проекта из Spring Initializr и распаковывает его в текущем каталоге. Нужны `curl` и `unzip`.

`baseDir` задаёт имя папки, в которую будет распакован архив. Перед запуском замените параметры проекта на нужные значения. Для другого имени проекта замените `my-project` в проверке каталога, параметрах `artifactId`, `name`, `baseDir` и имени архива. Отдельно измените `packageName`, например на `com.example.newproject`.

## Скачать и распаковать проект

Команда не запускает загрузку, если каталог `my-project` уже существует. Флаг `--fail` сообщает об HTTP-ошибках, а `--location` разрешает перенаправления. Распаковка выполняется только после успешной загрузки, а архив удаляется только после успешной распаковки.

```bash
if [ -e my-project ]; then
  echo "Каталог my-project уже существует. Выберите другое имя проекта." >&2
else
  curl --fail --location https://start.spring.io/starter.zip \
    -d type=maven-project \
    -d dependencies=web,data-jpa,lombok \
    -d javaVersion=25 \
    -d bootVersion=4.1.2 \
    -d groupId=com.example \
    -d artifactId=my-project \
    -d name=my-project \
    -d packageName=com.example.myproject \
    -d baseDir=my-project \
    -o my-project.zip &&
  unzip my-project.zip &&
  rm my-project.zip
fi
```

После распаковки перейдите в каталог `my-project` и используйте [команды запуска, тестирования и сборки](../commands.md).
