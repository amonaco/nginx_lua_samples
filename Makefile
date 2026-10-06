.PHONY: help install test docker-up docker-down clean run lint

PWD := $(shell pwd)
NGINX_CONF := $(PWD)/conf/nginx.conf
LUA_PATH := $(PWD)/lib
REDIS_PORT := 6379
NGINX_PORT := 80

help:
	@echo "Available targets:"
	@echo "  install      - Install dependencies (Perl test modules, Redis)"
	@echo "  test         - Run Perl test suite (requires Test::Nginx)"
	@echo "  docker-up    - Start Nginx + Redis in Docker"
	@echo "  docker-down  - Stop Docker containers"
	@echo "  run          - Start Nginx locally (requires manual redis-server)"
	@echo "  stop         - Stop local Nginx"
	@echo "  lint         - Check Lua syntax"
	@echo "  clean        - Remove build artifacts and logs"

install:
	@echo "Installing dependencies..."
	@command -v cpan >/dev/null 2>&1 || { echo "Perl required"; exit 1; }
	cpan -i Test::Nginx
	@echo "On Ubuntu/Debian, also run: sudo apt-get install redis-server"
	@echo "On macOS, run: brew install redis"

test: check-redis
	@echo "Running tests..."
	PATH="$(PATH):$$(find /usr -name prove 2>/dev/null | head -1 | xargs dirname)" \
	prove -l -r t/

check-redis:
	@redis-cli ping > /dev/null 2>&1 || { echo "Error: Redis not running"; exit 1; }

run: check-redis
	@echo "Starting Nginx with config: $(NGINX_CONF)"
	@export SCRIPT_PATH=$(LUA_PATH); \
	REDIS_HOST=127.0.0.1 REDIS_PORT=$(REDIS_PORT) \
	nginx -c $(NGINX_CONF) -g "daemon off; error_log logs/nginx-error.log debug;"

stop:
	@echo "Stopping Nginx..."
	nginx -s stop || true

# Docker targets
docker-build:
	docker-compose build

docker-up: docker-build
	@echo "Starting Docker containers..."
	docker-compose up -d nginx redis
	@sleep 2
	@echo "Containers running. Access at http://localhost"

docker-down:
	@echo "Stopping Docker containers..."
	docker-compose down

docker-logs:
	docker-compose logs -f nginx

docker-test: docker-up
	@echo "Running tests in Docker..."
	docker-compose exec nginx prove -l -r t/

lint:
	@echo "Checking Lua syntax..."
	@find lib -name '*.lua' -exec lua -c {} \; 2>&1 || { echo "Lua syntax check requires 'lua' command"; exit 1; }

clean:
	@echo "Cleaning up..."
	rm -rf logs/*.log
	rm -rf t/servroot
	ngx -s stop 2>/dev/null || true
	@echo "Done"

format:
	@echo "Note: No auto-formatter configured. Use standard Lua style:"
	@echo "  - 4-space indentation"
	@echo "  - snake_case for functions and variables"
	@echo "  - camelCase for table keys (when applicable)"

.DEFAULT_GOAL := help
