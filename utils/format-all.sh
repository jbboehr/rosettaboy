#!/usr/bin/env bash
set -eu

cd $(dirname $0)/..
for n in */format.sh ; do
    $n
done
