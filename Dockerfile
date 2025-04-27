# Build stage

# original from Keila will not work on Ubuntu
#FROM elixir:1.15-alpine AS build
# so instead, build this...
FROM elixir:1.15-slim AS build
ENV MIX_ENV=prod PORT=4000
# This Alpine command won't work on Ubuntu
#RUN apk add --no-cache build-base npm cmake erlang-dev
# So install the same via Debian dependencies (apt-get instead of apk)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    nodejs \
    npm \
    cmake \
    erlang-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY mix.exs mix.lock ./
COPY config config
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile
COPY assets assets
RUN npm install --prefix assets && \
    mix assets.deploy
COPY lib lib
COPY priv priv
RUN mix compile && \
    mix release

# Final stage - Cloudron-specific
# Cloudron base image
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

# Cloudron-specific environment setup
# Set locale
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8
    MIX_ENV=prod \
    PORT=4000

# Cloudron expects apps in /app/code
WORKDIR /app/code
COPY --from=build /app/_build/prod/rel/keila /app/code/keila

# Copy artifacts with Cloudron conventions
COPY --from=build /app/_build/prod/rel/keila ./_build/prod/rel/keila
COPY --from=build /app/priv ./priv
COPY --from=build /app/config ./config
COPY --from=build /app/mix.exs ./mix.exs
COPY --from=build /app/mix.lock ./mix.lock

# Conditional copy with explicit paths
# rel not needed
# COPY --from=build /app/rel ./rel
COPY --from=build /app/lib ./lib

# Copy start script and make executable
COPY start.sh /app/code/start.sh
RUN chmod +x /app/code/start.sh

# Cloudron DB credentials
ENV CLOUDRON_POSTGRESQL_URL=postgresql://cloudron:cloudron@postgres/keila
ENV POSTGRESQL_URL=${CLOUDRON_POSTGRESQL_URL}

# Cloudron-provided SMTP variables to app-expected variables

ENV MAILER_SMTP_HOST=${CLOUDRON_MAIL_SMTP_SERVER}
ENV MAILER_SMTP_USER=${CLOUDRON_MAIL_SMTP_USERNAME}
ENV MAILER_SMTP_PASSWORD=${CLOUDRON_MAIL_SMTP_PASSWORD}
ENV MAILER_SMTP_PORT=${CLOUDRON_MAIL_SMTP_PORT}
ENV MAILER_SMTP_FROM_EMAIL=${CLOUDRON_MAIL_FROM}

EXPOSE ${PORT}
# Use start.sh as entrypoint
CMD ["/app/code/start.sh"]
