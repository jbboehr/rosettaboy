#!/usr/bin/env bash
set -eu

cd $(dirname $0)
nimble --accept build -d:release
cp ./rosettaboy ./rosettaboy-release