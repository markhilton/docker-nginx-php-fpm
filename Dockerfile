#
# nginx + pagespeed + substitutions + vhosts VTS + more headers + geoip 
# with php-fpm with lots of extensions base image build on Alpine Linux
# 
# credits: 
# - https://github.com/lagun4ik/docker-nginx-pagespeed
#


FROM php:7.0-fpm-alpine

MAINTAINER Mark Hilton <nerd305@gmail.com>

#
# --------------------------------------------------------------------------
# Install PHP-FPM
# --------------------------------------------------------------------------
#
RUN apk update && \
    apk add \
        gcc \
        g++ \
        git \
        re2c \
        curl \
        make \
        libtool \
        libmagic \
        autoconf \
        icu-dev \
        zlib-dev \
        file-dev \
        freetds-dev \
        freetype-dev \
        gmp-dev \
        curl-dev \
        krb5-dev \
        imap-dev \
        bzip2-dev \
        erlang-dev \
        sqlite-dev \
        ghostscript \
        libexif-dev \
        libxslt-dev \
        poppler-utils \
        openssl-dev \
        openldap-dev \
        enchant-dev \
        unixodbc-dev \
        memcached-dev \
        cyrus-sasl-dev \
        postgresql-dev \
        imagemagick-dev \
        libpq \
        libltdl \
        libjpeg \
        libpng-dev \
        libxpm-dev \
        libvpx-dev \
        libxml2-dev \
        libwebp-dev \
        libssh2-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libjpeg-turbo-dev

RUN docker-php-ext-configure hash && \
    docker-php-ext-configure gd \
        --enable-gd-native-ttf \
        --with-vpx-dir=/usr/lib \
        --with-xpm-dir=/usr/lib \
        --with-webp-dir=/usr/lib \
        --with-jpeg-dir=/usr/lib \
        --with-freetype-dir=/usr/include/freetype2 && \
    docker-php-ext-install gd && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl && \
    docker-php-ext-configure ldap && \
    docker-php-ext-install ldap

# Compile igbinary extension
RUN cd /tmp/ && git clone https://github.com/igbinary/igbinary "php-igbinary" && \
    cd php-igbinary && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    make clean && \
    docker-php-ext-enable igbinary

# Install Php Redis Extension
RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# Install the mongodb extension
RUN pecl install mongodb && \
    docker-php-ext-enable mongodb

# Compile Data Structures extension
RUN cd /tmp/ && git clone https://github.com/php-ds/extension "php-ds" \
    && cd php-ds \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable ds

RUN docker-php-ext-install mcrypt pdo_mysql pdo_pgsql soap

# Install bcmath, mbstring and zip extensions
RUN docker-php-ext-install bcmath mbstring zip wddx shmop sockets

# Enable Exif PHP extentions requirements
RUN docker-php-ext-install exif gettext

# Install APCu
RUN pecl install apcu \
    && echo "extension=apcu.so" > /usr/local/etc/php/conf.d/ext-apcu.ini

# Mysqli Modifications
RUN docker-php-ext-install mysqli dba

# Tokenizer Modifications:
RUN docker-php-ext-install tokenizer

RUN yes "" | pecl install msgpack-beta \
    && echo "extension=msgpack.so" > /usr/local/etc/php/conf.d/ext-msgpack.ini

# curl extension
RUN docker-php-ext-install curl

# data structures extension
RUN pecl install ds && \
    docker-php-ext-enable ds

# imagick
RUN pecl install imagick \
    && docker-php-ext-enable imagick 

# ssh2 module
RUN pecl install ssh2-1.0 && \
    docker-php-ext-enable ssh2

RUN export CFLAGS="-I/usr/src/php" && \
    docker-php-ext-install xmlreader xmlwriter pdo_sqlite

RUN docker-php-ext-install \
    dom \
    bz2 \
    json \
    iconv \
    pcntl \
    phar \
    posix \
    simplexml \
    soap \
    xml \
    xmlrpc \
    xsl \
    calendar \
    session \
    ctype \
    fileinfo \
    ftp \
    sysvmsg \
    sysvsem \
    sysvshm    



