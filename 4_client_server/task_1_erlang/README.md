# 4.1. Сервер бронирования временных интервалов на Erlang

TCP-сервер создаёт, показывает и отменяет бронирования. Пересекающиеся интервалы одного ресурса запрещены, соприкасающиеся границы разрешены. Состояние хранится в памяти и изменяется одним процессом Erlang.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 4_client_server/task_1_erlang
docker build -t npl-booking .
docker run --rm --name npl-booking -p 127.0.0.1:5001:5001 npl-booking server 5001
```

В другом терминале:

```powershell
docker exec npl-booking escript main.escript client 5001 "BOOK room1 10 20"
docker exec npl-booking escript main.escript client 5001 "LIST room1"
docker exec npl-booking escript main.escript client 5001 "CANCEL 1"
```

Границы интервала — целые неотрицательные отметки времени, начало меньше конца. В `LIST` каждая бронь представлена как `id:начало:конец`. Имена ресурсов задаются без пробелов. Сервер останавливается через Ctrl+C.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/1E2O9IrM-3unmSsp_UckNYUnDzQladqWI/view?usp=sharing)
