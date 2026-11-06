#!/bin/sh
set -eu

python3 /usr/local/bin/render_config.py
exec "$@"
