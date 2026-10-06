# Embedded Linux

Проект для сборки Linux-образов под Raspberry Pi Zero 2 W. Сейчас основной и проверенный путь сборки — Buildroot. В перспективе те же образы планируется собирать и через Yocto.

## Образы

| Профиль | Назначение | Состояние |
| --- | --- | --- |
| `base` | Минимальная базовая система для Raspberry Pi Zero 2 W: Linux, Raspberry Pi firmware и rootfs на BusyBox. | Собирается через Buildroot. |
| `fb_painter` | Задуманный образ мини-графического планшета: дисплей ILI9488, сенсорный ввод и приложение для рисования. | Buildroot-конфигурация и компоненты есть, но профиль пока требует интеграционной доработки; см. раздел «Текущее состояние». |

## Структура проекта

```text
.
├── br-external/                       # Buildroot external tree проекта
│   ├── Config.in                       # меню параметров проекта для Buildroot
│   ├── configs/                        # defconfig для board/profile
│   ├── package/python-fb-painter/      # Buildroot-пакет приложения
│   ├── projects/fb-painter/            # исходники Python-приложения
│   └── board/rpi0_2w/
│       ├── base/                       # загрузочные файлы и скрипты базового образа
│       └── fb_painter/                 # DTS, фрагмент конфигурации Linux,
│                                       # firmware ILI9488 и файлы профиля
├── scripts/
│   ├── build.sh                        # настройка и сборка профиля Buildroot
│   ├── fetch-buildroot.sh              # загрузка закреплённой версии Buildroot
│   ├── flash.sh                        # запись собранного образа на SD-карту
│   └── versions.env                    # версия и URL Buildroot
├── toolchains/                         # toolchain-файлы для других инструментов сборки
├── docker/Dockerfile                   # контейнер с зависимостями Buildroot
└── yocto/                              # заметки о планируемом Yocto BSP
```

`br-external` — расширение Buildroot: здесь находятся конфигурации, board-скрипты и описание пакета приложения. Исходники Buildroot скачиваются отдельно в `buildroot-<версия>/`, а результаты сборки находятся в `br-external/output/`; эти каталоги не хранятся в Git.

## Сборка через Buildroot

Нужны Linux-хост и базовые инструменты сборки: `make`, GCC/G++, Perl, Python 3, `wget`, `tar`, `cpio`, `rsync`, `bc`, `file`, `unzip`, `patch`, библиотеки и заголовки ncurses и OpenSSL. Версия Buildroot задаётся в `scripts/versions.env`; toolchain Bootlin и исходники пакетов скачиваются при сборке.

Собрать базовый образ:

```sh
bash scripts/build.sh rpi0_2w base
```

Готовый образ карты SD:

```text
br-external/output/rpi0_2w/base/images/sdcard.img
```

Для профиля планшета имя каталога и defconfig сейчас используют подчёркивание:

```sh
bash scripts/build.sh rpi0_2w fb_painter
```

Имя Python-пакета и приложения — `fb-painter` (через дефис); это отдельное имя, не аргумент профиля сборки.

Если Linux-хост работает через WSL и его `PATH` включает Windows-каталоги с пробелами, перед сборкой может потребоваться чистый Linux `PATH`:

```sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  bash scripts/build.sh rpi0_2w base
```

## Сборка в Docker и GitHub Actions

Для сборки нужен установленный Docker. Из корня репозитория создайте контейнер:

```sh
docker build --file docker/Dockerfile --tag embedded-linux-builder:local docker
```

Затем запустите сборку `base`, примонтировав checkout в контейнер. Результат и кэш Buildroot останутся в рабочем каталоге:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace \
  embedded-linux-builder:local
```

По умолчанию контейнер запускает `bash scripts/build.sh rpi0_2w base`. Чтобы передать другую команду, укажите её после имени образа, например:

```sh
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --env HOME=/tmp \
  --volume "$PWD:/workspace" \
  --workdir /workspace \
  embedded-linux-builder:local \
  bash scripts/build.sh rpi0_2w fb_painter
