#!/usr/bin/env perl

use strict;
use warnings;
use Test::Nginx::Socket::Lua 'no_plan';

our $HttpConfig = qq{
    lua_package_path '../../lib/?/init.lua;../../lib/?.lua;;';
    
    server {
        listen 127.0.0.1:8080;
        server_name localhost;
        
        location ~ ^/data_test/ {
            lua_need_request_body on;
            content_by_lua_block {
                local string_utils = require 'utils.string_utils'
                local method, object = string.match(ngx.var.uri, "/data_test/(%w+)/(%w+)")
                
                if not method or not object then
                    ngx.status = ngx.HTTP_BAD_REQUEST
                    ngx.say('{"error":"Invalid URI"}')
                    return
                end
                
                if method == 'save' then
                    ngx.req.read_body()
                    local body = ngx.req.get_body_data()
                    ngx.say('{"result":"saved","object":"' .. object .. '"}')
                elseif method == 'read' then
                    ngx.say('{"result":"found","object":"' .. object .. '"}')
                else
                    ngx.status = ngx.HTTP_FORBIDDEN
                    ngx.say('{"error":"Method not allowed"}')
                end
            }
        }
    }
};

run_tests();

__DATA__

=== TEST 1: Invalid URI format
--- request
GET /data_test/invalid
--- response_body
{"error":"Invalid URI"}
--- status: 400

=== TEST 2: Save operation
--- request
POST /data_test/save/mydata
--- data
{"key":"value"}
--- response_body
{"result":"saved","object":"mydata"}
--- status: 200

=== TEST 3: Read operation
--- request
GET /data_test/read/mydata
--- response_body
{"result":"found","object":"mydata"}
--- status: 200

=== TEST 4: Unsupported method
--- request
GET /data_test/delete/mydata
--- response_body
{"error":"Method not allowed"}
--- status: 403