#
# --------------------------------------------------------------------------
# Compile Nginx
# --------------------------------------------------------------------------
#

ARG NGINX_VERSION=1.13.2
ARG PAGESPEED_VERSION=1.11.33.4
ARG LIBPNG_VERSION=1.2.56
ARG MAKE_J=4
ARG PAGESPEED_ENABLE=on

ENV NGINX_VERSION=${NGINX_VERSION} \
    PAGESPEED_VERSION=${PAGESPEED_VERSION} \
    LIBPNG_VERSION=${LIBPNG_VERSION} \
    MAKE_J=${MAKE_J} \
    PAGESPEED_ENABLE=${PAGESPEED_ENABLE}

RUN apk upgrade --no-cache --update && \
    apk add --no-cache --update \
        bash \
        ca-certificates \
        libuuid \
        apr \
        apr-util \
        libjpeg-turbo \
        icu \
        icu-libs \
        openssl \
        pcre \
        zlib

RUN set -x && \
    apk --no-cache add -t .build-deps \
        apache2-dev \
        apr-dev \
        apr-util-dev \
        build-base \
        curl \
        git \
        icu-dev \
        geoip-dev \
        libjpeg-turbo-dev \
        linux-headers \
        gperf \
        openssl-dev \
        pcre-dev \
        python \
        zlib-dev

# Build libpng
RUN cd /tmp && \
    curl -L http://prdownloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz | tar -zx && \
    cd /tmp/libpng-${LIBPNG_VERSION} && \
    ./configure --build=$CBUILD --host=$CHOST --prefix=/usr --enable-shared --with-libpng-compat && \
    make -j${MAKE_J} install V=0 

# Build PageSpeed
RUN cd /tmp && \
    curl -L https://dl.google.com/dl/linux/mod-pagespeed/tar/beta/mod-pagespeed-beta-${PAGESPEED_VERSION}-r0.tar.bz2 | tar -jx && \
    curl -L https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}-beta.tar.gz | tar -zx && \
    cd /tmp/modpagespeed-${PAGESPEED_VERSION} && \
    curl -L https://raw.githubusercontent.com/lagun4ik/docker-nginx-pagespeed/master/patches/automatic_makefile.patch | patch -p1 && \
    curl -L https://raw.githubusercontent.com/lagun4ik/docker-nginx-pagespeed/master/patches/libpng_cflags.patch | patch -p1 && \
    curl -L https://raw.githubusercontent.com/lagun4ik/docker-nginx-pagespeed/master/patches/pthread_nonrecursive_np.patch | patch -p1 && \
    curl -L https://raw.githubusercontent.com/lagun4ik/docker-nginx-pagespeed/master/patches/rename_c_symbols.patch | patch -p1 && \
    curl -L https://raw.githubusercontent.com/lagun4ik/docker-nginx-pagespeed/master/patches/stack_trace_posix.patch | patch -p1 && \
    ./generate.sh -D use_system_libs=1 -D _GLIBCXX_USE_CXX11_ABI=0 -D use_system_icu=1 && \
    cd /tmp/modpagespeed-${PAGESPEED_VERSION}/src && \
    make -j${MAKE_J} BUILDTYPE=Release CXXFLAGS=" -I/usr/include/apr-1 -I/tmp/libpng-${LIBPNG_VERSION} -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" CFLAGS=" -I/usr/include/apr-1 -I/tmp/libpng-${LIBPNG_VERSION} -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" && \
    cd /tmp/modpagespeed-${PAGESPEED_VERSION}/src/pagespeed/automatic/ && \
    make -j${MAKE_J} psol BUILDTYPE=Release CXXFLAGS=" -I/usr/include/apr-1 -I/tmp/libpng-${LIBPNG_VERSION} -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" CFLAGS=" -I/usr/include/apr-1 -I/tmp/libpng-${LIBPNG_VERSION} -fPIC -D_GLIBCXX_USE_CXX11_ABI=0" && \
    mkdir -p /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol && \
    mkdir -p /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/lib/Release/linux/x64 && \
    mkdir -p /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/out/Release && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/out/Release/obj /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/out/Release/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/net /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/testing /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/pagespeed /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/third_party /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/tools /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/url /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/include/ && \
    cp -r /tmp/modpagespeed-${PAGESPEED_VERSION}/src/pagespeed/automatic/pagespeed_automatic.a /tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol/lib/Release/linux/x64

