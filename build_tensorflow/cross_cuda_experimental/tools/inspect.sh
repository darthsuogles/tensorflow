#!/bin/bash

set -eu

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_random_text="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

pushd "${_bsd_}/.."
bazel build --action_env="PLATFORM_RESTART_FLAG=${_random_text}" //src:inspect
popd
