#!/bin/sh -eu
chmod -R 755 /usr/share/nginx/html/assets

echo PARSE_URL=$PARSE_URL | tee /usr/share/nginx/html/assets/stack.env

nginx -g "daemon off;"