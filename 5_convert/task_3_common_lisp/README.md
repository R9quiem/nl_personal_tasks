# 5.3. PGM → текстовая графика на Common Lisp

Программа преобразует PGM P2 в ASCII-art со шкалой `@%#*+=-:. ` от чёрного к белому. Размер изображения сохраняется. Комментарии, начинающиеся с `#`, поддерживаются.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 5_convert/task_3_common_lisp
New-Item -ItemType Directory -Force build | Out-Null
docker build -t npl-pgm .
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/data" npl-pgm /data/examples/gradient.pgm /data/build/image.txt
Get-Content build/image.txt
```

Аргументы — входной PGM и выходной текстовый файл. После `P2` задаются ширина, высота, максимальная яркость от 1 до 65535 и значения пикселей. Число пикселей должно совпадать с размером изображения.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/1BK2tROszi3Vi3CQBHbyFJuEDXN0GOjXw/view?usp=sharing)
