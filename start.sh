#!/bin/bash

# Ensure /app/data exists (Cloudron writable directory)
mkdir -p /app/data

# Generate SECRET_KEY_BASE only if not already set
if [ ! -f /app/data/.secret ]; then
  head -c 48 /dev/urandom | base64 > /app/data/.secret
fi

export SECRET_KEY_BASE=$(cat /app/data/.secret)

# Start Keila with Cloudron-friendly settings
exec /app/code/keila/bin/keila start
