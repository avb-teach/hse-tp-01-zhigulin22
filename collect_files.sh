#!/bin/bash
if [ "$#" -lt 2 ]; then
    echo "Использование: $0 <input_dir> <output_dir> [--max_depth <n>]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_DEPTH=-1
if [ "$3" = "--max_depth" ] && [ "$4" -ge 0 ] 2>/dev/null; then
    MAX_DEPTH="\$4"
fi
if [ ! -d "$INPUT_DIR" ]; then
    echo "Ошибка: входная директория не существует"
    exit 1
fi
mkdir -p "$OUTPUT_DIR"
get_depth() {
    local path="$1"
    local base="$2"
    local rel_path="${path#$base}"
    rel_path="${rel_path#/}"
    if [ -z "$rel_path" ]; then
        echo 0
    else
        echo "$rel_path" | awk -F'/' '{print NF}'
    fi
}
create_dirs() {
    if [ "$MAX_DEPTH" -lt 0 ]; then
        return
    fi
    
    find "$INPUT_DIR" -type d | while read -r dir; do
        depth=$(get_depth "$dir" "$INPUT_DIR")
        if [ "$depth" -le "$MAX_DEPTH" ]; then
            rel_path="${dir#$INPUT_DIR}"
            [ -z "$rel_path" ] && continue
            mkdir -p "$OUTPUT_DIR$rel_path"
        fi
    done
}
process_files() {
    find "$INPUT_DIR" -type f | while read -r file; do
        rel_path="${file#$INPUT_DIR}"
        file_name=$(basename "$file")
        dir_path=$(dirname "$rel_path")
        depth=$(get_depth "$file" "$INPUT_DIR")
        
        if [ "$MAX_DEPTH" -lt 0 ] || [ "$depth" -le "$MAX_DEPTH" ]; then
            target_dir="$OUTPUT_DIR$dir_path"
        else
            allowed_path=$(echo "$dir_path" | cut -d'/' -f1-$MAX_DEPTH)
            target_dir="$OUTPUT_DIR$allowed_path"
        fi
        
        mkdir -p "$target_dir"
        if [ -f "$target_dir/$file_name" ]; then
            name="${file_name%.*}"
            ext="${file_name##*.}"
            if [ "$name" = "$ext" ]; then
                ext=""
            else
                ext=".$ext"
            fi
            
            counter=1
            while [ -f "$target_dir/$name$counter$ext" ]; do
                counter=$((counter+1))
            done
            
            cp "$file" "$target_dir/$name$counter$ext"
        else
            cp "$file" "$target_dir/$file_name"
        fi
    done
}
create_dirs
process_files
echo "Копирование завершено."
