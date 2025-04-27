#!/bin/bash

# Cloudron: Generate and persist SECRET_KEY_BASE if not set
SECRET_FILE="/app/data/.secret"

if [ -z "${SECRET_KEY_BASE}" ] && [ ! -f "${SECRET_FILE}" ]; then
    echo "Generating new SECRET_KEY_BASE"
    SECRET_KEY_BASE=$(head -c 64 /dev/urandom | base64 | tr -d '\n')
    echo "export SECRET_KEY_BASE=${SECRET_KEY_BASE}" > "${SECRET_FILE}"
fi

# Source persisted secret if available
[ -f "${SECRET_FILE}" ] && source "${SECRET_FILE}"

# Start Keila with Cloudron-friendly settings
exec /app/code/keila/bin/keila start
