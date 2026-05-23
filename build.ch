#!/bin/bash

TARGET="ldp_matrix"
SOURCE="ldp_matrix.c"

echo "============================================================"
echo "  Compiling ldp-matrix Production Engine Layer..."
echo "============================================================"

if [ ! -f "$SOURCE" ]; then
    echo "[-] Error: Source file $SOURCE not found."
    exit 1
fi

clang -O2 "$SOURCE" -o "$TARGET"

if [ $? -eq 0 ]; then
    echo "[+] Compilation successful: ./$TARGET"
    echo "[+] Running automated execution pipeline..."
    echo "------------------------------------------------------------"
    ./"$TARGET"
else
    echo "[-] Error: Compilation failed. Verify compiler tools."
    exit 1
fi
