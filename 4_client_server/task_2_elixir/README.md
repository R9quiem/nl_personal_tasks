# 4.2. Сервер RLE-сжатия на Elixir

TCP-сервер сжимает и восстанавливает байты методом RLE. Сжатые данные состоят из пар байтов «число повторений от 1 до 255, значение». Более длинные серии разбиваются на несколько пар.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 4_client_server/task_2_elixir
docker build -t npl-rle .
docker run --rm --name npl-rle -p 127.0.0.1:5002:5002 npl-rle server 5002
```

В другом терминале:

```powershell
docker exec npl-rle elixir main.exs client 5002 "COMPRESS AAAABB"
docker exec npl-rle elixir main.exs client 5002 "DECOMPRESS 02AA01BB"
docker exec npl-rle elixir main.exs client 5002 "COMPRESS"
```

Данные задаются шестнадцатеричной строкой без пробелов. Первые два примера возвращают `OK 02AA01BB` и `OK AAAABB`. Отсутствие данных обозначает пустую последовательность. Некорректные пары, нулевые счётчики и ошибочная hex-запись отклоняются. Сервер останавливается через Ctrl+C.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/12SjiylC7vmaV84IzmIfMhAG-G4KlQ8Mx/view?usp=sharing)
