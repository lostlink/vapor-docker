FROM php:8.0-fpm-alpine

ENV CHROME_BIN="/usr/bin/chromium-browser" \
    CHROME_PATH="/usr/lib/chromium/" \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 \
    PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium-browser"

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" >> /etc/apk/repositories && \
    apk upgrade -U -a && \
    apk add --no-cache \
      libstdc++ \
      chromium \
      harfbuzz \
      nss \
      freetype \
      ttf-freefont \
      font-noto-emoji \
      wqy-zenhei \
      bind-tools \
      nodejs \
      npm && \
    rm /var/cache/apk/*

COPY "php80/resources/local.conf" "/etc/fonts/local.conf"

RUN npm install --global puppeteer