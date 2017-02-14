FROM alpine:3.5

WORKDIR /app

COPY . .

# Run Mix in production mode.
ENV MIX_ENV prod

RUN \
    # Upgrade old packages.
    apk --update upgrade && \
    # Ensure we have ca-certs installed.
    apk add --no-cache ca-certificates && \
    # Install build packages.
    apk add --virtual build-packages nodejs-current && \
    # Install runtime packages.
    apk add --virtual runtime-packages elixir erlang-crypto erlang-parsetools erlang-syntax-tools && \
    # Install rebar and hex.
    mix local.rebar --force && \
    mix local.hex --force && \
    # Install backend dependencies.
    mix deps.get --force --only-prod && \
    # Install frontend dependencies.
    npm install && \
    # Compile application.
    mix compile && \
    # Build frontend assets.
    npm run deploy && \
    mix phoenix.digest && \
    # Clean up build packages.
    apk del --purge build-packages && \
    # Delete APK caches.
    find / -type f -iname \*.apk-new -delete && \
    rm -rf /var/cache/apk/* && \
    # Yay!
    echo "Build complete!"

ENTRYPOINT mix phoenix.server