# Build in additional Nginx modules
RUN cd /tmp && \
    git clone https://github.com/vozlt/nginx-module-vts.git && \
    git clone https://github.com/openresty/headers-more-nginx-module.git && \
    git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

# Build Nginx with support for PageSpeed
RUN cd /tmp && \
    curl -L http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -zx && \
    cd /tmp/nginx-${NGINX_VERSION} && \
    LD_LIBRARY_PATH=/tmp/modpagespeed-${PAGESPEED_VERSION}/usr/lib:/usr/lib ./configure \
        --sbin-path=/usr/sbin \
        --modules-path=/usr/lib/nginx \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_sub_module \
        --with-http_gunzip_module \
        --with-http_secure_link_module \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-http_geoip_module \
        --without-http_autoindex_module \
        --without-http_browser_module \
        --without-http_memcached_module \
        --without-http_userid_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --without-http_split_clients_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_upstream_ip_hash_module \
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --add-module=/tmp/nginx-module-vts \
        --add-module=/tmp/ngx_pagespeed-${PAGESPEED_VERSION}-beta \
        --add-module=/tmp/headers-more-nginx-module \
        --add-module=/tmp/ngx_http_substitutions_filter_module \
        --with-cc-opt="-fPIC -I /usr/include/apr-1" \
        --with-ld-opt="-luuid -lapr-1 -laprutil-1 -licudata -licuuc -L/tmp/modpagespeed-${PAGESPEED_VERSION}/usr/lib -lpng12 -lturbojpeg -ljpeg" && \
    make -j${MAKE_J} install --silent


# Clean-up
RUN cd && \
    # Forward request and error logs to docker log collector
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # Make PageSpeed cache writable
    mkdir -p /var/cache/ngx_pagespeed && \
    chmod -R o+wr /var/cache/ngx_pagespeed

# Download latest GeoIP databases
RUN apk add geoip-dev curl jq

RUN mkdir -p /usr/share/GeoIP && cd /usr/share/GeoIP/ && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz && \
    gzip -d *




#
# --------------------------------------------------------------------------
# PHP-FPM Final Touches
# --------------------------------------------------------------------------
#

# composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Set default work directory
ADD ./php-fpm/config/*.ini  /usr/local/etc/php/conf.d/
ADD ./php-fpm/config/*.conf /usr/local/etc/php-fpm.d/

# create PHP user
RUN addgroup php-fpm -g 1000 && \
    adduser -h /usr/share/php -u 1000 -G php-fpm -D -s /bin/false php-fpm

# remove access log for health check
RUN sed -i '/^access.log/ d' /usr/local/etc/php-fpm.d/docker.conf



#
# --------------------------------------------------------------------------
# Nginx Final Touches
# --------------------------------------------------------------------------
#

# Inject Nginx configuration files
ADD ./nginx/conf.d /etc/nginx/conf.d
ADD ./nginx/include /etc/nginx/include
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./nginx/fastcgi_params /etc/nginx/fastcgi_params
ADD ./docker-entrypoint.sh /usr/local/bin/

RUN echo "<?php phpinfo();" > /etc/nginx/html/info.php
RUN chmod +x /usr/local/bin/*


# Removing build dependencies, clean temporary files
RUN apk del .build-deps && \
    docker-php-source delete && \
    rm -rf /var/cache/apk/* /var/tmp/* /tmp/* 



#
# --------------------------------------------------------------------------
# Touchdown!
# --------------------------------------------------------------------------
#

EXPOSE 80
EXPOSE 8080

# check if response header returns 200 code OR die
HEALTHCHECK --interval=5s --timeout=5s CMD [ "200" = "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/healthcheck)" ] || exit 1

CMD ["nginx", "-g", "daemon off;"]
ENTRYPOINT ["docker-entrypoint.sh"]
