#!/bin/bash
if [[ "$#" -lt 2 ]]; then
    echo "Использование: $0 /путь/к/входной_директории /путь/к/выходной_директории [--max_depth число]"
    exit 1
fi
input_dir="$1"
output_dir="$2"
max_depth=-1 
if [[ "$#" -gt 2 && "$3" == "--max_depth" && "$4" =~ ^[0-9]+$ ]]; then
    max_depth=\$4
fi
if [[ ! -d "$input_dir" ]]; then
    echo "Ошибка: входная директория не существует: $input_dir"
    exit 1
fi
mkdir -p "$output_dir"
copy_files() {
    local src="$1"
    local dst="$2"
    local current_depth="$3"
    local rel_path="${4:-}" 
    for item in "$src"/*; do
        if [[ ! -e "$item" ]]; then
            continue
        fi
        
        local item_name=$(basename "$item")
        
        if [[ -f "$item" ]]; then
            if [[ $max_depth -ge 0 && $current_depth -gt $max_depth ]]; then
                local target_dir="$output_dir/$rel_path"
                mkdir -p "$target_dir"
                if [[ -f "$target_dir/$item_name" ]]; then
                    local counter=1
                    local file_ext="${item_name##*.}"
                    local file_name="${item_name%.*}"
                    
                    if [[ "$file_name" == "$file_ext" ]]; then
                        file_ext=""
                    else
                        file_ext=".$file_ext"
                    fi
                    
                    local new_name="${file_name}${counter}${file_ext}"
                    while [[ -f "$target_dir/$new_name" ]]; do
                        ((counter++))
                        new_name="${file_name}${counter}${file_ext}"
                    done
                    cp "$item" "$target_dir/$new_name"
                else
                    cp "$item" "$target_dir/$item_name"
                fi
            else
                if [[ -f "$dst/$item_name" ]]; then
                    local counter=1
                    local file_ext="${item_name##*.}"
                    local file_name="${item_name%.*}"
                    
                    if [[ "$file_name" == "$file_ext" ]]; then
                        file_ext=""
                    else
                        file_ext=".$file_ext"
                    fi
                    
                    local new_name="${file_name}${counter}${file_ext}"
                    while [[ -f "$dst/$new_name" ]]; do
                        ((counter++))
                        new_name="${file_name}${counter}${file_ext}"
                    done
                    
                    cp "$item" "$dst/$new_name"
                else
                    cp "$item" "$dst/$item_name"
                fi
            fi
        elif [[ -d "$item" ]]; then
            if [[ $max_depth -lt 0 || $current_depth -lt $max_depth ]]; then
                local new_dst="$dst/$item_name"
                mkdir -p "$new_dst"
                local new_rel_path
                if [[ -z "$rel_path" ]]; then
                    new_rel_path="$item_name"
                else
                    new_rel_path="$rel_path/$item_name"
                fi
                copy_files "$item" "$new_dst" $((current_depth + 1)) "$new_rel_path"
            else
                mkdir -p "$dst/$item_name"
                find "$item" -type f -exec cp {} "$dst/$item_name/" \;
            fi
        fi
    done
}

copy_files "$input_dir" "$output_dir" 0
echo "Копирование завершено."

