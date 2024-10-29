# Prepare web release
FROM nginx:alpine

ENV PARSE_URL parseUrl

# Copy the config files
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./entrypoint.sh /usr/share/nginx/entrypoint.sh
# Clears the static files
RUN rm -rf /usr/share/nginx/html
# Copy the static web content
ADD ./build/web /usr/share/nginx/html

# Expose server
EXPOSE 80/tcp

ENTRYPOINT ["/usr/share/nginx/entrypoint.sh"]