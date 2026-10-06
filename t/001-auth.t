#!/usr/bin/env perl

use strict;
use warnings;
use Test::Nginx::Socket::Lua 'no_plan';
use IO::Socket::INET;

our $HttpConfig = qq{
    lua_package_path '../../lib/?/init.lua;../../lib/?.lua;;';
    
    server {
        listen 127.0.0.1:8080;
        server_name localhost;
        
        location /auth_test {
            content_by_lua_block {
                local logger = require 'middleware.logger'
                local headers = ngx.req.get_headers()
                local id = headers["x-foo-id"]
                local key = headers["x-foo-key"]
                
                if not id or not key then
                    ngx.status = ngx.HTTP_UNAUTHORIZED
                    ngx.say('{"error":"Missing credentials"}')
                    return
                end
                
                ngx.say('{"message":"Authenticated","id":"' .. id .. '"}')
            }
        }
    }
};

run_tests();

__DATA__

=== TEST 1: Missing X-Foo-Id header
--- request
GET /auth_test
--- response_body
{"error":"Missing credentials"}
--- status: 401

=== TEST 2: Missing X-Foo-Key header
--- request
GET /auth_test
--- more_headers
X-Foo-Id: testuser
--- response_body
{"error":"Missing credentials"}
--- status: 401

=== TEST 3: With both headers
--- request
GET /auth_test
--- more_headers
X-Foo-Id: testuser
X-Foo-Key: testkey
--- response_body
{"message":"Authenticated","id":"testuser"}
--- status: 200
