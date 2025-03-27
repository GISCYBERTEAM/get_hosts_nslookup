## Информация / Information

Скрипт для быстрого вывода перечня хостов в тестируемой инфраструктуре через запросы на DNS-сервер.

## Подготовка и запуск / Preparation and launch

Перед запуском предварительно необходимо выполнить команду:

```
chmod +x get_hosts_nslookup.sh
```

После этого необходимо выполнить команду указав в качестве аргумента сеть и маску. Пример команды ниже

```
./get_hosts_nslookup.sh 192.168.0.0/24
```

## Пример работы / Example of work

```
./get_hosts_nslookup.sh 192.168.0.0/24

┌──────────────────────────────────────────────────────┐
│ Сканирование сети: 192.168.0.0/24
│ Диапазон: 192.168.0.0 - 192.168.0.255
│ Всего IP-адресов: 254
├──────────────────────────────────────────────────────┤
│ Прогресс: 7% [20/254] Найдено: 0 Скорость: 20 IP/сек Время: 1 сек
│ Прогресс: 54% [139/254] Найдено: 1 Скорость: 19 IP/сек Время: 7 сек
│ Прогресс: 100% [254/254] Найдено: 2 Скорость: 18 IP/сек Время: 14 сек
├──────────────────────────────────────────────────────┤
│ Сканирование завершено! Найдено: 2 хостов │
└──────────────────────────────────────────────────────┘

Полный список найденных хостов:
IP              FQDN
---------------- ---------------
192.168.0.20    Mac
192.168.0.139   iPhone
```

