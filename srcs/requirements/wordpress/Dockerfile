FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y wget

RUN mkdir /var/www
RUN apt-get install -y php8.2 php8.2-fpm php8.2-mysql

RUN apt-get install -y mariadb-client && apt install curl -y

COPY ./tools/start.sh /
RUN chmod +x start.sh

CMD ["/start.sh"]