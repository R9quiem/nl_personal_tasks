# 2.2. Поиск мостов в графе на OCaml

Программа рекурсивным обходом в глубину находит все мосты неориентированного графа, включая несвязный. Петли и повторяющиеся рёбра отклоняются.

## Запуск

Требуется OCaml. Команды выполняются из корня репозитория в PowerShell.

```powershell
cd 2_algorithms/task_2_ocaml
New-Item -ItemType Directory -Force build | Out-Null
ocamlc -c -o build/main.cmo main.ml
ocamlc -o build/bridges.exe build/main.cmo
.\build\bridges.exe examples/sample.txt
```

Аргумент — путь к текстовому файлу. В начале задаются число вершин `n` и число рёбер `m`, затем `m` пар индексов вершин от `0` до `n - 1`. Все числа разделяются пробельными символами. Вывод содержит число мостов и их пары вершин.

Запуск через Docker из папки лабораторной:

```powershell
docker build -t npl-bridges .
docker run --rm npl-bridges examples/sample.txt
```

Для своего файла в текущей папке:

```powershell
docker run --rm --mount "type=bind,source=$($PWD.Path),target=/data,readonly" npl-bridges /data/input.txt
```
