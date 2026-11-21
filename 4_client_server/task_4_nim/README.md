# 4.4. Сервер сравнения семантических версий на Nim

TCP-сервер сравнивает версии по Semantic Versioning 2.0.0. Учитываются числовые компоненты и предрелизные идентификаторы, метаданные сборки не влияют на приоритет. Некорректный запрос возвращает ошибку.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 4_client_server/task_4_nim
docker build -t npl-semver .
docker run --rm --name npl-semver -p 127.0.0.1:5004:5004 npl-semver server 5004
```

В другом терминале:

```powershell
docker exec npl-semver ./semver client 5004 "COMPARE 1.0.0-alpha 1.0.0"
docker exec npl-semver ./semver client 5004 "COMPARE 1.2.3+one 1.2.3+two"
```

Ответы `OLDER`, `NEWER`, `EQUAL` относятся к первой версии относительно второй. Примеры возвращают `OLDER` и `EQUAL`. Сервер останавливается через Ctrl+C.
