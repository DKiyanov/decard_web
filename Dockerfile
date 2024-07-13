# Prepare web release
FROM plugfox/flutter:3.3.10-web AS build

ENV PARSE_URL parseUrl

# USER root
WORKDIR /home

# Copy app source code and compile it
COPY --chown=101:101 . client

RUN set -eux; \
    # Change directory to client for monorepo
    cd client \
    # Ensure packages are still up-to-date if anything has changed
    && flutter pub get \
    # Codegeneration
    #&& flutter pub run build_runner build --delete-conflicting-outputs --release \
    # Localization
    #&& flutter pub global run intl_utils:generate
    # Build web release (opt --tree-shake-icons)
    && flutter build web --dart-define PARSE_URL=$PARSE_URL --release --no-source-maps \
        --pwa-strategy offline-first \
        --web-renderer auto --base-href /

# Production from scratch
FROM nginx:alpine as production

COPY --from=build --chown=101:101 /home/client/build/web /usr/share/nginx/html
COPY --from=build --chown=101:101 /home/client/nginx.conf /etc/nginx/nginx.conf
COPY --from=build --chown=101:101 /home/client/entrypoint.sh /usr/share/nginx/entrypoint.sh

# Expose server
EXPOSE 80/tcp

ENTRYPOINT ["/usr/share/nginx/entrypoint.sh"]