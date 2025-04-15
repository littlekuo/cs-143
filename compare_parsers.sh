#!/bin/bash

LEXER="./bin/lexer"
PARSER1="./assignments/PA3/parser"   
PARSER2="./bin/parser"  


TEST_DIR="./examples"

# create output directory
OUT_DIR1="./tmp/parser1_out"
OUT_DIR2="./tmp/parser2_out"
mkdir -p "$OUT_DIR1" "$OUT_DIR2"

for file in "$TEST_DIR"/*; do
    [ -d "$file" ] && continue
    
    filename=$(basename "$file")
    echo "file: $filename"
    
    
    out1="$OUT_DIR1/${filename}.out"
    out2="$OUT_DIR2/${filename}.out"
    
    
    $LEXER  "$file" | $PARSER1 > "$out1" 2>&1
    $LEXER  "$file" | $PARSER2  > "$out2" 2>&1
    
    
    if diff "$out1" "$out2" >/dev/null; then
        echo -e "\033[32m the same \033[0m"  # means the same
    else
        echo -e "\033[31m different \033[0m"
        echo "差异内容："
        diff --color=always "$out1" "$out2"
        echo "----------------------------------------"
    fi
done
rm -rf "$OUT_DIR1" "$OUT_DIR2"
