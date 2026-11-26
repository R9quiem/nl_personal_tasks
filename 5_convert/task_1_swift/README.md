# 5.1. JSON → Graphviz DOT на Swift

Программа преобразует JSON-описание ориентированного графа в DOT. Проверяются уникальность идентификаторов и ссылки рёбер на вершины. Кавычки и обратные слеши экранируются.

## Запуск

Требуется Docker Desktop с Linux-контейнерами.

Из корня репозитория в PowerShell:

```powershell
cd 5_convert/task_1_swift
New-Item -ItemType Directory -Force build | Out-Null
docker build -t npl-dot .
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/data" npl-dot /data/examples/graph.json /data/build/graph.dot
Get-Content -Encoding utf8 build/graph.dot
```

Аргументы — входной JSON и выходной DOT. Массив `nodes` содержит объекты с полями `id`, `label`, массив `edges` — объекты с полями `from`, `to`. Все поля — строки.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/11HrEIaXyBqQc8KF8Z4-Ql5gdO_RnZe_P/view?usp=sharing)
