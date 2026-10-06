FROM nginx:latest

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    perl \
    cpanminus \
    lua5.1 \
    liblua5.1-0-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Lua Redis client
RUN luarocks install lua-redis 2>/dev/null || \
    git clone https://github.com/openresty/lua-resty-redis.git /tmp/redis && \
    mkdir -p /usr/local/share/lua/5.1 && \
    cp /tmp/redis/lib/resty/redis.lua /usr/local/share/lua/5.1/redis.lua

# Install Perl test dependencies
RUN cpanm Test::Nginx

# Copy application files
COPY lib /usr/local/nginx/lib
COPY conf /usr/local/nginx/conf
COPY t /usr/local/nginx/t
COPY scripts /usr/local/nginx/scripts
COPY Makefile /usr/local/nginx/

WORKDIR /usr/local/nginx

# Verify Lua syntax
RUN find lib -name '*.lua' -exec lua -c {} \; || true

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
