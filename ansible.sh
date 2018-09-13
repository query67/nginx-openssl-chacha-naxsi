#!/bin/bash
#Custom script for update with Ansible


#Cleaning old sources
cd /usr/src
rm -rf nginx*
rm -rf openssl*


#Download Latest nginx, nasxsi & OpenSSL, then extract.
latest_nginx=$(curl -L http://nginx.org/en/download.html | egrep -o "nginx\-[0-9.]+\.tar[.a-z]*" | head -n 1)
git clone https://github.com/openssl/openssl.git --branch OpenSSL_1_1_1-stable
git clone https://github.com/hakasenyang/openssl-patch.git
cd openssl
patch -p1 < ../openssl-patch/openssl-equal-1.1.1_ciphers.patch
cd /usr/src
(curl -fLRO "http://nginx.org/download/${latest_nginx}" && tar -xaf "${latest_nginx}") &
(curl -fLRO "https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz" && tar -xaf "v0.33.tar.gz") &


#Cleaning
rm /usr/src/*.tar.gz

#Patch OpenSSL
latest_openssl=$(echo openssl-1.1.0*)
cd "${latest_openssl}"


#Dynamic TLS Records
cd /usr/src
cd nginx-*
wget https://raw.githubusercontent.com/cujanovic/nginx-dynamic-tls-records-patch/master/nginx__dynamic_tls_records_1.13.0%2B.patch
patch -p1 < nginx__dynamic_tls_records_1.13.0+.patch

#Configure NGINX & make & install
./config
./configure \
--http-client-body-temp-path=/usr/local/etc/nginx/body \
--http-fastcgi-temp-path=/usr/local/etc/nginx/fastcgi \
--http-proxy-temp-path=/usr/local/etc/nginx/proxy \
--http-scgi-temp-path=/usr/local/etc/nginx/scgi \
--http-uwsgi-temp-path=/usr/local/etc/nginx/uwsgi \
--user=www-data \
--group=www-data \
--prefix=/etc/nginx \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--with-pcre-jit \
--with-http_v2_module \
--with-debug \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_dav_module \
--with-http_gzip_static_module \
--with-http_sub_module \
--with-http_xslt_module \
--with-file-aio \
--with-threads \
--with-http_ssl_module \
--with-http_geoip_module \
--add-module=../headers-more-nginx-module-0.33 \
--with-openssl=/usr/src/${latest_openssl} \
--with-openssl-opt=enable-tls1_3 \
--with-ld-opt=-lrt \

make -j $(nproc)
make install

service nginx stop
service nginx start
