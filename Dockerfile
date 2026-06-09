FROM alpine:3.23 AS build

ARG version=1.30.2
ARG opensslversion=3.5.6
ARG zlibversion=1.3.2

RUN apk add --no-cache unzip bash gcc make pcre2 build-base pcre2-dev pcre2-static perl-dev linux-headers curl

RUN wget https://nginx.org/download/nginx-${version}.tar.gz && \
    tar -xf nginx-${version}.tar.gz && \
    wget https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/master.zip -O subs.zip && \
    unzip subs.zip && \
    wget https://github.com/openresty/headers-more-nginx-module/archive/master.zip && \
    unzip master.zip && \
    wget https://github.com/openssl/openssl/releases/download/openssl-${opensslversion}/openssl-${opensslversion}.tar.gz && \
    tar -xf openssl-${opensslversion}.tar.gz && \
    wget https://github.com/madler/zlib/releases/download/v${zlibversion}/zlib-${zlibversion}.tar.gz && \
    tar -xf zlib-${zlibversion}.tar.gz

WORKDIR /nginx-${version}

RUN extra_cc_opt=""; \
    if [ "$(printf '%s\n' "$version" "1.28.3" | sort -V | head -n1)" = "$version" ] && [ "$version" != "1.28.3" ]; then \
        extra_cc_opt="-Wno-error=unterminated-string-initialization"; \
    fi; \
    ./configure --with-cc-opt="-static -static-libgcc ${extra_cc_opt}" \
    --with-ld-opt="-static" \
    --with-zlib=../zlib-${zlibversion} \
    --add-module=/ngx_http_substitutions_filter_module-master \
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
    --with-http_sub_module \
    --with-openssl=../openssl-${opensslversion}

RUN make install

FROM scratch

COPY --from=build /usr/sbin/nginx . 
COPY --from=build /usr/share/nginx /usr/share/nginx
COPY etc /etc
# These are just some minor hacks
COPY .empty /usr/share/
COPY .empty /var/run/
COPY .empty /var/lock/

ENTRYPOINT ["./nginx", "-g" ,"daemon off;"]
