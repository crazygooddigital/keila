#!/bin/bash

# Verify that this script is executable; if not, set permissions
if [ ! -x "$0" ]; then
  chmod +x "$0"
fi

# Ensure required directories exist
mkdir -p /app/data/uploads

# Generate SECRET_KEY_BASE only if not already set
[[ ! -f /app/data/.secret ]] && head -c 48 /dev/urandom | base64 > /app/data/.secret
export SECRET_KEY_BASE=$(cat /app/data/.secret)

# Set Cloudron admin credentials (using Cloudron's default email format)
export KEILA_USER="${CLOUDRON_MAIL_FROM:-admin@${CLOUDRON_APP_DOMAIN}}"
export KEILA_PASSWORD="${CLOUDRON_APP_ADMIN_PASSWORD:-admin}"

# Set remaining Cloudron-specific variables
export URL_SCHEMA="https"
export URL_HOST="${CLOUDRON_APP_DOMAIN}"
export DB_URL="${CLOUDRON_POSTGRESQL_URL}"
export USER_CONTENT_DIR="/app/data/uploads"

# Configure Captcha using Cloudron env vars if available
export CAPTCHA_SITE_KEY="${CLOUDRON_CAPTCHA_SITE_KEY}"
export CAPTCHA_SECRET_KEY="${CLOUDRON_CAPTCHA_SECRET_KEY}"
export CAPTCHA_PROVIDER="${CLOUDRON_CAPTCHA_PROVIDER:-hcaptcha}"

# Make sure PostgreSQL is ready
until pg_isready -h $CLOUDRON_POSTGRESQL_HOST -p $CLOUDRON_POSTGRESQL_PORT;
do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

# Start Keila
exec /app/code/keila/bin/keila start

