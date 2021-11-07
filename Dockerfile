FROM php:7.4-fpm

LABEL maintainer="Andrey Mikhalchuk <andrey@mikhalchuk.com>"

ENV NGINX_VERSION=1.21.3

COPY files /

RUN apt-get --allow-releaseinfo-change update && apt-get install -y procps telnet
COPY files/php.ini /usr/local/etc/php/
RUN addgroup --system --gid 101 nginx && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libgl-dev \
    webp \
    sendmail \
    vim \
    wget \
    curl \
    openssl \
    libssl-dev \
    libpcre3 \
    libpcre3-dev \
    libxml2-dev \
    libxslt1-dev \
    libgeoip-dev \
    libgd-dev \
    telnet \
    gcc
RUN mkdir -p /var/lib/nginx && \
    cd /tmp && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xzvf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --with-cc-opt='-g -O2 -fdebug-prefix-map=/build/nginx-Cjs4TR/nginx-${NGINX_VERSION}=. -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
        --sbin-path=/usr/sbin/nginx \
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --lock-path=/var/lock/nginx.lock \
        --pid-path=/var/run/nginx.pid \
        --modules-path=/usr/lib/nginx/modules \
        --http-client-body-temp-path=/var/lib/nginx/body \
        --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
        --http-proxy-temp-path=/var/lib/nginx/proxy \
        --http-scgi-temp-path=/var/lib/nginx/scgi \
        --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
        --with-debug \
        --with-pcre-jit \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_v2_module \
        --with-http_dav_module \
        --with-http_slice_module \
        --with-threads \
        --with-http_addition_module \
        --with-http_geoip_module=dynamic \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_image_filter_module=dynamic \
        --with-http_sub_module \
        --with-http_xslt_module=dynamic \
        --with-stream=dynamic \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-mail=dynamic \
        --with-mail_ssl_module \
        --with-http_sub_module \
        --with-http_flv_module \
        --with-http_mp4_module && \
    make && \
    make install && \
    cd .. &&\
    rm -rf nginx-${NGINX_VERSION}
RUN pecl install mcrypt-1.0.4
RUN mkdir -p /usr/local/etc/php/conf.d/ \
    && docker-php-ext-install -j$(nproc) mysqli iconv \
    && docker-php-ext-enable mysqli mcrypt \
    && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# install imagemagic
RUN apt-get update && apt-get install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN printf "\n" | pecl install imagick
RUN docker-php-ext-enable imagick

# install exif
RUN docker-php-ext-install exif

# install zip
RUN apt-get update && apt-get install -y \
        libzip-dev \
        zip \
  && docker-php-ext-install zip

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && chmod +x /start.sh

VOLUME [ "/var/log/nginx", "/var/log/php-fpm", "/www", "/etc/nginx" ]
EXPOSE 80 443

CMD ["/start.sh"]
