# 4.3. Сервер аренды ресурсов на Groovy

TCP-сервер хранит состояние ресурсов `camera`, `laptop`, `projector`. Клиент может получить список, арендовать свободный ресурс и вернуть ресурс на своё имя. Проверка владельца и изменение состояния выполняются в синхронизированном блоке.

## Запуск

Требуется Docker Desktop с Linux-контейнерами. Из корня репозитория в PowerShell:

```powershell
cd 4_client_server/task_3_groovy
docker build -t npl-rental .
docker run --rm --name npl-rental -p 127.0.0.1:5003:5003 npl-rental server 5003
```

В другом терминале:

```powershell
docker exec npl-rental groovy main.groovy client 5003 "LIST"
docker exec npl-rental groovy main.groovy client 5003 "RENT camera alice"
docker exec npl-rental groovy main.groovy client 5003 "RETURN camera alice"
```

Имя клиента передаётся в команде и состоит из латинских букв, цифр, `_` и `-`. Вернуть ресурс можно только с именем текущего владельца. `LIST` возвращает JSON, где `null` обозначает свободный ресурс. Данные хранятся в памяти. Сервер останавливается через Ctrl+C.

## Видео с объяснением

[Посмотреть видео](https://drive.google.com/file/d/1qOvSDNHhVWW72CK95vMBj_qwd4UJx5bB/view?usp=sharing)
