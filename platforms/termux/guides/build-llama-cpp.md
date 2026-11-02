# Сборка llama.cpp в Ubuntu через Termux

Инструкция создаёт Ubuntu-окружение в Termux на Android и собирает сервер `llama.cpp` из исходников.

## Перед началом

Нужны установленный Termux, подключение к интернету и свободное место для Ubuntu и исходников. Сборка может занять продолжительное время.

## Шаг 1. Обновить Termux

В терминале Termux обновите список пакетов и установленные пакеты:

```bash
pkg update -y && pkg upgrade -y
```

## Шаг 2. Установить инструменты Termux

`proot-distro` создаёт изолированное Linux-окружение без обычного Docker.

```bash
pkg install -y proot-distro git curl wget termux-exec
```

## Шаг 3. Установить Ubuntu

```bash
proot-distro install ubuntu:24.04
```

## Шаг 4. Войти в Ubuntu

Флаг `--isolated` отключает стандартные привязки каталогов Termux, включая общую память Android.

```bash
proot-distro login ubuntu --isolated
```

Следующие команды выполняйте внутри Ubuntu.

## Шаг 5. Установить инструменты сборки

```bash
apt update -y && apt upgrade -y
apt install -y build-essential git cmake
```

## Шаг 6. Собрать llama.cpp

Клонируйте репозиторий и соберите `llama-server`:

```bash
git clone https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
cmake -B build -DGGML_NATIVE=ON
cmake --build build --config Release --target llama-server -j$(nproc)
```

Команда собирает только сервер. Дополнительные оптимизации можно настроить отдельно.

Флаг `-j$(nproc)` использует все доступные потоки и может вызвать нехватку памяти на Android-устройстве. В этом случае замените его на `-j2`, а если памяти всё ещё недостаточно — на `-j1`.

## Проверка результата

Убедитесь, что исполняемый файл появился по пути `build/bin/llama-server`.
