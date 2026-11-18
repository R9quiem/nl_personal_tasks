# 1.4. Параллельный поиск дубликатов файлов на D

Программа обходит каталог и подпапки, группирует файлы по размеру, параллельно вычисляет SHA-256 и подтверждает совпадения побайтовым сравнением. Выводятся группы файлов с одинаковым содержимым.

## Запуск

Требуется компилятор DMD. Команды выполняются из корня репозитория в PowerShell.

```powershell
cd 1_threads/task_4_d
New-Item -ItemType Directory -Force build | Out-Null
dmd -m64 '-of=build\duplicates.exe' source/main.d
.\build\duplicates.exe "C:\data"
```

Аргумент — путь к каталогу для проверки.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/16X0G9gWD-JJ3yxUrZ0O2Maet0YtSmVhv/view?usp=sharing)
