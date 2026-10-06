# Nginx Lua Samples

A comprehensive collection of Lua scripting examples for Nginx, demonstrating patterns for authentication, data persistence, rate limiting, and more. These examples are compatible with standard Nginx (with lua module), OpenResty, and other Lua-enabled Nginx distributions.

## Features

- **Authentication & Authorization**: Custom header validation with Redis backend
- **Data Persistence**: Save and retrieve data objects via Redis
- **Rate Limiting**: Token-bucket style rate limiting with Redis transactions
- **Request Introspection**: Access headers, URI parameters, request bodies
- **Recursive Operations**: Location captures and internal redirects
- **Test Coverage**: Comprehensive Perl-based test suite using Test::Nginx

## Quick Start

### Requirements

- Nginx with lua module (`nginx -V` should show `--with-http_lua_module`)
  - OR OpenResty (includes lua module by default)
- Redis server (for examples using data persistence)
- Perl (for running tests) - optional but recommended

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/amonaco/nginx_lua_samples.git
   cd nginx_lua_samples
   ```

2. Install dependencies (if using test suite):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install perl libtest-nginx-perl redis-server
   
   # macOS
   brew install redis
   cpan Test::Nginx
   ```

3. Adjust paths in configuration:
   ```bash
   # Edit conf/nginx.conf and update paths as needed
   # or use environment variable:
   export SCRIPT_PATH=$(pwd)/lib
   ```

### Running the Examples

#### Option 1: With Docker (recommended)

```bash
make docker-up      # Start nginx + redis in containers
make test           # Run Perl test suite
make docker-down    # Stop containers
```

#### Option 2: Manual setup

```bash
# Start Redis
redis-server &

# Start Nginx (replace paths if needed)
nginx -c $(pwd)/conf/nginx.conf

# Run tests
prove t/

# Stop Nginx
nginx -s stop
```

#### Option 3: Sample manual requests

```bash
# Save data (see scripts/save.sh)
curl -X POST \
  -H "X-Foo-Id: demo" \
  -H "X-Foo-Key: jH4y7Ka81JQ8jaDc891jka9D8k3DlkM1ja8D-Zo1jwS" \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}' \
  http://localhost/save/mydata

# Read data (see scripts/read.sh)
curl -X POST \
  -H "X-Foo-Id: demo" \
  -H "X-Foo-Key: jH4y7Ka81JQ8jaDc891jka9D8k3DlkM1ja8D-Zo1jwS" \
  http://localhost/read/mydata
```

## Project Structure

```
lib/
  handlers/           # Request handlers (authentication, data ops, rate limit)
    auth.lua          # Header-based authentication
    data.lua          # Save/read operations with Redis
    limit.lua         # Rate limiting logic
  middleware/         # Shared utilities
    redis_client.lua  # Redis connection pool management
    logger.lua        # Logging helpers
  utils/
    json.lua          # JSON parsing (Lua 5.1 compatible)
    string_utils.lua  # String manipulation helpers
conf/
  nginx.conf          # Main Nginx configuration
scripts/
  save.sh             # Example: save request
  read.sh             # Example: read request
t/
  fixtures/           # Test data and mock responses
  lib/                # Test helper modules
  000-sanity.t        # Basic functionality tests
  001-auth.t          # Authentication tests
  002-data.t          # Data persistence tests
  003-limit.t         # Rate limit tests
Makefile             # Development tasks
Dockerfile           # Docker setup for isolated testing
docker-compose.yml   # Nginx + Redis stack
.openresty-version   # Version reference (informational)
```

## Examples by Feature

### 1. Authentication

The `lib/handlers/auth.lua` module validates requests via custom headers:
- Checks `X-Foo-Id` and `X-Foo-Key` headers
- Verifies credentials against Redis backend
- Denies with HTTP 401 if invalid

**Use case**: API gateway authentication without external calls.

### 2. Data Persistence

The `lib/handlers/data.lua` handler demonstrates CRUD operations:
- Parse URI to extract method (save/read) and object name
- Store/retrieve data in Redis under namespace keys
- Return JSON responses

**Use case**: Simple caching layer or session storage in Nginx.

### 3. Rate Limiting

The `lib/handlers/limit.lua` module implements token-bucket rate limiting:
- Uses Redis transactions for atomic counter increments
- Compares request count against configurable limit
- Redirects to fallback page when limit exceeded

**Use case**: Per-user or per-IP rate limiting without external service calls.

## Configuration

### Environment Variables

- `REDIS_HOST` - Redis server hostname (default: `127.0.0.1`)
- `REDIS_PORT` - Redis server port (default: `6379`)
- `SCRIPT_PATH` - Path to Lua scripts (default: `/usr/local/nginx/scripts`)
- `LOG_LEVEL` - Nginx error log level (default: `debug`)

### Nginx Directives

```nginx
# Enable request body reading when needed
lua_need_request_body on;

# Set Lua package path (if using custom modules)
lua_package_path '/path/to/lua/lib/?/init.lua;/path/to/lua/lib/?.lua;;';

# Access phase (early request filtering)
access_by_lua_file /path/to/handlers/auth.lua;

# Content phase (generate response)
content_by_lua_file /path/to/handlers/data.lua;
```

## Compatibility

- **Nginx versions**: 1.9.3+ (lua module required)
- **Lua versions**: 5.1, 5.2, 5.3 (examples avoid LuaJIT-specific features)
- **Operating Systems**: Linux, macOS, BSD
- **Redis versions**: 2.6+

## Testing

This repository includes a comprehensive test suite using [Test::Nginx](https://metacpan.org/pod/Test::Nginx):

```bash
# Run all tests
prove t/

# Run specific test file
prove t/001-auth.t

# Run with verbose output
prove -v t/
```

Tests are independent and can run in any order. Each test:
1. Starts a temporary Nginx instance
2. Runs HTTP requests against it
3. Validates responses
4. Cleans up

## Performance Considerations

- Redis connections are pooled per worker process (see `redis_client.lua`)
- Use `lua_shared_dict` for high-frequency cached data (examples in progress)
- Minimize synchronous I/O in high-traffic paths
- Consider using `ngx.thread.spawn()` for concurrent operations (Nginx 1.13+)

## Common Issues

### "No such file or directory" errors
- Verify paths in `conf/nginx.conf` match your installation
- Use absolute paths or adjust `lua_package_path`

### Redis connection refused
- Ensure Redis is running: `redis-cli ping` should return `PONG`
- Check Redis host/port in handler files match configuration
- Redis socket connections supported via `params = { path = '/tmp/redis.sock' }`

### Test failures in CI
- Tests require `Test::Nginx` Perl module
- Some tests may need root access (port 80/443)
- Use Docker Compose to run in isolated environment

## Contributing

Contributions welcome! Please:
1. Add tests for new examples in `t/`
2. Update documentation with use cases
3. Keep Lua code compatible with Lua 5.1+
4. Include error handling and logging

## License

Public domain (2015-2024). Use freely.

## References

- [Nginx Lua Module Documentation](https://github.com/openresty/lua-nginx-module)
- [OpenResty Official Site](https://openresty.org)
- [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/)
- [Redis Lua Scripting](https://redis.io/commands/eval/)
- [Test::Nginx Documentation](https://metacpan.org/pod/Test::Nginx)
