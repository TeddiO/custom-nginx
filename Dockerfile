FROM alpine

ARG version=1.16.1
ARG unixgroup=1000

RUN apk add --no-cache unzip bash gcc make pcre build-base pcre-dev openssl openssl-dev zlib zlib-dev

RUN addgroup -g ${unixgroup} -S www-data \
	&& adduser -u ${unixgroup} -D -S -G www-data www-data

RUN wget https://nginx.org/download/nginx-${version}.tar.gz && \
    tar -xf nginx-${version}.tar.gz && \
    rm nginx-${version}.tar.gz && \
    wget https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/master.zip -O subs.zip && \
	unzip subs.zip && \
	rm subs.zip && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/master.zip && \
    unzip master.zip && \
    rm master.zip

WORKDIR nginx-${version}
RUN ./configure --add-module=/ngx_http_substitutions_filter_module-master \
    --add-module=/headers-more-nginx-module-master \
    --prefix=/usr/share/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --user=www-data \
    --group=www-data \
    --with-compat \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_v2_module \
    --with-stream_ssl_preread_module \
    --with-stream_ssl_module \
    --with-http_auth_request_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_sub_module 

RUN make install && \
    apk del unzip gcc make build-base pcre-dev zlib zlib-dev && \
    rm -R /headers-more-nginx-module-master /ngx_http_substitutions_filter_module-master

CMD ["nginx", "-g" ,"daemon off;"]
