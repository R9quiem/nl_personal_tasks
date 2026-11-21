# 5.4. SQL INSERT → CSV на Scheme

Программа преобразует один или несколько `INSERT INTO ... (столбцы) VALUES ...` для одной таблицы в CSV. Поддерживаются целые числа, строки с удвоенными апострофами и NULL. Перестановка одинакового набора столбцов учитывается.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 5_convert/task_4_scheme
New-Item -ItemType Directory -Force build | Out-Null
docker build -t npl-sql-csv .
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/data" npl-sql-csv /data/examples/people.sql /data/build/people.csv
Get-Content -Encoding utf8 build/people.csv
```

Аргументы — входной SQL и выходной CSV в UTF-8. Имена столбцов указываются явно. NULL записывается пустым полем, строки заключаются в двойные кавычки. Первая строка CSV содержит имена столбцов первого оператора.
