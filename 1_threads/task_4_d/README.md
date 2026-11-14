# 1.4. Параллельный поиск дубликатов файлов на D

Программа обходит каталог вместе с подпапками и выводит группы файлов с одинаковым содержимым. Символические ссылки пропускаются. При ошибке доступа программа выводит сообщение и завершается с кодом `1`.

## Сборка и запуск в PowerShell

Из корня репозитория выполните:

```powershell
cd 1_threads/task_4_d
New-Item -ItemType Directory -Force build | Out-Null
dmd -m64 '-of=build\duplicates.exe' source/main.d
.\build\duplicates.exe 'E:\папка для проверки'
```

На этом компьютере компилятор распакован в `E:\prog\npl-labs-tools\dmd-2.111.0`. Если `dmd` недоступен в `PATH`, для сборки используйте:

```powershell
& 'E:\prog\npl-labs-tools\dmd-2.111.0\dmd2\windows\bin64\dmd.exe' -m64 '-of=build\duplicates.exe' source/main.d
```

## Как работает программа

1. Файлы группируются по размеру. Если в группе только один файл, его содержимое читать не нужно.
2. Для остальных файлов несколько потоков считают SHA-256. Каждый поток читает свой файл блоками до 64 КиБ и записывает хеш в отдельную ячейку массива.
3. Файлы с совпавшими размером и хешем сравниваются побайтово. Внутри каждой группы достаточно сравнить новый файл с её первым файлом. Если хеш совпал, а содержимое различается, пути окажутся в разных группах.

## Демонстрация для видео

```powershell
$demo = Join-Path $PWD.Path 'build/demo'
$nested = Join-Path $demo 'nested'
New-Item -ItemType Directory -Force $nested | Out-Null
[IO.File]::WriteAllBytes((Join-Path $demo 'original.bin'), [byte[]](0, 255, 7))
[IO.File]::WriteAllBytes((Join-Path $nested 'copy.bin'), [byte[]](0, 255, 7))
[IO.File]::WriteAllBytes((Join-Path $demo 'other.bin'), [byte[]](0, 255, 8))
.\build\duplicates.exe $demo
```

Покажите, что все три файла имеют одинаковый размер, но программа выводит одну группу из `original.bin` и `nested/copy.bin`. Затем покажите в коде группировку по размеру, параллельный `foreach` для SHA-256 и `sameContents` для побайтовой проверки.
