FROM nginx:1.27-bookworm
ARG UID=1001
ARG GID=1001
RUN groupadd -g $GID clp && \
    useradd -u $UID -g clp -s /bin/bash test-ssh
COPY nginx.conf /etc/nginx/nginx.conf
COPY vhost.conf /etc/nginx/conf.d/test.dyna.com.conf
COPY certs/ /etc/nginx/certs/
# Change nginx worker process user
RUN sed -i 's/user nginx/user test-ssh/' /etc/nginx/nginx.conf
