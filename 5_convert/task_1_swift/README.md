# 5.1. JSON → Graphviz DOT на Swift

Программа преобразует JSON-описание ориентированного графа в DOT. Проверяются уникальность идентификаторов и ссылки рёбер на вершины. Кавычки и обратные слеши экранируются.

## Запуск

Требуются Docker Desktop и Linux-компилятор Swift 5.10.1 для Ubuntu 22.04, распакованный на этом компьютере в `E:\prog\npl-labs-tools\swift-5.10.1`.

Из корня репозитория в PowerShell:

```powershell
cd 5_convert/task_1_swift
New-Item -ItemType Directory -Force build | Out-Null
docker build -t npl-dot .
$swift = 'E:\prog\npl-labs-tools\swift-5.10.1\swift-5.10.1-RELEASE-ubuntu22.04'
docker run --rm --mount "type=bind,source=$swift,target=/toolchain,readonly" --mount "type=bind,source=$($PWD.Path),target=/data" npl-dot /data/examples/graph.json /data/build/graph.dot
Get-Content -Encoding utf8 build/graph.dot
```

Аргументы — входной JSON и выходной DOT. Массив `nodes` содержит объекты с полями `id`, `label`, массив `edges` — объекты с полями `from`, `to`. Все поля — строки.
