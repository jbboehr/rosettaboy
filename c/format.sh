#!/usr/bin/env bash
set -eu

cd $(dirname $0)
if command -v clang-format-14 &> /dev/null ; then
    CMD=clang-format-14
else
    CMD=clang-format
fi
$CMD -i $(find src -type f) --ferror-limit 10 -Werror
