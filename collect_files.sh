#!/bin/bash
if [ "$#" -lt 2 ]; then
    echo "Использование: $0 <input_dir> <output_dir> [--max_depth <n>]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
MAX_DEPTH=""
if [ "$3" = "--max_depth" ]&&[ -n "$4" ]; then
    MAX_DEPTH="--max_depth \$4"
fi
mkdir -p "$OUTPUT_DIR"
python3 -c "
import os, sys, shutil
from pathlib import Path
input_dir = '$INPUT_DIR'
output_dir = '$OUTPUT_DIR'
max_depth = ${4:-'-1'} 
def get_depth(path, base_path):
    rel_path = os.path.relpath(path, base_path)
    if rel_path == '.':
        return 0
    return len(rel_path.split(os.sep))
if max_depth >= 0:
    for root, dirs, files in os.walk(input_dir):
        depth = get_depth(root, input_dir)
        if depth <= max_depth:
            rel_path = os.path.relpath(root, input_dir)
            if rel_path != '.':
                os.makedirs(os.path.join(output_dir, rel_path), exist_ok=True)

for root, dirs, files in os.walk(input_dir):
    for file in files:
        src_file = os.path.join(root, file)
        depth = get_depth(root, input_dir)
        
        if max_depth < 0 or depth <= max_depth:
            rel_path = os.path.relpath(root, input_dir)
            dst_dir = output_dir if rel_path == '.' else os.path.join(output_dir, rel_path)
        else:
            parts = os.path.relpath(root, input_dir).split(os.sep)[:max_depth]
            dst_dir = os.path.join(output_dir, *parts)
        
        os.makedirs(dst_dir, exist_ok=True)
        dst_file = os.path.join(dst_dir, file)
        
        if os.path.exists(dst_file):
            name, ext = os.path.splitext(file)
            counter = 1
            while os.path.exists(os.path.join(dst_dir, f'{name}{counter}{ext}')):
                counter += 1
            dst_file = os.path.join(dst_dir, f'{name}{counter}{ext}')
        
        shutil.copy2(src_file, dst_file)
"

echo "Копирование завершено."
