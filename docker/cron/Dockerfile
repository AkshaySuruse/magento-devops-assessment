FROM php:8.3-cli-bookworm
# Same extensions as PHP-FPM image
ARG UID=1001
ARG GID=1001
RUN groupadd -g $GID clp && \
    useradd -u $UID -g clp -s /bin/bash test-ssh
COPY --from=builder --chown=test-ssh:clp /var/www/html /var/www/html
USER test-ssh
WORKDIR /var/www/html
CMD ["/bin/bash", "-c", \
  "while true; do php bin/magento cron:run; sleep 60; done"]
