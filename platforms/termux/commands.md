# Основные команды Termux

Короткий справочник по пакетам Termux и входу в установленное Ubuntu-окружение. Команды ниже выполняются в самом Termux, до входа в Ubuntu.

## Пакеты Termux

### Обновить пакеты

Обновляет сведения о пакетах, затем установленные пакеты.

```bash
pkg update && pkg upgrade
```

### Найти и установить пакет

Первой командой найдите пакет, затем установите нужный.

```bash
pkg search cmake
pkg install cmake
```

## Ubuntu через proot-distro

### Показать установленные окружения

В proot-distro 5 и новее команда выводит установленные окружения. Доступные образы Ubuntu можно найти отдельной командой `proot-distro search ubuntu`.

```bash
proot-distro list
```

### Войти в Ubuntu

Требуется окружение, установленное по [руководству](guides/build-llama-cpp.md).

```bash
proot-distro login ubuntu --isolated
```

Чтобы вернуться в Termux, выполните внутри Ubuntu команду `exit`.