```

GitHub Actions workflow [`.github/workflows/buildroot.yml`](.github/workflows/buildroot.yml) запускает сборку `rpi0_2w/base` при push, pull request и вручную через `workflow_dispatch`. Он собирает Docker-образ, запускает Buildroot в примонтированном checkout’е, кэширует исходники в `dl/` и публикует `sdcard.img` как артефакт на 14 дней. Артефакт доступен на странице завершённого workflow в разделе **Artifacts**.

CI пока собирает только `base`: `fb_painter` ещё не проходит собственную конфигурацию, как описано ниже. Контейнер запускает процесс от UID/GID пользователя хоста, поэтому файлы в рабочем каталоге не должны становиться root-owned.

## Запись на SD-карту

`scripts/flash.sh` записывает образ на указанное блочное устройство и стирает его прежнее содержимое. Перед запуском проверьте имя устройства и размонтируйте его разделы:

```sh
bash scripts/flash.sh /dev/sdX rpi0_2w base
```

Замените `/dev/sdX` на устройство карты памяти. Скрипт показывает выбранный файл и устройство, ждёт пять секунд и затем вызывает `sudo dd`.

## Buildroot и Yocto

Цель проекта — поддерживать оба способа сборки. Сейчас реально интегрирован только Buildroot. Каталог `yocto/` пока содержит план, но не содержит Yocto layer, `kas`-конфигурации, machine-конфигурации или рецептов. Поэтому Yocto-сборку на текущем состоянии выполнить нельзя.

Для переноса понадобятся как минимум:

- Yocto layer с рецептами базовой системы и приложения `fb-painter`;
- machine-конфигурация Raspberry Pi Zero 2 W и согласованные kernel/U-Boot либо Raspberry Pi firmware настройки;
- перенос Linux fragment, DTS overlay и способов установки firmware-файлов;
- image-рецепт с разделами загрузки и rootfs, соответствующими текущему SD-образу;
- сборка Python-пакета из тех же исходников, что использует Buildroot.

Часть board-данных и исходников приложения уже вынесена отдельно от Buildroot и может использоваться повторно. Однако `.mk`-описание пакета, defconfig и post-build/post-image скрипты зависят от Buildroot. Для двух поддерживаемых сборочных систем лучше сохранять общие исходники, DTS и настройки устройства общими, а рецепты, machine-настройки и упаковку образа реализовать отдельно для каждого инструмента.

## Текущее состояние и ограничения

- `base` проверен полной сборкой Buildroot для `rpi0_2w`; создан `sdcard.img`.
- `fb_painter` — проектируемый профиль, а не подтверждённая сборка. Его defconfig указывает на отсутствующий каталог `board/rpi0_2w/fb_painter/patches`; Buildroot остановится на этой проверке, пока ссылку не убрать или каталог не добавить.
- В `fb_painter` есть overlay, firmware-команды для ILI9488, DTS overlay, Linux fragment и исходники приложения. При этом в репозитории не найден init-скрипт автозапуска, несмотря на сообщение об автозапуске в `scripts/flash.sh`.
- Есть несогласованность имён: Build-скрипт формирует имя defconfig из аргумента профиля, директория профиля называется `fb_painter`, а некоторые комментарии и сообщения используют `fb-painter`. Используйте `fb_painter` для вызова Buildroot до унификации этих имён.
- Пути framebuffer также требуют сверки: приложение открывает `/dev/fb0`, а подсказка в Buildroot-меню пакета говорит о `/dev/fb1`. Нужна проверка на целевом дисплее и фиксация ожидаемого устройства.

Проверенный сейчас результат — базовый образ. Образ планшета и Yocto-путь требуют дальнейшей интеграции и проверки на целевом оборудовании.
