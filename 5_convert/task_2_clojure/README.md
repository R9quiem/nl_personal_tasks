# 5.2. Журнал Apache → CSV на Clojure

Программа преобразует Common Log Format в CSV с полями `ip,time,method,path,status,bytes`. Некорректные строки пропускаются, их количество выводится в терминал. Размер ответа `-` преобразуется в `0`.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 5_convert/task_2_clojure
New-Item -ItemType Directory -Force build | Out-Null
docker build -t npl-apache-csv .
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/data" npl-apache-csv /data/examples/access.log /data/build/access.csv
Get-Content -Encoding utf8 build/access.csv
```

Аргументы — входной журнал и выходной CSV. Файлы читаются и записываются в UTF-8. В примере преобразуются две строки, одна пропускается.
