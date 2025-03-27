#!/bin/bash

# Проверка аргументов
if [ "$#" -ne 1 ]; then
    echo -e "\033[1;31mОшибка: Необходимо указать сеть и маску\033[0m"
    echo "Пример использования: $0 192.168.1.0/24"
    exit 1
fi

# Парсинг аргумента
network=$(echo "$1" | cut -d'/' -f1)
mask=$(echo "$1" | cut -d'/' -f2)

# Проверка валидности маски
if ! [[ "$mask" =~ ^[0-9]+$ ]] || [ "$mask" -lt 0 ] || [ "$mask" -gt 32 ]; then
    echo -e "\033[1;31mОшибка: Некорректная маска сети (должна быть 0-32)\033[0m"
    exit 1
fi

# Функции преобразования IP
ip_to_int() {
    local ip="$1"
    local a b c d
    IFS=. read -r a b c d <<< "$ip"
    echo "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

int_to_ip() {
    local int="$1"
    echo "$(( (int >> 24) % 256 )).$(( (int >> 16) % 256 )).$(( (int >> 8) % 256 )).$(( int % 256 ))"
}

# Вычисление диапазона
ip_int=$(ip_to_int "$network")
start_ip=$((ip_int & (0xFFFFFFFF << (32 - mask))))
end_ip=$((start_ip + (1 << (32 - mask)) - 1))
total_ips=$((end_ip - start_ip - 1)) # -2 для network/broadcast

# Переменные для статистики
found_hosts=0
current=0
start_time=$(date +%s)
found_list=()  # Массив для хранения найденных хостов

# Функция для очистки строки статуса
clear_line() {
    printf "\033[2K\r"
}

# Начальный вывод информации
echo -e "\033[1;36m┌──────────────────────────────────────────────────────┐\033[0m"
echo -e "\033[1;36m│ Сканирование сети: \033[1;33m$network/$mask\033[0m"
echo -e "\033[1;36m│ Диапазон: \033[0m$(int_to_ip $start_ip) - $(int_to_ip $end_ip)"
echo -e "\033[1;36m│ Всего IP-адресов: \033[0m$total_ips"
echo -e "\033[1;36m├──────────────────────────────────────────────────────┤\033[0m"

# Функция обновления статистики
update_stats() {
    local elapsed=$(( $(date +%s) - start_time ))
    local speed=0
    [ $elapsed -gt 0 ] && speed=$(( current / elapsed ))
    
    clear_line
    printf "\033[1;36m│ Прогресс: \033[1;33m%d%%\033[0m [\033[1;33m%d\033[0m/$total_ips] " $(( current*100/total_ips )) $current
    printf "Найдено: \033[1;32m%d\033[0m " $found_hosts
    printf "Скорость: \033[1;33m%d\033[0m IP/сек " $speed
    printf "Время: \033[1;33m%d\033[0m сек\033[0m" $elapsed
}

# Функция получения FQDN
get_fqdn() {
    local ip="$1"
    nslookup "$ip" 2>/dev/null | awk -F'name = ' '/name =/{print $2}' | sed 's/\.$//'
}

# Основной цикл сканирования
for ((i = start_ip+1; i < end_ip; i++)); do
    current=$((i - start_ip))
    ip=$(int_to_ip "$i")
    
    # Получаем FQDN
    hostname=$(get_fqdn "$ip")
    
    # Обновляем статистику каждые 10 IP или при нахождении хоста
    if [ $((current % 10)) -eq 0 ] || [ -n "$hostname" ]; then
        update_stats
    fi
    
    # Если хост найден, добавляем в массив
    if [ -n "$hostname" ]; then
        found_hosts=$((found_hosts + 1))
        found_list+=("$ip $hostname")
        echo -e "\n  \033[1;32m✓\033[0m \033[34m$ip\033[0m \033[1;33m$hostname\033[0m"
        tput cuu1  # Возвращаем курсор на строку вверх
    fi
done

# Финальный вывод статистики
update_stats
echo -e "\033[1;36m\033[0m"
echo -e "\033[1;36m├──────────────────────────────────────────────────────┤\033[0m"
echo -e "\033[1;36m│ Сканирование завершено! Найдено: \033[1;32m$found_hosts\033[0m хостов\033[1;36m │\033[0m"
echo -e "\033[1;36m└──────────────────────────────────────────────────────┘\033[0m"

# Вывод полного списка найденных хостов
if [ $found_hosts -gt 0 ]; then
    echo -e "\n\033[1;34mПолный список найденных хостов:\033[0m"
    printf "\033[1;32m%-15s %s\033[0m\n" "IP" "FQDN"
    echo "---------------- ---------------"
    for host in "${found_list[@]}"; do
        printf "\033[36m%-15s \033[1;33m%s\033[0m\n" $host
    done
else
    echo -e "\n\033[1;33mХосты не найдены.\033[0m"
fi