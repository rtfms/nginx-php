#!/bin/bash -x
if [ ! -f "/etc/nginx/nginx.conf" ]; then
  cp /files/nginx.conf /etc/nginx/nginx.conf
fi
if [ ! -f "/usr/local/etc/php-fpm.conf" ]; then
  cp /files/php-fpm.conf /usr/local/etc/php-fpm.conf
fi

php-fpm&
nginx -g "daemon off;"
