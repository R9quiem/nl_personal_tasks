# 2.1. Рекурсивная генерация разбиений числа на Haskell

Программа рекурсивно выводит все разбиения натурального числа на положительные целые слагаемые и их общее количество. Перестановки слагаемых считаются одним разбиением.

## Запуск

Требуется GHC. Команды выполняются из корня репозитория в PowerShell.

```powershell
cd 2_algorithms/task_1_haskell
New-Item -ItemType Directory -Force build | Out-Null
ghc -O2 -outputdir build Main.hs -o build/partitions.exe
.\build\partitions.exe 4
```

Аргумент — положительное целое число. Для числа `4` выводятся пять разбиений и строка `Total: 5`.

Запуск через Docker из папки лабораторной:

```powershell
docker build -t npl-partitions .
docker run --rm npl-partitions 4
```
