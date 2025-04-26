#!/bin/bash
Проверка количества аргументов
if [[ "$#" -lt 2 ]]; then
echo "Использование: $0 /путь/к/входной_директории /путь/к/выходной_директории [--max_depth число]"
exit 1
fi
input_dir="$1"
output_dir="$2"
max_depth=-1  # По умолчанию неограниченная глубина
Обработка дополнительного параметра --max_depth
if [[ "$#" -gt 2 && "$3" == "--max_depth" && "$4" =~ ^[0-9]+$ ]]; then
max_depth=$4
fi
Проверка существования директорий
if [[ ! -d "$input_dir" ]]; then
echo "Ошибка: входная директория не существует: $input_dir"
exit 1
fi
Создание выходной директории, если она не существует
mkdir -p "$output_dir"
Функция для копирования файлов
copy_files() {
local src="$1"
local dst="$2"
local current_depth="$3"
# Проверка глубины, если задан --max_depth
if [[ $max_depth -ge 0 && $current_depth -gt $max_depth ]]; then
    return
fi


# Перебор всех файлов и директорий в текущей директории
for item in "$src"/*; do
    if [[ -f "$item" ]]; then
        # Это файл - копируем его
        base_name=$(basename "$item")
        
        # Обработка дубликатов имен файлов
        if [[ -f "$dst/$base_name" ]]; then
            # Файл с таким именем уже существует
            counter=1
            new_name="${base_name%.*}${counter}.${base_name##*.}"
            
            # Ищем свободное имя
            while [[ -f "$dst/$new_name" ]]; do
                ((counter++))
                new_name="${base_name%.*}${counter}.${base_name##*.}"
            done
            
            cp "$item" "$dst/$new_name"
        else
            cp "$item" "$dst/$base_name"
        fi
    elif [[ -d "$item" ]]; then
        # Это директория
        if [[ $max_depth -ge 0 && $current_depth -lt $max_depth ]]; then
            # Создаем поддиректорию в выходной директории
            subdir_name=$(basename "$item")
            mkdir -p "$dst/$subdir_name"
            
            # Копируем файлы из поддиректории
            copy_files "$item" "$dst/$subdir_name" $((current_depth + 1))
        else
            # Рекурсивно обрабатываем директорию
            copy_files "$item" "$dst" $((current_depth + 1))
        fi
    fi
done


}
Запуск копирования файлов, начиная с глубины 0
copy_files "$input_dir" "$output_dir" 0
echo "Копирование завершено."
