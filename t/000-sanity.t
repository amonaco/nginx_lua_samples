#!/usr/bin/env perl

use strict;
use warnings;
use Test::Nginx::Socket::Lua 'no_plan';

our $HttpConfig = qq{
    lua_package_path '../../lib/?/init.lua;../../lib/?.lua;;';
    
    server {
        listen 127.0.0.1:8080;
        server_name localhost;
        
        location /test {
            content_by_lua_block {
                ngx.say("Hello World")
            }
        }
        
        location /health {
            access_log off;
            return 200 "OK";
        }
        
        location /recursive {
            content_by_lua_block {
                local num = tonumber(ngx.var.arg_num) or 0
                if num > 5 then
                    ngx.say("overflow")
                    return
                end
                if num > 0 then
                    local res = ngx.location.capture("/recursive?num=" .. tostring(num - 1))
                    ngx.print(num .. " ")
                    ngx.print(res.body)
                else
                    ngx.say("done")
                end
            }
        }
    }
};

run_tests();

__DATA__

=== TEST 1: Basic sanity check
--- request
GET /test
--- response_body
Hello World
--- status: 200

=== TEST 2: Health endpoint
--- request
GET /health
--- response_body
OK
--- status: 200

=== TEST 3: Recursive location capture
--- request
GET /recursive?num=3
--- response_body
3 2 1 done
--- status: 200
